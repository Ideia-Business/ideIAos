#!/usr/bin/env bash
# =============================================================================
# check-manifest-drift.sh — detecta drift entre manifests/modules.json e o disco
#
# POR QUÊ: o manifesto é a fonte declarativa do catálogo de código próprio do
# IdeiaOS, mas nada o reconciliava com o disco — um hook/skill/agent novo podia
# existir em source/ sem entrada no manifesto (drift silencioso). Este gate fecha
# esse buraco (gap "drift manifesto↔disco não é detectado por nenhum gate").
#
# Dois regimes (a catalogação de rules é por-CONCEITO, não 1:1):
#   • hook / skill / agent  → comparação 1:1 por arquivo. Órfão (disco sem
#     manifesto) ou fantasma (manifesto sem arquivo) = DRIFT ACIONÁVEL.
#   • rule                  → cobertura: um arquivo source/rules/X/y.md é coberto
#     se há entrada com source == o arquivo OU == o grupo "source/rules/X/".
#     Não-coberto = REPORTADO (visibilidade), não conta como falha (catalogar
#     cada rule é decisão de granularidade pendente).
#
# Uso:  bash scripts/check-manifest-drift.sh            # advisory (exit 0)
#       bash scripts/check-manifest-drift.sh --strict   # exit 1 se houver órfão 1:1
#       bash scripts/check-manifest-drift.sh --quiet     # só o resumo
#
# Exit: 0 = sem órfão 1:1 (ou advisory) · 1 = órfão 1:1 com --strict · 2 = erro
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/manifests/modules.json"
STRICT=0; QUIET=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    --quiet)  QUIET=1 ;;
    *) echo "uso: check-manifest-drift.sh [--strict] [--quiet]" >&2; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "python3 ausente — não dá para parsear o manifesto" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "manifesto ausente: $MANIFEST" >&2; exit 2; }

python3 - "$ROOT" "$MANIFEST" "$STRICT" "$QUIET" <<'PY'
import json, sys, os, glob
from collections import defaultdict

root, manifest, strict, quiet = sys.argv[1], sys.argv[2], sys.argv[3] == '1', sys.argv[4] == '1'
G, Y, R, C, N = '\033[0;32m', '\033[1;33m', '\033[0;31m', '\033[0;36m', '\033[0m'
mods = json.load(open(manifest)).get('modules', [])

# source paths por kind (normalizados, sem barra final p/ comparação)
src_by_kind = defaultdict(set)
for m in mods:
    s = (m.get('source') or '').rstrip('/')
    if s:
        src_by_kind[m.get('kind')].add(s)

missing = 0   # órfãos 1:1 (acionáveis)
drift_rules = 0
def log(*a):
    if not quiet:
        print(*a)

def check_1to1(kind, disk_paths, label):
    global missing
    man = src_by_kind.get(kind, set())
    disk = set(p.rstrip('/') for p in disk_paths)
    orphans = sorted(disk - man)   # no disco, fora do manifesto
    ghosts  = sorted(man - disk)   # no manifesto, sem arquivo
    log(f"\n{C}── {label} (1:1) ──{N}")
    for o in orphans:
        log(f"  {R}❌{N} órfão no disco SEM entrada no manifesto: {o}"); missing += 1
    for g in ghosts:
        log(f"  {Y}⚠️ {N} no manifesto mas SEM arquivo no disco: {g}")
    if not orphans and not ghosts:
        log(f"  {G}✅{N} {len(disk)} em sincronia (disco == manifesto)")
    else:
        log(f"  resumo: disco={len(disk)} · manifesto={len(man)} · órfãos={len(orphans)} · fantasmas={len(ghosts)}")

# hooks runtime (exclui test-*)
hooks = [f for f in glob.glob(f"{root}/source/hooks/*.sh")
         if not os.path.basename(f).startswith('test-')]
check_1to1('hook', [os.path.relpath(f, root) for f in hooks], 'hooks de runtime')

# skills (dir com SKILL.md → source aponta p/ .../SKILL.md)
skills = [f"source/skills/{os.path.basename(d.rstrip('/'))}/SKILL.md"
          for d in glob.glob(f"{root}/source/skills/*/") if os.path.exists(d + 'SKILL.md')]
check_1to1('skill', skills, 'skills')

# agents
agents = [os.path.relpath(f, root) for f in glob.glob(f"{root}/source/agents/*.md")]
check_1to1('agent', agents, 'agents')

# rules — cobertura (arquivo OU grupo)
rule_srcs = src_by_kind.get('rule', set())   # paths: arquivos e/ou dirs-grupo
log(f"\n{C}── rules (cobertura por arquivo OU grupo) ──{N}")
by_subdir = defaultdict(lambda: [0, 0])  # subdir → [coberto, total]
uncovered = []
for f in glob.glob(f"{root}/source/rules/**/*.md", recursive=True):
    rel = os.path.relpath(f, root)
    if os.path.basename(rel).upper() == 'README.MD':
        continue
    sub = rel.split('/')[2] if len(rel.split('/')) > 2 else '(raiz)'
    group = '/'.join(rel.split('/')[:3])  # source/rules/<sub>
    covered = (rel in rule_srcs) or (group in rule_srcs)
    by_subdir[sub][1] += 1
    if covered:
        by_subdir[sub][0] += 1
    else:
        uncovered.append(rel)
for sub in sorted(by_subdir):
    cov, tot = by_subdir[sub]
    mark = f"{G}✅{N}" if cov == tot else f"{Y}⚠️ {N}"
    log(f"  {mark} {sub}/: {cov}/{tot} cobertas no manifesto")
drift_rules = len(uncovered)
if uncovered and not quiet:
    log(f"  {Y}→ {drift_rules} rules no disco sem cobertura no manifesto (decisão de granularidade pendente):{N}")
    for u in uncovered[:8]:
        log(f"      {u}")
    if drift_rules > 8:
        log(f"      … +{drift_rules - 8} outras")

# resumo
print(f"\n{C}━━━ Resumo do drift manifesto↔disco ━━━{N}")
print(f"  órfãos 1:1 (hook/skill/agent, ACIONÁVEIS): {missing}")
print(f"  rules sem cobertura (visibilidade): {drift_rules}")
if missing > 0:
    print(f"  {R}→ corrija adicionando as entradas órfãs a manifests/modules.json (e check-plugin-membership.sh se for plugin).{N}")
    sys.exit(1 if strict else 0)
print(f"  {G}✅ sem órfão 1:1.{N}")
sys.exit(0)
PY
