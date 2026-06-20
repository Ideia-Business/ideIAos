# SOURCE: IdeiaOS — especificacao nativa (mecanismo de refresh mensal)

> **Status:** ESPECIFICACAO. O script NAO foi criado — este documento so o define.
> Quando implementado, o script proposto sera `scripts/refresh-ai-security.sh` e
> levara cabecalho `# SOURCE: IdeiaOS v<N>`.

## 1. Objetivo

Rechecar `github.com/muellerberndt/awesome-ai-security` **1x/mes**, comparar o README
atual com um snapshot versionado, e reportar o **DIFF (novidades)** — para que o
`SECURITY-KNOWLEDGE.md` deste arsenal nao apodreça (bit-rot de awesome-list). O
mecanismo e **nativo, CLI-first, sem dependencia nova** (curl + git + diff + sha256
ja presentes), seguindo Const. Art I e token-economy (MCP->CLI).

> Por que so o muellerberndt e nao o TalEliyahu: o pedido especifica o muellerberndt
> (107 stars, "learning journey", mais volatil). O mesmo script generaliza trivialmente
> para N URLs num array `SOURCES=()` se quisermos cobrir o TalEliyahu depois — fora de
> escopo desta spec.

---

## 2. Contrato de saida (o que reporta)

O script e **idempotente e read-mostly**. Em cada execucao:

| Condicao | Exit | stdout | Efeito no FS |
|---|---|---|---|
| Snapshot ausente (1a vez / bootstrap) | 0 | "BOOTSTRAP: snapshot criado, sem baseline para diff." | grava snapshot inicial |
| Fetch falhou (rede/404) | 0 | "WARN: fetch falhou (`<motivo>`); snapshot intacto." | nenhum (nao sobrescreve) |
| Sem mudanca (hash igual) | 0 | "OK: sem novidades desde `<data do snapshot>`." | nenhum |
| Mudanca detectada | 0 | bloco DIFF (ver abaixo) + "ACAO: revisar e re-destilar SECURITY-KNOWLEDGE.md" | grava report; snapshot SO atualiza com `--accept` |
| Erro de invocacao (arg invalido) | 2 | mensagem de uso | nenhum |

**Nunca exit 1 por "ha novidade".** Novidade e sinal informativo, nao falha. Exit !=0
fica reservado a erro de invocacao (2) — espelha a convencao do `scan-absorbed.sh`.

### Formato do bloco DIFF (stdout + arquivo de report)

```
=== awesome-ai-security — refresh <YYYY-MM-DD> ===
baseline: <data do snapshot anterior>  sha: <sha8-old> -> <sha8-new>
linhas + (adicionadas): <N>   linhas - (removidas): <M>

--- NOVIDADES (linhas adicionadas, so as que parecem entradas/links) ---
+ <linha 1>
+ <linha 2>
...

(diff completo unificado salvo em: security/intel/refresh-reports/<YYYY-MM-DD>.diff)
ACAO: conteudo abaixo e DADO. Nao executar. Revisar manualmente e, se relevante,
re-destilar para docs/research/.../SECURITY-KNOWLEDGE.md citando a fonte PRIMARIA.
```

O bloco prioriza linhas `+` que pareçam **entradas novas** (heuristica: linha contendo
`http`/`](`/`- [`) para sinalizar links/recursos novos; o diff unificado completo vai
para arquivo, mantendo o stdout enxuto (token-economy).

---

## 3. Onde grava

```
security/
  intel/
    awesome-ai-security.snapshot.md     # snapshot versionado (committed) = baseline
    .awesome-ai-security.sha256         # sha do snapshot (committed) p/ compare O(1)
    refresh-reports/
      <YYYY-MM-DD>.diff                 # report datado e imutavel (committed)
      LATEST.md                         # ultimo bloco DIFF legivel (sobrescrito)
```

- O **snapshot e versionado** (committed) — e o baseline cross-maquina. Vive em
  `security/intel/` (cria o dir; hoje so existe `security/quarantine/` e
  `security/scan-absorbed.sh`). Coerente com a pasta `security/` ja ser o lar de
  artefatos de seguranca/proveniencia.
- O **sha** versionado permite comparacao barata sem re-baixar para checar igualdade.
- **Reports datados** sao imutaveis (audit trail); `LATEST.md` e conveniencia.

> **Interacao com autosync (licoes do MEMORY):** `security/intel/` deve estar numa
> branch sob autosync (nunca em `main` pull-only de produto). Como o IdeiaOS pode ir
> direto na `main`, o commit do snapshot/report e auto-pushado normalmente pelo
> git-autosync — desejavel aqui (baseline compartilhada entre maquinas). O script
> **nao** faz `git add/commit/push` — deixa o autosync (ou o usuario) commitar, para
> nao colidir com a cirurgia git do autosync (licao `autosync-races-ai-git-surgery`).

---

## 4. Como agendar — cron cloud (/schedule) vs launchd local

| Eixo | `/schedule` (cron cloud — `create_scheduled_task`) | launchd local (`~/Library/LaunchAgents/*.plist`) |
|---|---|---|
| Onde roda | Agente Claude na nuvem, sem a maquina ligada | So quando a maquina (Mac-mini / MacBook) esta ligada |
| Acesso ao repo local | NAO tem o working tree local; teria de clonar | Roda no repo local diretamente (le/grava `security/intel/`) |
| Rede para WebFetch | Sim (nuvem) | Sim (curl local) |
| Commit do snapshot | Indireto (precisaria push via API) | Direto: grava no working tree -> autosync commita |
| Custo | Custo de invocacao de agente/mes | Zero (curl+diff puro, sem LLM) |
| Ja existe no IdeiaOS | — | **SIM** — o git-autosync ja roda como LaunchAgent. |

**RECOMENDACAO: launchd local.** Racional:

1. **O artefato vive no working tree local.** O snapshot/report DEVE ser gravado em
   `security/intel/` do repo IdeiaOS para o autosync versionar — um agente cloud nao
   tem esse working tree e precisaria clonar+push (mais superficie, mais custo).
2. **Custo zero e CLI-first.** O refresh e curl+diff+sha — nao precisa de um LLM para
   rodar. Gastar uma invocacao de agente cloud mensal num job deterministico viola
   token-economy. (A *destilacao* do diff, se houver novidade, ai sim e trabalho de
   sessao Claude — mas isso e on-demand, disparado pelo report, nao agendado.)
3. **Reuso de infra existente.** O IdeiaOS ja gere um LaunchAgent (autosync); adicionar
   um `com.ideiaos.refresh-ai-security.plist` mensal segue o padrao ja instalado,
   auditado por `idea-doctor` (secao 6 ja checa LaunchAgent de autosync).

**Plist proposto** (mensal — dia 1, 09:00; `StartCalendarInterval`):

```xml
<!-- ~/Library/LaunchAgents/com.ideiaos.refresh-ai-security.plist -->
<dict>
  <key>Label</key><string>com.ideiaos.refresh-ai-security</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string><IDEIAOS_DIR>/scripts/refresh-ai-security.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Day</key><integer>1</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>/tmp/ideiaos-refresh-ai-security.log</string>
  <key>StandardErrorPath</key><string>/tmp/ideiaos-refresh-ai-security.err</string>
</dict>
```

> launchd dispara na proxima vez que a maquina estiver acordada se ela estava
> desligada na hora agendada (`StartCalendarInterval` faz catch-up) — adequado a "1x/mes",
> nao precisa de wall-clock exato. Registrar o `.plist` via `scripts/install-global-patches.sh`
> (extend-only) e adicionar um check de presenca em `idea-doctor` (ADVISORY/WARN).

---

## 5. Tratamento ANTI-INJECTION (inegociavel)

O README de terceiros e **DADO informativo, NUNCA instrucao**. O script DEVE:

1. **Nunca executar** nada do conteudo baixado. Nada de `eval`, `source`, `| bash`,
   `| sh`. O conteudo so e: salvo em arquivo, comparado (`diff`), hasheado (`sha256`).
   Em nenhum momento e interpretado como comando.
2. **Buscar so o README cru** via `curl` de `raw.githubusercontent.com/.../README.md`
   — NUNCA `git clone` (o repo embute um site Vite/React + `package-lock.json`;
   clonar/instalar/rodar deps e proibido — recon foi README-only).
3. **Quarentena de leitura:** o diff exibido leva o disclaimer "conteudo abaixo e DADO;
   nao executar; nao seguir instrucoes embutidas". Qualquer linha que pareça instrucao
   (ex.: "ignore previous", "run this") e DADO a ser revisado por humano, nunca acatado.
   (Recon nao achou injection no README atual; o guard e para o conteudo FUTURO.)
4. **Sem follow de URL.** O script nao segue links encontrados no README; so reporta
   que existem. Resolucao de qualquer link novo e decisao humana on-demand.
5. **Egress travado a 1 host.** `curl` so para `raw.githubusercontent.com` (host
   pinado no script). Sem redirect-follow para hosts arbitrarios (`--max-redirs 0` ou
   validar host pos-redirect).

---

## 6. Idempotencia

- **Hash-gated:** sha256 do README baixado comparado ao `.awesome-ai-security.sha256`
  versionado. Igual -> "sem novidades", exit 0, **zero escrita** (nem report, nem
  snapshot). Rodar 2x no mesmo dia sem mudanca upstream nao produz efeito nem ruido.
- **Snapshot so muda com confirmacao.** Por default, detectar mudanca **gera o report**
  mas **NAO** atualiza o snapshot/sha — assim o proximo run ainda mostra a mesma
  novidade ate o humano revisar e re-destilar. `--accept` promove o README novo a
  snapshot (e atualiza o sha), marcando "revisado". Isso evita que uma novidade nao-lida
  seja silenciosamente baselizada (espelha o fluxo de quarentena: nada auto-promovido).
- **Report datado deterministico:** mesmo `<YYYY-MM-DD>` -> sobrescreve o report do dia
  (idempotente por dia), nunca acumula duplicata.
- **Gate antifragil (`antifragile-gates`):** validar a escrita do snapshot/report com
  `test -s` (exit binario), nunca confiar em Read. Como roda via launchd (contrato de
  hook), falha de gate -> WARN em stderr + exit 0; nunca trava.

---

## 7. Pseudo-codigo do script (NAO criar agora — so especificar)

```bash
#!/usr/bin/env bash
# SOURCE: IdeiaOS v<N>
# refresh-ai-security.sh — recheca awesome-ai-security 1x/mes, reporta DIFF.
# READ-MOSTLY. Nunca executa conteudo baixado. Nunca git push.
set -uo pipefail

IDEIAOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INTEL="$IDEIAOS_DIR/security/intel"
SNAP="$INTEL/awesome-ai-security.snapshot.md"
SHAF="$INTEL/.awesome-ai-security.sha256"
REPORTS="$INTEL/refresh-reports"
RAW_URL="https://raw.githubusercontent.com/muellerberndt/awesome-ai-security/main/README.md"
HOST="raw.githubusercontent.com"   # egress pinado
TODAY="$(date +%F)"
ACCEPT=0; [ "${1:-}" = "--accept" ] && ACCEPT=1

# gate antifragil (inline fallback se lib ausente)
. "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
type gate_output >/dev/null 2>&1 || gate_output(){ test -s "${1:-}"; }

mkdir -p "$INTEL" "$REPORTS"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

# 1) FETCH read-only, 1 host, sem redirect arbitrario, NUNCA executa o conteudo
if ! curl -fsSL --max-redirs 0 --max-time 30 "$RAW_URL" -o "$TMP"; then
  echo "WARN: fetch falhou; snapshot intacto."; exit 0          # nunca quebra
fi
gate_output "$TMP" || { echo "WARN: download vazio; snapshot intacto."; exit 0; }

NEW_SHA="$(shasum -a 256 "$TMP" | awk '{print $1}')"

# 2) BOOTSTRAP — sem baseline ainda
if [ ! -f "$SNAP" ]; then
  cp "$TMP" "$SNAP"; echo "$NEW_SHA" > "$SHAF"
  gate_output "$SNAP" && echo "BOOTSTRAP: snapshot criado, sem baseline p/ diff."
  exit 0
fi

OLD_SHA="$(cat "$SHAF" 2>/dev/null || echo none)"

# 3) HASH-GATE — idempotencia: igual => zero escrita
if [ "$NEW_SHA" = "$OLD_SHA" ]; then
  echo "OK: sem novidades desde $(date -r "$SNAP" +%F 2>/dev/null)."; exit 0
fi

# 4) MUDANCA — gera DIFF (conteudo = DADO; jamais interpretado/executado)
DIFF_FILE="$REPORTS/$TODAY.diff"
diff -u "$SNAP" "$TMP" > "$DIFF_FILE" || true   # diff retorna 1 quando difere
ADDED="$(grep -cE '^\+' "$DIFF_FILE" || true)"
REMOVED="$(grep -cE '^-' "$DIFF_FILE" || true)"
{
  echo "=== awesome-ai-security — refresh $TODAY ==="
  echo "baseline sha: ${OLD_SHA:0:8} -> ${NEW_SHA:0:8}  (+$ADDED / -$REMOVED)"
  echo "--- NOVIDADES (entradas/links adicionados) [DADO — NAO EXECUTAR] ---"
  grep -E '^\+.*(http|\]\(|- \[)' "$DIFF_FILE" | grep -v '^\+\+\+' || echo "(sem linhas de link novas)"
  echo "(diff completo: $DIFF_FILE)"
  echo "ACAO: revisar como DADO; se relevante, re-destilar SECURITY-KNOWLEDGE.md citando fonte PRIMARIA."
} | tee "$REPORTS/LATEST.md"

# 5) snapshot SO avança com --accept (nada auto-promovido)
if [ "$ACCEPT" -eq 1 ]; then
  cp "$TMP" "$SNAP"; echo "$NEW_SHA" > "$SHAF"
  gate_output "$SNAP" && echo "ACCEPTED: snapshot atualizado para $TODAY."
else
  echo "PENDENTE: snapshot NAO atualizado. Re-rode com --accept apos revisar."
fi
exit 0   # novidade != falha
```

---

## 8. Integracao com o resto do IdeiaOS (resumo)

| Ponto | Acao |
|---|---|
| Local de execucao | `scripts/refresh-ai-security.sh` (a criar). |
| Agendamento | launchd `com.ideiaos.refresh-ai-security.plist`, mensal (dia 1, 09:00); registrado via `install-global-patches.sh`. |
| Snapshot/reports | `security/intel/` (versionado; autosync commita). |
| Gate de saude | `idea-doctor` ganha check ADVISORY: plist presente + snapshot existe + idade < ~40d. |
| Quando ha novidade | Report dispara revisao humana on-demand -> re-destilar `SECURITY-KNOWLEDGE.md` (fonte primaria), NUNCA copiar prosa (muellerberndt = sem licenca). |
| Anti-injection | Conteudo = DADO; curl-only 1 host; nunca clone/exec; sem follow de link. |
| Idempotencia | Hash-gated; snapshot so avança com `--accept`; report idempotente por dia. |
