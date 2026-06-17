# G-01-SUMMARY — Fase G (opcional): could-haves / deltas finos

**Milestone:** v9 · **Fase:** G (could-haves, pós-v9.0) · **Status:** ✅ DONE · **Data:** 2026-06-17
**Origem:** `v9-IMPLEMENTATION-PLAN.md §G` — dois deltas finos estimados XS, fora do caminho de ship do v9.0.

## Entregue

Ambos absorvidos de `mattpocock/skills` (MIT) via o mecanismo de **overlay idempotente** (`install-global-patches.sh`), porque o `.aiox-core` vendado no repo é mantido **pristine** (IdeiaOS aplica deltas só na cópia instalada — mesmo padrão dos Patches 1 e 5) e o `/gsd-debug` é um skill **global** (não vive no repo).

- **PATCH 14 — delta `to-prd` no @pm/Morgan** (`.aiox-core/.../agents/pm.md`): novo `core_principle` "**Síntese sobre entrevista**" — quando já há contexto (uma conversa, um `/grelha`, um entendimento prévio), sintetizar o PRD do que já se sabe em vez de re-entrevistar do zero; antes de fechar, rodar um quiz curto de seams/módulos (lente `/aprofundar`) e registrar módulos profundos + costuras testáveis como restrições de design no PRD.
- **PATCH 15 — nota de seam no `/gsd-debug`** (`~/.claude/skills/gsd-debug/SKILL.md`): bloco `<ideiaos_seam_note>` após `</objective>` — do `diagnose`: se não há *seam* de teste correto para isolar o bug, isso **é O achado** (sinaliza problema de arquitetura) → handoff p/ `/aprofundar`/@architect em vez de forçar um fix que contorna a falta de costura. NÃO substitui o `/gsd-debug`; complementa.

Não foi necessário fatiar versão: ambos são deltas em cima do v9.0 (sem mudança de comportamento contratado). `caveman`/`to-issues`/`triage` permanecem **WON'T** (conflito com clareza+PT-BR / acoplam a issue tracker externo).

## Empacotamento / propagação

- `install-global-patches.sh`: +2 funções (`patch_pm_to_prd`, `patch_gsd_debug_note`), header e 15 step-labels atualizados (`/13`→`/15`). Idempotente (marker-detection + re-grep).
- Contagem "**15 patches**" sincronizada em `README.md` (texto + tabela de patches, +2 linhas) e `idea-doctor.sh` (label + 2 `chk` que verificam os marcadores 14/15 na cópia instalada).

## Gates binários (exit code)

| Gate | Resultado |
|------|-----------|
| `bash -n install-global-patches.sh` | ✅ sintaxe OK |
| `install-global-patches.sh` (run) | ✅ exit 0 — 2 aplicados / 17 pulados / **0 falhas** |
| grep marcador Patch 14 em pm.md instalado | ✅ count 1 (core_principle válido, scalar single-quoted balanceado) |
| grep marcador Patch 15 em gsd-debug instalado | ✅ count 1 (após `</objective>`) |
| `idea-doctor.sh` | ✅ Patch 14 ✓ / Patch 15 ✓ — 63 OK / 1 WARN / **0 FAIL** |
| `check-readme-sync.sh` | ✅ exit 0 — 114/114 mencionados |

## Nota de escopo

O plano estimou XS ("1 parágrafo"). Na prática virou **MEDIUM**: o lar fiel à convenção (overlay sobre `.aiox-core` pristine + skill global) carrega a manutenção da contagem "13→15 patches" em 3 arquivos. Decisão consciente — overlay é o padrão estabelecido (Patches 1/5), não edição direta (violaria o pristine) nem rule (não alcança a persona do agente AIOX / o skill GSD).
