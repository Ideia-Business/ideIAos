#!/bin/bash
# ledger.sh — ledger de auditoria hash-chained append-only LOCAL (v14.4 · B6 / R-WP9).
#
# Decisão ACEITA (docs/decisions/v14.4-command-ref-origin-exposure.md, Q5):
#   • a auditoria autoritativa do "quem-o-quê-quando(-para-quem)" vive SÓ no ledger LOCAL —
#     NUNCA no `origin`/GitHub (o ref é espelho efêmero de transporte, não registro de auditoria);
#   • não-repúdio com DETECÇÃO DE REESCRITA. DUAS defesas COMPLEMENTARES:
#       (1) hash-chain: cada entrada carrega prev_hash = sha256 da LINHA-ENTRADA anterior INTEIRA
#           → editar/remover/reordenar uma entrada do INTERIOR quebra o elo na entrada SEGUINTE;
#       (2) ÂNCORA-DE-CAUDA: HEAD-file 0600 (`$STORE.head` = "<contagem>|sha256(última-linha)",
#           atualizado atomicamente a cada append) → detecta adulteração da ÚLTIMA entrada
#           (editar/substituir), TRUNCAMENTO e APPEND-FORJADO-NO-FIM — que a hash-chain sozinha
#           NÃO pega (a última entrada não tem "entrada seguinte" que a cheque). Sem a âncora,
#           `verify` era CEGO NA CAUDA (achado CRITICAL da verificação adversarial wf_35d229e3-d24).
#   • a genesis usa prev_hash = 64 zeros (âncora determinística do INÍCIO da cadeia).
#
# Concorrência: append serializa via LOCK-POR-DIRETÓRIO (`mkdir` é atômico no FS local — nativo,
#   sem dep nova; macOS não tem flock(1)) e grava 1 linha via O_APPEND (`>>`), em vez do
#   read-modify-write de arquivo INTEIRO (que sob concorrência PERDIA entradas e quebrava a cadeia
#   — achado HIGH da mesma verificação). N appends paralelos preservam N entradas e mantêm verify=0.
#
# LIMITE HONESTO (threat model): cadeia + âncora NÃO-assinadas detectam adulteração ACIDENTAL/PARCIAL
#   e trazem a CAUDA à PARIDADE com o interior. Tamper-evidência contra um adversário com ACESSO DE
#   ESCRITA ao store (que reescreveria cadeia + HEAD de forma coordenada, ou apagaria o ledger inteiro)
#   exige ASSINAR o HEAD com a chave de máquina (sign-payload.sh / B0).
#   debt: assinar o HEAD (não-repúdio forte contra store-writer) — diferido para a Wave de wiring do
#   ledger ao daemon-loop/bundle (ADR Q5), que traz o contexto de chave/role da máquina. Hoje é LATENTE
#   (sem call-site de produção); estes fixes DEVEM preceder esse wiring.
#
# Formato de LINHA (determinístico, campos separados por '|', sem newline interno):
#   prev_hash|subject|role|action|ref|scope|result|signature
# '|' e control-chars nos campos são REJEITADOS (exit 2 REASON=bad-field) — senão um campo
# com '|' embutido redesenharia as fronteiras de coluna e forjaria/ocultaria entradas.
#
# antifragile-gates: o veredito de integridade é o EXIT-CODE de `verify`, nunca a leitura humana.
# credential-isolation: NENHUM valor de segredo entra aqui — a `signature` é uma assinatura
#   destacada (artefato público, não a chave); NENHUMA chamada a provedor externo.
#
# Store local override por env (para testes): IDEIAOS_LEDGER_STORE
#
# Uso:
#   ledger.sh append <subject> <role> <action> <ref> <scope> <result> [signature]
#   ledger.sh verify
#   ledger.sh print
#
# Exit-codes:
#   0  sucesso (append gravado / cadeia íntegra / print)
#   2  erro de invocação / campo inválido ('|'/control-char) / falha operacional de escrita
#      (REASON=usage | bad-field | write-failed | lock-timeout)
#   3  cadeia quebrada — interior (prev_hash) OU cauda (HEAD: contagem/sha) — REASON=chain-broken
set -uo pipefail
umask 077   # entradas de auditoria nunca legíveis por outros (defesa-em-profundidade)

GENESIS="0000000000000000000000000000000000000000000000000000000000000000"
STORE="${IDEIAOS_LEDGER_STORE:-$HOME/.ideiaos/cockpit/ledger}"
HEAD="$STORE.head"
LOCKD="$STORE.lock.d"

_ensure_store() { mkdir -p "$(dirname "$STORE")" 2>/dev/null || true; [ -f "$STORE" ] || : > "$STORE"; chmod 600 "$STORE" 2>/dev/null || true; }

# sha256 dos BYTES exatos passados em $1 (sem newline final — printf '%s'). Determinístico.
_sha() { printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }

# lock EXCLUSIVO por diretório (mkdir é atômico no FS local). Bounded retry → fail-closed (exit 2)
# se não conseguir em ~10s. trap libera no EXIT (cobre saídas normais e a maioria dos sinais; um
# SIGKILL com lock segurado é o único resíduo aceito — raro, mesmo regime do append durável).
_lock() {
  local tries=0
  while ! mkdir "$LOCKD" 2>/dev/null; do
    tries=$((tries+1))
    [ "$tries" -gt 500 ] && { echo "REASON=lock-timeout" >&2; exit 2; }
    sleep 0.02 2>/dev/null || sleep 1
  done
  trap '_unlock' EXIT
}
_unlock() { rmdir "$LOCKD" 2>/dev/null || true; }

# _reject_bad_field <valor> — exit 2 REASON=bad-field se contém '|' ou QUALQUER control-char.
_reject_bad_field() {
  case "$1" in
    *'|'*) echo "REASON=bad-field (separador '|' embutido)" >&2; exit 2 ;;
  esac
  local stripped; stripped=$(printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]')
  if [ "$stripped" != "$1" ]; then
    echo "REASON=bad-field (control-char embutido)" >&2; exit 2
  fi
}

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  append) # append <subject> <role> <action> <ref> <scope> <result> [signature]
    subject="${1:?}"; role="${2:?}"; action="${3:?}"; ref="${4:?}"; scope="${5:?}"; result="${6:?}"
    signature="${7:-}"
    _reject_bad_field "$subject"; _reject_bad_field "$role"; _reject_bad_field "$action"
    _reject_bad_field "$ref";     _reject_bad_field "$scope"; _reject_bad_field "$result"
    _reject_bad_field "$signature"
    _ensure_store
    _lock   # serializa: ler-tail + computar-prev + O_APPEND da linha + atualizar HEAD (atômico cross-processo)
    # prev_hash = sha256 da ÚLTIMA linha-entrada INTEIRA; genesis (store vazio) → 64 zeros.
    last=$(tail -n 1 "$STORE" 2>/dev/null)
    if [ -z "$last" ]; then prev="$GENESIS"; else prev=$(_sha "$last"); fi
    line="$prev|$subject|$role|$action|$ref|$scope|$result|$signature"
    # O_APPEND de 1 linha: escrita atômica (<PIPE_BUF), descarta o read-modify-write de arquivo inteiro.
    printf '%s\n' "$line" >> "$STORE" || { echo "REASON=write-failed" >&2; exit 2; }
    # ÂNCORA-DE-CAUDA: contagem de entradas + sha256 da ÚLTIMA linha (a recém-gravada), atômico.
    cnt=$(wc -l < "$STORE" | tr -d ' ')
    htmp="$HEAD.tmp.$$"
    printf '%s|%s\n' "$cnt" "$(_sha "$line")" > "$htmp" && mv -f "$htmp" "$HEAD" \
      || { rm -f "$htmp"; echo "REASON=write-failed" >&2; exit 2; }
    chmod 600 "$STORE" "$HEAD" 2>/dev/null || true
    exit 0
    ;;

  verify) # re-encadeia do início + confere a ÂNCORA-DE-CAUDA (contagem + sha da última) contra o HEAD.
    _ensure_store
    _lock   # snapshot consistente: nenhum append em curso pode deixar HEAD/store em estado intermediário
    expected="$GENESIS"
    n=0; lastline=""
    # lê linha-a-linha PRESERVANDO bytes (IFS vazio + read -r); não pula linha final sem \n.
    while IFS= read -r line || [ -n "$line" ]; do
      n=$((n+1)); lastline="$line"
      got=$(printf '%s' "$line" | cut -d'|' -f1)
      if [ "$got" != "$expected" ]; then
        echo "REASON=chain-broken (entrada #$n: prev_hash gravado != sha256 da anterior)" >&2; exit 3
      fi
      expected=$(_sha "$line")   # próximo elo esperado = sha256 desta linha-entrada INTEIRA
    done < "$STORE"
    # ── ÂNCORA-DE-CAUDA (fecha a cegueira da cauda: edição/substituição da última, truncamento, append forjado) ──
    if [ "$n" -eq 0 ]; then
      # ledger vazio é aceitável SÓ sem HEAD (ledger novo); HEAD presente c/ store vazio = truncamento.
      if [ -s "$HEAD" ]; then echo "REASON=chain-broken (HEAD presente mas ledger vazio — truncado)" >&2; exit 3; fi
      exit 0
    fi
    if [ ! -s "$HEAD" ]; then echo "REASON=chain-broken (HEAD ausente — âncora de cauda removida)" >&2; exit 3; fi
    hc=$(cut -d'|' -f1 "$HEAD"); hs=$(cut -d'|' -f2 "$HEAD")
    if [ "$n" != "$hc" ]; then
      echo "REASON=chain-broken (HEAD: contagem N=$n != HEAD.count=$hc — truncamento/append forjado)" >&2; exit 3
    fi
    if [ "$(_sha "$lastline")" != "$hs" ]; then
      echo "REASON=chain-broken (HEAD: sha da última entrada != HEAD.sha — cauda adulterada)" >&2; exit 3
    fi
    exit 0
    ;;

  print) # ecoa as entradas SEM expor a signature por inteiro (só um prefixo curto — artefato sensível).
    _ensure_store
    while IFS='|' read -r prev subject role action ref scope result signature || [ -n "$prev" ]; do
      [ -z "$prev" ] && continue
      sigshort=""
      [ -n "$signature" ] && sigshort="$(printf '%s' "$signature" | cut -c1-8)…"
      printf 'subject=%s role=%s action=%s ref=%s scope=%s result=%s sig=%s\n' \
        "$subject" "$role" "$action" "$ref" "$scope" "$result" "$sigshort"
    done < "$STORE"
    exit 0
    ;;

  *)
    echo "uso: ledger.sh {append <subject> <role> <action> <ref> <scope> <result> [signature]|verify|print}" >&2
    exit 2
    ;;
esac
