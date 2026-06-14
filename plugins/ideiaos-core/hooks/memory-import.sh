#!/usr/bin/env bash
# =============================================================================
# memory-import.sh — IdeiaOS SessionStart hook (v5 cross-IDE shared memory)
# SOURCE: IdeiaOS v5 — Phase 20 / R5-07 (import bridge)
#
# Importa os fatos do store canônico compartilhado (que vive SOMENTE no branch
# `planning`, nunca no `main`) para a memória nativa da IDE
# (~/.claude/projects/<slug>/memory/) e regenera a ponte do Cursor
# (.cursor/rules/memory-bridge.mdc). Roda no SessionStart, DEPOIS de
# git-sync-check.sh (que já fez o fetch dos refs do remote).
#
# Leitura do store é SEMPRE read-only sobre o branch planning, sem checkout:
#   git show planning:.planning/memory/shared/MEMORY.md
#   git archive planning .planning/memory/shared/ | tar -x -C <tmp>
# (mesmo padrão de git-sync-check.sh — não suja o working tree, não troca branch).
#
# INVARIANTE LOVABLE: este hook NUNCA escreve no working tree do branch corrente
# (nada de .lovable_mem_tmp.md). A única escrita versionada é o .mdc do Cursor,
# que é gitignored. Tudo o mais vai para paths machine-local fora do repo
# (~/.claude/projects/.../memory/, ~/.local/state/).
#
# Contrato de resiliência: exit 0 em QUALQUER falha (offline, sem origin, sem
# branch planning, sem memória shared). Nunca bloqueia o SessionStart.
#
# Sem-jq: só /usr/bin/python3. set -uo pipefail. exit 0 puro/sempre.
# Entrada (stdin): JSON SessionStart { session_id, cwd, source }
# Saída (stdout): JSON { "systemMessage": "..." } com a contagem importada
#                 (ou nada, se nada mudou / fora de escopo).
# =============================================================================
set -uo pipefail

# Anti-runaway: sessões spawned de análise NÃO fazem import (mesma guarda dos
# Stop hooks de observação — evita custo/loop em background).
[ -n "${IDEIAOS_INSTINCT_SPAWN:-}" ] && exit 0

# ── 1) cwd do SessionStart (extraído sem jq, igual git-sync-check.sh) ─────────
INPUT="$(cat 2>/dev/null || true)"
CWD="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "${CWD:-}" ] && CWD="$PWD"
cd "$CWD" 2>/dev/null || exit 0

# Precisa ser um working tree git.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Não interferir durante merge/rebase/cherry-pick em andamento.
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
{ [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ] \
  || [ -f "$GITDIR/MERGE_HEAD" ] || [ -f "$GITDIR/CHERRY_PICK_HEAD" ]; } && exit 0

# ── 2) Branch planning precisa existir (local OU origin) ──────────────────────
# git-sync-check.sh já fez o fetch; aqui só lemos os refs. Preferimos o ref que
# está mais à frente para ler a versão mais nova do store sem precisar de pull.
PLANNING_REF=""
if git rev-parse --verify --quiet "origin/planning" >/dev/null 2>&1; then
  PLANNING_REF="origin/planning"
elif git rev-parse --verify --quiet "planning" >/dev/null 2>&1; then
  PLANNING_REF="planning"
fi
# Se existem os dois e o local está atrás do origin, usar origin (store mais novo).
if [ "$PLANNING_REF" = "origin/planning" ] && git rev-parse --verify --quiet "planning" >/dev/null 2>&1; then
  L_BEHIND="$(git rev-list --count "planning..origin/planning" 2>/dev/null || echo 0)"
  case "$L_BEHIND" in ''|*[!0-9]*) L_BEHIND=0 ;; esac
  [ "$L_BEHIND" -eq 0 ] && PLANNING_REF="planning"
fi
# Sem branch planning em lugar nenhum → offline-safe, nada a importar.
[ -z "$PLANNING_REF" ] && exit 0

PLANNING_SHA="$(git rev-parse --verify --quiet "$PLANNING_REF" 2>/dev/null || true)"
[ -z "$PLANNING_SHA" ] && exit 0

# O store precisa existir nesse ref (primeiro export pode ainda não ter rodado).
SHARED_PREFIX=".planning/memory/shared"
git ls-tree --name-only "$PLANNING_REF" "$SHARED_PREFIX/" >/dev/null 2>&1 || exit 0
git cat-file -e "$PLANNING_REF:$SHARED_PREFIX/MEMORY.md" 2>/dev/null \
  || git ls-tree --name-only "$PLANNING_REF" "$SHARED_PREFIX/facts/" >/dev/null 2>&1 \
  || exit 0

# ── 3) Slug nativo + bug #30828 (variante com underscore e com hífen) ─────────
# Derivação canônica: caminho absoluto do repo root, '/' → '-', resto preservado
# (idêntico ao formato real ~/.claude/projects/<slug>/). O bug #30828 troca '_'
# por '-' de forma não-determinística, criando um 2º diretório para o mesmo
# projeto — então checamos AMBAS as variantes e usamos a que JÁ tem memória.
SLUG_CANON="$(printf '%s' "$REPO_ROOT" | tr '/' '-')"
SLUG_HYPHEN="$(printf '%s' "$SLUG_CANON" | tr '_' '-')"

PROJ_BASE="$HOME/.claude/projects"
pick_memory_dir() {
  # Escolhe o diretório de memória nativo:
  #   1) variante (canônica/hífen) que já tem MEMORY.md
  #   2) senão, variante que já tem o diretório memory/
  #   3) senão, a canônica (será criada)
  local d_canon="$PROJ_BASE/$SLUG_CANON/memory"
  local d_hyphen="$PROJ_BASE/$SLUG_HYPHEN/memory"
  if [ -f "$d_canon/MEMORY.md" ]; then echo "$d_canon"; return; fi
  if [ "$SLUG_HYPHEN" != "$SLUG_CANON" ] && [ -f "$d_hyphen/MEMORY.md" ]; then echo "$d_hyphen"; return; fi
  if [ -d "$d_canon" ]; then echo "$d_canon"; return; fi
  if [ "$SLUG_HYPHEN" != "$SLUG_CANON" ] && [ -d "$d_hyphen" ]; then echo "$d_hyphen"; return; fi
  echo "$d_canon"
}
MEM_DIR="$(pick_memory_dir)"
# Chave de estado: basename do slug escolhido (estável entre as 2 variantes na
# medida em que sempre apontamos para o dir que já existe).
SLUG_KEY="$(basename "$(dirname "$MEM_DIR")")"

# ── 4) Freshness guard (espelha git-sync-check.sh / backlog-sync-check.sh) ────
# Se o SHA do planning não mudou desde o último import, é no-op: nada de
# git archive redundante, nada de regenerar índice.
STATE_DIR="$HOME/.local/state/ideiaos-mem-import"
SHA_FILE="$STATE_DIR/$SLUG_KEY.sha"
mkdir -p "$STATE_DIR" 2>/dev/null || true
if [ -f "$SHA_FILE" ]; then
  LAST_SHA="$(tr -d ' \n' < "$SHA_FILE" 2>/dev/null || true)"
  if [ "$LAST_SHA" = "$PLANNING_SHA" ]; then
    exit 0
  fi
fi

# ── 5) Extrair o store shared do planning para um tmp (read-only, sem checkout) ─
TMP_EXTRACT="$(mktemp -d "${TMPDIR:-/tmp}/ideiaos-mem-import.XXXXXX" 2>/dev/null)" || exit 0
cleanup() { rm -rf "$TMP_EXTRACT" 2>/dev/null || true; }
trap cleanup EXIT

# git archive extrai a subtree shared/ inteira; tolerante a falha de rede/ref.
if command -v timeout >/dev/null 2>&1; then
  timeout 20 git archive "$PLANNING_REF" "$SHARED_PREFIX/" 2>/dev/null | tar -x -C "$TMP_EXTRACT" 2>/dev/null || true
else
  git archive "$PLANNING_REF" "$SHARED_PREFIX/" 2>/dev/null | tar -x -C "$TMP_EXTRACT" 2>/dev/null || true
fi

SHARED_DIR="$TMP_EXTRACT/$SHARED_PREFIX"
FACTS_DIR="$SHARED_DIR/facts"
# Sem facts extraídos → nada a importar (mas registra o SHA pra não retentar).
if [ ! -d "$FACTS_DIR" ]; then
  printf '%s\n' "$PLANNING_SHA" > "$SHA_FILE" 2>/dev/null || true
  exit 0
fi

# ── 6) Copiar facts novos/atualizados → memória nativa ───────────────────────
# Regras (R5-07):
#   - preserva fatos LOCAL-ONLY (que não existem no shared/) — nunca apaga
#   - não sobrescreve uma versão local MAIS NOVA (compara hash; em empate de
#     conteúdo é no-op; se diferente, shared vence por ser a fonte canônica
#     multi-máquina, exceto se o local for estritamente mais novo por mtime)
#   - cópia flat: shared/facts/<file>.md → memory/<file>.md (mesmo formato nativo)
mkdir -p "$MEM_DIR" 2>/dev/null || { printf '%s\n' "$PLANNING_SHA" > "$SHA_FILE" 2>/dev/null || true; exit 0; }

IMPORTED="$(/usr/bin/python3 - "$FACTS_DIR" "$MEM_DIR" <<'PYEOF' 2>/dev/null || echo 0
import sys, os, hashlib, shutil

facts_dir = sys.argv[1]
mem_dir   = sys.argv[2]

def sha256(path):
    try:
        h = hashlib.sha256()
        with open(path, "rb") as fh:
            for chunk in iter(lambda: fh.read(65536), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return None

imported = 0
try:
    names = sorted(os.listdir(facts_dir))
except Exception:
    print(0)
    sys.exit(0)

for name in names:
    if not name.endswith(".md"):
        continue
    if name == "MEMORY.md":
        continue
    src = os.path.join(facts_dir, name)
    if not os.path.isfile(src):
        continue
    dst = os.path.join(mem_dir, name)

    if not os.path.exists(dst):
        # fato novo no shared → importar
        try:
            shutil.copy2(src, dst)
            imported += 1
        except Exception:
            pass
        continue

    # já existe localmente: comparar conteúdo por hash
    sh_src = sha256(src)
    sh_dst = sha256(dst)
    if sh_src is not None and sh_src == sh_dst:
        # idêntico → no-op (idempotência)
        continue

    # conteúdo difere: não clobberar versão local estritamente mais nova
    try:
        m_src = os.path.getmtime(src)
        m_dst = os.path.getmtime(dst)
    except Exception:
        m_src = m_dst = 0
    if m_dst > m_src:
        # local é mais novo → preserva (não sobrescreve)
        continue
    # shared é igual/mais novo e difere → atualiza
    try:
        shutil.copy2(src, dst)
        imported += 1
    except Exception:
        pass

print(imported)
PYEOF
)"
case "${IMPORTED:-}" in ''|*[!0-9]*) IMPORTED=0 ;; esac

# ── 7) Regenerar o índice MEMORY.md nativo (rebuild-from-scan, idempotente) ───
# NUNCA edita in-place: varre o diretório e reescreve o índice do zero, ordenado.
# Inclui fatos local-only (preservados) + os importados. Formato idêntico ao
# real: "- [<description>](<file>) — <summary>".
PROJ_NAME="$(basename "$REPO_ROOT")"
/usr/bin/python3 - "$MEM_DIR" "$PROJ_NAME" <<'PYEOF' 2>/dev/null || true
import sys, os, re

mem_dir   = sys.argv[1]
proj_name = sys.argv[2]

def front(path):
    """Lê name/description do frontmatter YAML simples (sem dependência)."""
    name = desc = ""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            in_fm = False
            seen_open = False
            for line in fh:
                s = line.rstrip("\n")
                if s.strip() == "---":
                    if not seen_open:
                        seen_open = True
                        in_fm = True
                        continue
                    else:
                        break
                if in_fm:
                    m = re.match(r"\s*name:\s*(.+)\s*$", s)
                    if m and not name:
                        name = m.group(1).strip()
                    m = re.match(r"\s*description:\s*(.+)\s*$", s)
                    if m and not desc:
                        desc = m.group(1).strip()
    except Exception:
        pass
    return name, desc

try:
    files = sorted(
        f for f in os.listdir(mem_dir)
        if f.endswith(".md") and f != "MEMORY.md"
        and os.path.isfile(os.path.join(mem_dir, f))
    )
except Exception:
    sys.exit(0)

lines = [f"# MEMORY.md — {proj_name}", ""]
for f in files:
    name, desc = front(os.path.join(mem_dir, f))
    label = desc or name or f[:-3]
    summary = name or ""
    if summary and summary != label:
        lines.append(f"- [{label}]({f}) — {summary}")
    else:
        lines.append(f"- [{label}]({f})")

out = "\n".join(lines).rstrip() + "\n"
try:
    with open(os.path.join(mem_dir, "MEMORY.md"), "w", encoding="utf-8") as fh:
        fh.write(out)
except Exception:
    pass
PYEOF

# ── 8) Ponte do Cursor: .cursor/rules/memory-bridge.mdc (gitignored) ─────────
# Cursor não tem hooks; a ÚNICA via de sync é este .mdc com alwaysApply: true,
# regenerado a cada import. É gitignored (a entrada é adicionada pelo agente de
# guardrails) — não deve aparecer em `git status`. Regeneração é from-scan,
# idempotente, e nunca toca o working tree versionado.
CURSOR_RULES_DIR="$REPO_ROOT/.cursor/rules"
MDC_FILE="$CURSOR_RULES_DIR/memory-bridge.mdc"
mkdir -p "$CURSOR_RULES_DIR" 2>/dev/null || true

# Defesa branch-agnóstica (invariante Lovable): garante que o .mdc gerado e os
# paths de memória local fiquem ignorados via .git/info/exclude — local à máquina,
# vale em QUALQUER branch (inclusive main/Lovable), sem depender do .gitignore
# versionado por-branch. Fecha o caminho em que o .mdc escrito no working tree de
# um branch sem a entrada no .gitignore poderia ser commitado para o main.
GIT_DIR_PATH="$(git -C "$REPO_ROOT" rev-parse --git-dir 2>/dev/null || true)"
if [ -n "$GIT_DIR_PATH" ]; then
  case "$GIT_DIR_PATH" in /*) : ;; *) GIT_DIR_PATH="$REPO_ROOT/$GIT_DIR_PATH" ;; esac
  EXCLUDE_FILE="$GIT_DIR_PATH/info/exclude"
  mkdir -p "$GIT_DIR_PATH/info" 2>/dev/null || true
  for pat in ".cursor/rules/memory-bridge.mdc" ".planning/memory/local/" ".lovable_mem_tmp.md"; do
    if [ ! -f "$EXCLUDE_FILE" ] || ! grep -qxF "$pat" "$EXCLUDE_FILE" 2>/dev/null; then
      printf '%s\n' "$pat" >> "$EXCLUDE_FILE" 2>/dev/null || true
    fi
  done
fi
/usr/bin/python3 - "$MEM_DIR" "$PROJ_NAME" "$MDC_FILE" <<'PYEOF' 2>/dev/null || true
import sys, os, re

mem_dir   = sys.argv[1]
proj_name = sys.argv[2]
mdc_file  = sys.argv[3]

def front(path):
    name = desc = ""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            in_fm = False; seen_open = False
            for line in fh:
                s = line.rstrip("\n")
                if s.strip() == "---":
                    if not seen_open:
                        seen_open = True; in_fm = True; continue
                    else:
                        break
                if in_fm:
                    m = re.match(r"\s*name:\s*(.+)\s*$", s)
                    if m and not name: name = m.group(1).strip()
                    m = re.match(r"\s*description:\s*(.+)\s*$", s)
                    if m and not desc: desc = m.group(1).strip()
    except Exception:
        pass
    return name, desc

try:
    files = sorted(
        f for f in os.listdir(mem_dir)
        if f.endswith(".md") and f != "MEMORY.md"
        and os.path.isfile(os.path.join(mem_dir, f))
    )
except Exception:
    files = []

bullets = []
for f in files:
    name, desc = front(os.path.join(mem_dir, f))
    label = desc or name or f[:-3]
    bullets.append(f"- {label}")

body_facts = "\n".join(bullets) if bullets else "- (nenhum fato compartilhado ainda)"

content = (
    "---\n"
    "description: 'IdeiaOS shared memory bridge — fatos compartilhados do branch planning (gerado, gitignored)'\n"
    "alwaysApply: true\n"
    "---\n\n"
    f"# Memória compartilhada — {proj_name}\n\n"
    "> Gerado automaticamente pelo hook IdeiaOS `memory-import.sh` a cada SessionStart.\n"
    "> Fonte canônica: `planning:.planning/memory/shared/`. Não editar à mão.\n"
    "> Este arquivo é gitignored — não comitar.\n\n"
    "## Fatos compartilhados\n\n"
    f"{body_facts}\n"
)
try:
    with open(mdc_file, "w", encoding="utf-8") as fh:
        fh.write(content)
except Exception:
    pass
PYEOF

# ── 9) Gravar o SHA importado (freshness) e emitir systemMessage ─────────────
printf '%s\n' "$PLANNING_SHA" > "$SHA_FILE" 2>/dev/null || true

# Contagem total de fatos no store nativo (para a mensagem). Conta arquivos .md
# != MEMORY.md no diretório nativo.
TOTAL_FACTS="$(/usr/bin/python3 -c '
import os, sys
d = sys.argv[1]
try:
    n = sum(1 for f in os.listdir(d)
            if f.endswith(".md") and f != "MEMORY.md" and os.path.isfile(os.path.join(d, f)))
    print(n)
except Exception:
    print(0)
' "$MEM_DIR" 2>/dev/null || echo 0)"
case "${TOTAL_FACTS:-}" in ''|*[!0-9]*) TOTAL_FACTS=0 ;; esac

# Se nada foi importado nesta rodada, ficar silencioso (sem ruído).
[ "$IMPORTED" -eq 0 ] && exit 0

SHORT_SHA="$(printf '%s' "$PLANNING_SHA" | cut -c1-7)"
MSG="$(printf '🧠 [memory-import] %d fato(s) novo(s)/atualizado(s) importado(s) de %s (%s) para a memória nativa (%d no total). Ponte Cursor regenerada (.cursor/rules/memory-bridge.mdc).' \
  "$IMPORTED" "$PLANNING_REF" "$SHORT_SHA" "$TOTAL_FACTS")"

/usr/bin/python3 -c '
import json, sys
print(json.dumps({"systemMessage": sys.argv[1]}))
' "$MSG" 2>/dev/null || true

exit 0
