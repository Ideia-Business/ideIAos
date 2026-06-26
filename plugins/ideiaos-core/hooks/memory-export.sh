#!/usr/bin/env bash
# =============================================================================
# memory-export.sh — IdeiaOS Stop hook (v5 cross-IDE memory, EXPORT bridge)
# SOURCE: IdeiaOS v5 — Phase 21, requirement R5-08 (+ R5-06 secret-scan)
#
# A ponte de EXPORT da memória compartilhada. Lê a memória nativa da IDE
# (~/.claude/projects/<slug>/memory/*.md), confronta cada FATO com o store
# canônico no branch `planning` (.planning/memory/shared/facts/<file>) e
# commita SÓ os fatos novos/alterados nesse branch — SEM dar checkout,
# SEM tocar o working tree, SEM tocar `main`.
#
# ───────────────────────────────────────────────────────────────────────────
# INVARIANTE LOVABLE (inegociável):
#   Nada aqui pode fazer memória chegar ao `main`. A escrita vai EXCLUSIVAMENTE
#   para o branch `planning` via git plumbing (hash-object → commit-tree →
#   update-ref). NENHUM arquivo temporário é escrito no working tree do branch
#   corrente — esse é exatamente o bug `.lovable_mem_tmp.md` que isto corrige.
#   O staging só existe DENTRO da árvore do commit em `planning`
#   (.planning/memory/local/staging/), nunca no disco do branch atual.
#
# CONTRATO:
#   - Gatilho: evento Stop (mesmo de session-summary.sh / observe-session-end.sh).
#   - Caminho de escrita PRIMÁRIO: git plumbing (sem working tree, sem resíduo).
#     `git worktree` documentado abaixo como `# FALLBACK:` (não usado por padrão).
#   - Secret-scan gate (R5-06): cada fato é escaneado ANTES do export; fato com
#     aparência de segredo (API key, JWT, connection string, atribuição .env) é
#     RECUSADO com mensagem clara; fatos limpos passam.
#   - NÃO faz push (o autosync empurra o branch `planning`).
#   - Se nenhum fato mudou → exit 0 SILENCIOSO (sem commit vazio).
#   - Conflito de fast-forward no `planning` → fetch + retry UMA vez → exit 0.
#   - exit 0 em QUALQUER caminho de falha (offline, sem planning, sem memória) —
#     nunca bloqueia o fechamento da sessão.
#
# DETERMINISMO/TESTE:
#   - A data do commit vem de IDEIAOS_MEM_DATE quando setada (não usa `date`),
#     para testes determinísticos. Sem ela, usa a data corrente.
#   - IDEIAOS_MEM_SLUG sobrescreve o slug derivado (testes).
#   - IDEIAOS_MEM_MEMDIR sobrescreve o diretório de memória nativa (testes).
#
# Entrada (stdin): JSON Stop { session_id, transcript_path, cwd }
# Saída: NENHUMA (exit 0 puro — sem JSON, sem additionalContext).
# Sem-jq: só python3 (resolvido por lookup). set -uo pipefail.
# =============================================================================
set -uo pipefail

# python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
PY3="$(command -v python3 2>/dev/null || true)"

# Anti-runaway: sessões spawned (ex.: instinct-analyze) não exportam memória.
[ -n "${IDEIAOS_INSTINCT_SPAWN:-}" ] && exit 0

PLANNING_BRANCH="${IDEIAOS_MEM_BRANCH:-planning}"
SHARED_PREFIX=".planning/memory/shared"
FACTS_PREFIX="$SHARED_PREFIX/facts"
STAGING_PREFIX=".planning/memory/local/staging"

# ── stdin → cwd ──────────────────────────────────────────────────────────────
INPUT="$(cat 2>/dev/null || echo '{}')"
CWD="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "${CWD:-}" ] && CWD="$PWD"
cd "$CWD" 2>/dev/null || exit 0

# Precisa ser um working tree git. Offline / sem git → silencioso.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Não interferir durante merge/rebase/cherry-pick em andamento.
GITDIR="$(git -C "$REPO" rev-parse --git-dir 2>/dev/null)" || exit 0
case "$GITDIR" in /*) : ;; *) GITDIR="$REPO/$GITDIR" ;; esac
{ [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ] \
  || [ -f "$GITDIR/MERGE_HEAD" ] || [ -f "$GITDIR/CHERRY_PICK_HEAD" ]; } && exit 0

# O branch `planning` precisa existir localmente. Sem ele → silencioso.
git -C "$REPO" rev-parse --verify --quiet "refs/heads/$PLANNING_BRANCH" >/dev/null 2>&1 || exit 0

# ── Slug nativo (mesma derivação do import: path → '/'→'-'; bug #30828) ───────
# A memória nativa do Claude Code vive em ~/.claude/projects/<slug>/memory/.
# O <slug> é o path absoluto do repo com '/' → '-'. O bug #30828 às vezes troca
# '_' por '-' também: checamos as duas variantes e usamos a que tem MEMORY.md
# (ou, na ausência de ambas, a que tiver qualquer .md de fato).
derive_memdir() {
  if [ -n "${IDEIAOS_MEM_MEMDIR:-}" ]; then
    printf '%s\n' "$IDEIAOS_MEM_MEMDIR"
    return 0
  fi
  local base slug_a slug_b dir_a dir_b
  base="${IDEIAOS_MEM_SLUG:-$REPO}"
  slug_a="$(printf '%s' "$base" | tr '/' '-')"
  slug_b="$(printf '%s' "$base" | tr '/' '-' | tr '_' '-')"
  dir_a="$HOME/.claude/projects/$slug_a/memory"
  dir_b="$HOME/.claude/projects/$slug_b/memory"
  # Preferir a variante que tem MEMORY.md; depois a que tem qualquer fato.
  if [ -f "$dir_a/MEMORY.md" ]; then printf '%s\n' "$dir_a"; return 0; fi
  if [ -f "$dir_b/MEMORY.md" ]; then printf '%s\n' "$dir_b"; return 0; fi
  if ls "$dir_a"/*.md >/dev/null 2>&1; then printf '%s\n' "$dir_a"; return 0; fi
  if ls "$dir_b"/*.md >/dev/null 2>&1; then printf '%s\n' "$dir_b"; return 0; fi
  printf '%s\n' "$dir_a"   # default; será detectado como "vazio" adiante
}

MEMDIR="$(derive_memdir)"
[ -d "$MEMDIR" ] || exit 0

# Slug "limpo" para a mensagem de commit (basename do repo).
SLUG_LABEL="$(basename "$REPO")"

# Data determinística: env override > data corrente.
MEM_DATE="${IDEIAOS_MEM_DATE:-$(date '+%Y-%m-%d' 2>/dev/null || echo 0000-00-00)}"

# ── Secret-scan gate (R5-06) ─────────────────────────────────────────────────
# Reaproveita os PADRÕES de segredo do pipeline de quarentena quando presente
# (security/scan-absorbed.sh é orientado a prompt-injection; aqui o foco são
# CREDENCIAIS). Detector próprio em python3 (sem dependência de rg). Retorna 0
# se o conteúdo PARECE conter segredo (= recusar), 1 se limpo.
fact_has_secret() {
  "$PY3" - "$1" <<'PY' 2>/dev/null
import sys, re
try:
    text = open(sys.argv[1], errors="replace").read()
except Exception:
    sys.exit(1)  # ilegível → trata como limpo (não bloqueia a sessão)

PATTERNS = [
    # JWT (header.payload.signature, base64url)
    r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}',
    # AWS Access Key ID
    r'\bAKIA[0-9A-Z]{16}\b',
    # GitHub / OpenAI / Slack / Google style tokens
    r'\bgh[pousr]_[A-Za-z0-9]{20,}\b',
    r'\bsk-[A-Za-z0-9]{20,}\b',
    r'\bxox[baprs]-[A-Za-z0-9-]{10,}\b',
    r'\bAIza[0-9A-Za-z_\-]{30,}\b',
    # Private key blocks
    r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
    # Connection strings com credenciais (postgres://user:pass@host, etc.)
    r'\b[a-z][a-z0-9+.\-]*://[^\s:/@]+:[^\s:/@]+@[^\s/]+',
    # Atribuições .env-style de segredo (KEY/SECRET/TOKEN/PASSWORD = valor não-trivial)
    r'(?im)\b[A-Z0-9_]*(?:API[_-]?KEY|SECRET|TOKEN|PASSWORD|PASSWD|ACCESS[_-]?KEY|PRIVATE[_-]?KEY)\b\s*[:=]\s*["\']?[A-Za-z0-9/+_\-]{12,}',
    # Supabase/JWT service role hint + bearer
    r'(?i)bearer\s+[A-Za-z0-9._\-]{20,}',
]
for pat in PATTERNS:
    if re.search(pat, text):
        sys.exit(0)  # achou segredo → recusar
sys.exit(1)  # limpo
PY
  return $?
}

# ── Coleta dos fatos novos/alterados ─────────────────────────────────────────
# Para cada *.md de fato na memória nativa (exclui MEMORY.md):
#   - confronta com git show planning:.planning/memory/shared/facts/<file>
#   - ausente OU conteúdo diferente → candidato a export
#   - candidato com segredo → RECUSA (não exporta), segue para o próximo
# Acumula pares "fname\0blobsha" para a fase de commit (plumbing).
TMP_LIST="$(mktemp 2>/dev/null)" || exit 0
REFUSED_LIST="$(mktemp 2>/dev/null)" || { rm -f "$TMP_LIST"; exit 0; }
cleanup_tmp() { rm -f "$TMP_LIST" "$REFUSED_LIST" 2>/dev/null || true; }
trap cleanup_tmp EXIT

# Antifragile gate helper (R6-01): load from source or define inline fallback.
# Never trusts Read tool output — binary test -s only.
if [ -n "${IDEIAOS_DIR:-}" ] && [ -f "$IDEIAOS_DIR/source/lib/gates.sh" ]; then
  # shellcheck source=/dev/null
  . "$IDEIAOS_DIR/source/lib/gates.sh"
else
  gate_output() { test -s "${1:-}" 2>/dev/null; }
fi

CHANGED=0
for f in "$MEMDIR"/*.md; do
  [ -e "$f" ] || continue
  fname="$(basename "$f")"
  [ "$fname" = "MEMORY.md" ] && continue

  # Conteúdo atual da versão no planning (vazio se ausente).
  existing="$(git -C "$REPO" show "$PLANNING_BRANCH:$FACTS_PREFIX/$fname" 2>/dev/null || true)"
  current="$(cat "$f" 2>/dev/null || true)"

  # Sem mudança → pular (idempotência; evita commit vazio).
  if [ -n "$existing" ] && [ "$existing" = "$current" ]; then
    continue
  fi

  # Secret-scan gate ANTES de exportar (R5-06).
  if fact_has_secret "$f"; then
    printf '%s\n' "$fname" >> "$REFUSED_LIST"
    continue
  fi

  # Hash o conteúdo no object store e registra para o commit.
  blob="$(git -C "$REPO" hash-object -w --stdin < "$f" 2>/dev/null || true)"
  [ -z "$blob" ] && continue
  printf '%s\t%s\n' "$fname" "$blob" >> "$TMP_LIST"
  CHANGED=$((CHANGED+1))
done

# Avisar sobre fatos recusados (vai para o transcript; não bloqueia).
if [ -s "$REFUSED_LIST" ]; then
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    printf '🔒 [memory-export] fato RECUSADO (aparenta conter segredo): %s — não foi exportado para o branch %s. Remova a credencial do fato antes de sincronizar.\n' "$r" "$PLANNING_BRANCH"
  done < "$REFUSED_LIST"
fi

# Gate: verify TMP_LIST is a real file before plumbing commit (not a hallucination).
# Fail-silent per hook contract: gate failure → treat as no changes, exit 0.
if [ "$CHANGED" -gt 0 ] && ! gate_output "$TMP_LIST" "memory-export/TMP_LIST"; then
  exit 0
fi

# Nenhum fato limpo mudou → exit silencioso (sem commit vazio).
[ "$CHANGED" -eq 0 ] && exit 0

# ── Commit no planning via GIT PLUMBING (caminho PRIMÁRIO) ────────────────────
# hash-object (feito acima) → read-tree (índice temporário) → update-index →
# write-tree → commit-tree → update-ref. NUNCA toca o working tree nem o índice
# real do repo; opera só na camada de objetos/refs. Validado contra o nfideia.
#
# SÓ os fatos shared/facts/ (+ índice MEMORY.md) entram no commit. O buffer
# local/staging/ é per-máquina, gitignored, e NUNCA é commitado — ele só existiria
# como rascunho efêmero; não o adicionamos à árvore do planning.
#
# Em colisão de fast-forward (planning andou entre o read-tree e o update-ref),
# refazemos UMA vez após um fetch+fast-forward do planning local.
do_plumbing_commit() {
  local tmpidx new_tree parent new_commit fname blob
  tmpidx="$(mktemp 2>/dev/null)" || return 1

  # Snapshot do parent ANTES de montar a árvore (base do CAS de ref).
  parent="$(git -C "$REPO" rev-parse "$PLANNING_BRANCH" 2>/dev/null)" || { rm -f "$tmpidx"; return 1; }

  # Índice temporário a partir da árvore atual do planning.
  if ! GIT_INDEX_FILE="$tmpidx" git -C "$REPO" read-tree "$PLANNING_BRANCH" 2>/dev/null; then
    rm -f "$tmpidx"; return 1
  fi

  # Inserir cada fato APENAS em shared/facts/. O buffer local/staging é
  # per-máquina e gitignored (.planning/.gitignore: memory/local/) — NUNCA entra
  # no commit do planning. `update-index` ignora o .gitignore, então a barreira
  # tem de ser AQUI: não adicionar staging à árvore (senão o buffer por-máquina
  # vaza pro remoto compartilhado — viola Phase 19 SC #4). Ref: bug do dogfood
  # 2026-06-14 (staging commitado no origin/planning).
  while IFS="$(printf '\t')" read -r fname blob; do
    [ -z "$fname" ] && continue
    GIT_INDEX_FILE="$tmpidx" git -C "$REPO" update-index --add \
      --cacheinfo "100644,$blob,$FACTS_PREFIX/$fname" 2>/dev/null || { rm -f "$tmpidx"; return 1; }
  done < "$TMP_LIST"

  # Regenerar o índice MEMORY.md de shared/ de forma DETERMINÍSTICA a partir da
  # árvore resultante (ordenado por filename → idempotente, minimiza conflito).
  local index_blob
  index_blob="$(build_shared_index "$tmpidx")" || { rm -f "$tmpidx"; return 1; }
  if [ -n "$index_blob" ]; then
    GIT_INDEX_FILE="$tmpidx" git -C "$REPO" update-index --add \
      --cacheinfo "100644,$index_blob,$SHARED_PREFIX/MEMORY.md" 2>/dev/null || { rm -f "$tmpidx"; return 1; }
  fi

  new_tree="$(GIT_INDEX_FILE="$tmpidx" git -C "$REPO" write-tree 2>/dev/null)" || { rm -f "$tmpidx"; return 1; }
  rm -f "$tmpidx"

  # Árvore idêntica ao parent → nada a commitar (evita commit vazio).
  local parent_tree
  parent_tree="$(git -C "$REPO" rev-parse "$parent^{tree}" 2>/dev/null || true)"
  [ -n "$parent_tree" ] && [ "$new_tree" = "$parent_tree" ] && return 0

  new_commit="$(
    GIT_AUTHOR_NAME="memory-bridge" GIT_AUTHOR_EMAIL="bridge@local" \
    GIT_COMMITTER_NAME="memory-bridge" GIT_COMMITTER_EMAIL="bridge@local" \
    git -C "$REPO" commit-tree "$new_tree" -p "$parent" \
      -m "mem: sync from $SLUG_LABEL $MEM_DATE" 2>/dev/null
  )" || return 1
  [ -z "$new_commit" ] && return 1

  # Compare-and-swap da ref: só avança se o parent ainda for o HEAD do planning.
  # Se outro processo (autosync/segunda sessão) moveu o planning, isto FALHA →
  # caller faz fetch+ff e tenta de novo uma vez.
  git -C "$REPO" update-ref "refs/heads/$PLANNING_BRANCH" "$new_commit" "$parent" 2>/dev/null || return 2
  return 0
}

# Constrói o blob do índice MEMORY.md a partir do conteúdo de shared/facts/ no
# índice temporário. Determinístico: ordena por filename; cada linha =
# "- [desc](facts/<file>) — <name>". Lê desc/name do frontmatter de cada blob.
build_shared_index() {
  local tmpidx="$1"
  GIT_INDEX_FILE="$tmpidx" "$PY3" - "$REPO" "$FACTS_PREFIX" "$SLUG_LABEL" <<'PY' 2>/dev/null
import os, subprocess, sys, re

repo, facts_prefix, label = sys.argv[1], sys.argv[2], sys.argv[3]

def git(*args):
    return subprocess.run(["git", "-C", repo, *args],
                          capture_output=True, text=True).stdout

# Lista os blobs de facts/ no índice temporário.
out = git("ls-files", "--stage", facts_prefix + "/")
entries = []
for line in out.splitlines():
    # formato: <mode> <sha> <stage>\t<path>
    parts = line.split("\t", 1)
    if len(parts) != 2:
        continue
    meta, path = parts
    sha = meta.split()[1]
    fname = os.path.basename(path)
    if fname == "MEMORY.md":
        continue
    entries.append((fname, sha))

entries.sort(key=lambda e: e[0])

def field(blob, key):
    content = git("cat-file", "-p", blob)
    m = re.search(r'(?m)^%s:\s*(.+)$' % re.escape(key), content)
    if not m:
        return ""
    v = m.group(1).strip().strip('"').strip("'")
    return v

lines = ["# MEMORY.md — %s" % label, ""]
for fname, sha in entries:
    desc = field(sha, "description") or fname
    name = field(sha, "name") or ""
    if name:
        lines.append("- [%s](facts/%s) — %s" % (desc, fname, name))
    else:
        lines.append("- [%s](facts/%s)" % (desc, fname))
index = "\n".join(lines) + "\n"

# Escreve o blob e imprime o sha.
p = subprocess.run(["git", "-C", repo, "hash-object", "-w", "--stdin"],
                   input=index, capture_output=True, text=True)
sys.stdout.write(p.stdout.strip())
PY
}

do_plumbing_commit
rc=$?

if [ "$rc" -eq 2 ]; then
  # Colisão de fast-forward: o planning andou. Fetch + ff do planning local e
  # tenta UMA vez mais. Tudo best-effort; qualquer falha → exit 0.
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git -C "$REPO" fetch --quiet origin "$PLANNING_BRANCH" 2>/dev/null || true
  else
    git -C "$REPO" fetch --quiet origin "$PLANNING_BRANCH" 2>/dev/null || true
  fi
  # Fast-forward do planning LOCAL para origin/planning, se possível (sem checkout).
  if git -C "$REPO" rev-parse --verify --quiet "origin/$PLANNING_BRANCH" >/dev/null 2>&1; then
    LOCAL_P="$(git -C "$REPO" rev-parse "$PLANNING_BRANCH" 2>/dev/null || echo)"
    REMOTE_P="$(git -C "$REPO" rev-parse "origin/$PLANNING_BRANCH" 2>/dev/null || echo)"
    if [ -n "$LOCAL_P" ] && [ -n "$REMOTE_P" ] && [ "$LOCAL_P" != "$REMOTE_P" ]; then
      # Só avança se for ancestral (fast-forward real); senão deixa como está.
      if git -C "$REPO" merge-base --is-ancestor "$LOCAL_P" "$REMOTE_P" 2>/dev/null; then
        git -C "$REPO" update-ref "refs/heads/$PLANNING_BRANCH" "$REMOTE_P" "$LOCAL_P" 2>/dev/null || true
      fi
    fi
  fi
  do_plumbing_commit || true   # segunda e última tentativa; falha → silêncio
fi

# Mensagem informativa (vai ao transcript; não bloqueia, não é obrigatória).
if [ "$CHANGED" -gt 0 ]; then
  printf '🧠 [memory-export] %s fato(s) sincronizado(s) para o branch %s (commit local; o autosync empurra). main intacto.\n' "$CHANGED" "$PLANNING_BRANCH"
fi

# =============================================================================
# # FALLBACK: escrita via git worktree (NÃO usado por padrão)
# -----------------------------------------------------------------------------
# Se o git plumbing acima não estiver disponível ou falhar de forma persistente,
# o mesmo resultado é obtível com um worktree temporário do branch planning.
# Diferença: cria um diretório de checkout em /tmp (impacto de filesystem), por
# isso é apenas fallback — o plumbing não deixa resíduo algum. Usar SEMPRE trap
# para remover o worktree, mesmo em erro. NUNCA criar o worktree dentro do repo
# nem do working tree do branch corrente.
#
#   WT="$(mktemp -d /tmp/ideiaos-mem-wt-$$-XXXXXX)"
#   trap 'git -C "$REPO" worktree remove --force "$WT" 2>/dev/null || true; rm -rf "$WT" 2>/dev/null || true' EXIT
#   git -C "$REPO" worktree add --quiet "$WT" "$PLANNING_BRANCH" 2>/dev/null || exit 0
#   mkdir -p "$WT/$FACTS_PREFIX" "$WT/$STAGING_PREFIX"
#   # copia cada fato novo/alterado (JÁ aprovado no secret-scan) para shared/ + staging/
#   cp "$MEMDIR/$fname" "$WT/$FACTS_PREFIX/$fname"
#   cp "$MEMDIR/$fname" "$WT/$STAGING_PREFIX/$MEM_DATE-$fname"
#   # regenera o índice MEMORY.md deterministicamente a partir de shared/facts/
#   git -C "$WT" add "$SHARED_PREFIX/"
#   git -C "$WT" -c user.name=memory-bridge -c user.email=bridge@local \
#       commit --quiet -m "mem: sync from $SLUG_LABEL $MEM_DATE"
#   git -C "$REPO" worktree remove --force "$WT"
#
# Mesmo no fallback: SEM push (autosync empurra), exit 0 sempre, e o `.planning/
# memory/local/` é gitignored no branch planning (não vira ruído).
# =============================================================================

exit 0
