# R15-19 — `idea update` (reconcilia hooks+overlay+daemon, prova equivalência) · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 2) · **Veredito:** pass (13/13 por exit-code).

## Problema (2 estratégias de daemon coexistindo)

O caminho de update tinha **duas** estratégias para o mesmo daemon, e elas rodavam JUNTAS no
`ideiaos-update.sh`: os patchers **in-place** (steps 2/2b/2c/2d — `sed -i`/grep/python aplicam deltas
no binário deployado) **e** o **cp-canônico** (step 2e — `cp` da fonte versionada). O 2e roda **depois**
e sobrescreve o binário inteiro, **anulando** os 4 patchers. Confuso e frágil.

## O que foi feito

### 1. Helper único `source/lib/redeploy-daemon.sh` (NOVO)
`redeploy_autosync_daemon SRC DST` → `cmp`-idempotente, cópia atômica (`.tmp`+`mv`, `chmod` antes do
`mv`). Tokens `ALREADY|HEALED|MISSING|FAILED` (exit 0/0/2/1). O cp substitui o binário **inteiro** →
cura qualquer drift; **estritamente superior** ao patch in-place (que deixa o binário híbrido).

### 2. `scripts/idea-update.sh` — comando único `idea update` (NOVO)
Reconcilia numa passada: pull → **overlay** (setup --global-only + install-global-patches, CRÍTICO,
gate) → **daemon** (redeploy canônico) → **hooks** (reusa `ideiaos-update.sh --hooks-only` — preserva
o consentimento T-01-10) → idea-doctor. **Build-contract: exit 1** se etapa crítica falhar. Abre com
`surgery_begin` (R15-22). 

### 3. Unificação da lógica (DRY) — 2 estratégias → 1
- `propagate-if-changed.sh` (step 2e equivalente) e `ideiaos-update.sh` step 2e → ambos usam
  `redeploy_autosync_daemon` (1 lógica de cp, não 2 cópias).
- Patchers in-place 2/2b/2c/2d → marcados **DEPRECATED** + `debt:` (remover quando a frota toda estiver
  pós-cp-canônico). Mantidos só como diagnóstico legado/fallback.

## Verificação (`tests/v15/test-idea-update.sh` — 13/13, exit 0)

O foco do requisito: **o sandbox /tmp limpo NÃO exercita a cura** → o teste deploya um daemon **LEGADO
driftado** (conteúdo antigo, sem guards, nem executável 0644) e prova:

| Caso | Resultado |
|------|-----------|
| pré-condição: deployado DIFERE da fonte (drift real, não sandbox limpo) | ✅ |
| **redeploy → HEALED; curado BYTE-A-BYTE == fonte; executável (corrige 0644→0755)** | ✅ |
| **equivalência:** o cp entrega os 4 guards que os in-place aplicariam (pause-file · conflict-marker · surgery R15-22 · exclude versions.lock) | ✅ |
| idempotência (2ª chamada = ALREADY) | ✅ |
| fonte ausente → MISSING; **destino intacto** (sem escrita parcial) | ✅ |
| sintaxe `idea-update.sh` + `redeploy-daemon.sh` | ✅ |

A equivalência prova que o cp-canônico **inclui** tudo que os patchers in-place produziriam — logo são
mesmo redundantes (autoriza a depreciação).

## Arquivos
- `source/lib/redeploy-daemon.sh` (novo) · `scripts/idea-update.sh` (novo, +x)
- `scripts/propagate-if-changed.sh` + `scripts/ideiaos-update.sh` (usam o helper; in-place deprecados)
- `tests/v15/test-idea-update.sh` (novo, 13 asserts) · `README.md` (tabela de scripts)
