# A-08 — Resolver FAIL crônico do cfoai / verde-falso do §7e (R15-06) · SUMMARY

**Status:** ✅ DONE (IdeiaOS) + ⏳ commit dos produtos PENDENTE · **Wave:** 2 · **Executor:** sessão principal
**Decisão do dono (2026-06-25):** **Exigir server ativo + remediar os 4 produtos.**

## O problema (provado por exit-code — A-08-PROBE.txt)

O §7e do `idea-doctor` contava só o connector Lovable **morto** `6f530143`. PROBE inicial:
nos 4 produtos `DENY_OLD=19, DENY_NEW=0, VERDE_FALSO=sim`. O gate dava ✅ "contido" enquanto o
server **ATIVO** (`claude.ai Lovable - gustavolpaiva` → `mcp__claude_ai_Lovable_-_gustavolpaiva__*`)
tinha **zero** tools mutantes denegadas.

## Contradição do plano resolvida com o dono

A *action* da Task 3 mandava contar `any(velho, novo)` — mas isso **não mata** o verde-falso (um
produto com deny só no connector morto seguiria ✅). Os *truths*/*success_criteria* exigiam o oposto.
**Provei ao vivo** que `any` mantinha os 4 ✅ pelo prefixo morto. Levei a contradição ao dono
(AskUserQuestion); decisão = **exigir o prefixo do server ATIVO** (falha-fechada) **+ remediar os 4**.

## O que foi feito

1. **`scripts/idea-doctor.sh` §7e — exige o server ATIVO** (`claude_ai_Lovable`); o connector morto
   `6f530143` NÃO conta mais. Lista aceita múltiplos prefixos (`split "|"`) p/ futuros servers ativos.
   Lógica provada por fixtures (Task 2): fixture-new (deny no ativo) → OK; fixture-empty → BAD.
   Threshold 19 + `fail` preservados; marcador `# debt:` p/ derivar o prefixo via `claude mcp list`.
2. **Remediação dos 4 produtos** — gravado deny das **19 tools mutantes no prefixo ATIVO** em
   `cfoai-grupori`, `ideiapartner`, `nfideia`, `lapidai` (`.claude/settings.json`), **mantendo o deny
   velho** (defense-in-depth) e adicionando o server ativo a `disabledMcpServers`. Nomes das 19 tools
   vieram da rule `source/rules/lovable/mcp-protocol.md` (No-Invention).
3. **Prova final (Task 6):** `idea-doctor` real → os 4 = "contido (deny=19)" **honesto**; zero
   "SEM contenção". PROBE regravado: `DENY_NEW=19` nos 4, `VERDE_FALSO=nao`.

## Verificação (exit-code)

| Etapa | Resultado |
|-------|-----------|
| PROBE inicial: divergência de prefixo + DENY_NEW=0 + VERDE_FALSO=sim | ✅ |
| §7e exige-ativo: fixture-new=OK, fixture-empty=BAD, sintaxe/threshold/fail/debt | ✅ |
| 4 produtos: deny novo formato-exato ≥19 + velho mantido + JSON válido + nada mutante em `allow` | ✅ |
| `idea-doctor` real: 4 contidos honestos, zero FAIL; PROBE `VERDE_FALSO=nao` | ✅ |

## ⏳ PENDENTE — commit/persistência nos produtos (NÃO feito por este plano)

O plano A-08 **não commita nem empurra** (invariante 6 — @devops exclusivo p/ push). Os 4
`settings.json` estão **gravados mas não-commitados**:
- **cfoai-grupori, nfideia** (`.claude/settings.json` TRACKED, branch **main** Lovable): precisa commit
  em **branch `work`** (NUNCA main automática) + push por @devops. cfoai é **PARTICULAR**.
- **ideiapartner** (`.claude/settings.json` **GITIGNORED**): já é local-only por design — persiste por
  reclone manual; não precisa commit.
- **lapidai** (branch **work**): commit em `work`. Protegido por pause-file **por-repo**
  (`~/dev/lapidai/.git/autosync-pause`) até o commit controlado, p/ o autosync não atropelar.

## Arquivos

- IdeiaOS (commitado): `scripts/idea-doctor.sh`, `.planning/.../A-08-PROBE.txt`, este SUMMARY.
- Produtos (gravados, não-commitados): `.claude/settings.json` × 4.
