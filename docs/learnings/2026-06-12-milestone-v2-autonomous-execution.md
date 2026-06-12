# SOURCE: IdeiaOS v2
# Learning — Execução autônoma de milestone completo (8 fases) com subagentes especialistas

**Data:** 2026-06-12 · **Contexto:** Milestone v2.0 (absorção ECC), fases 04-08 executadas em uma única sessão autônoma.

## Padrão

Pipeline GSD por fase: planner (opus) → plan-checker (sonnet) → executors em waves (sonnet, paralelos quando files disjuntos) → verifier (sonnet) → phase complete. Orquestrador permanece leve (~15% contexto); subagentes recebem prompts paths-only.

## Evidência

- 5 fases (04-08), 17 planos, ~20 subagentes, 0 retrabalho estrutural.
- Checker pagou o custo: 4 blockers reais na Fase 06 (script quebrando em runtime pós-remoção, hook pre-commit vivo desatualizado) e 2 na Fase 07 (numeração de steps colidindo, risco de fabricação de eval cases) — todos teriam virado bugs em execução.
- Wave 1 paralela com 3 executors no MESMO working tree funcionou com etiqueta: stage só os próprios arquivos, retry em index.lock, tolerar commits `wip: autosync`.
- Fase destrutiva (remoção de dirs): 1 executor único para os 3 planos acoplados por commit conjunto + pausa do autosync na janela destrutiva.

## Regra prática

1. Waves paralelas SÓ com files_modified disjuntos; edits de arquivos compartilhados concentrados em UM plano de Wave 2.
2. Plano destrutivo = executor único + autosync pausado + verificação superset ANTES do rm + commit conjunto com o README.
3. Fixes de checker pontuais: aplicar direto nos PLAN.md (mais barato que re-spawnar planner).
4. Checkpoint human-verify com pré-autorização: executar o teste comportamental de verdade (ex.: claude headless com --append-system-prompt) e registrar evidência — não apenas "auto-aprovar".

## Falsos positivos

- "Paralelizar sempre é melhor" — não: a Fase 06 ficou mais segura sequencial em 1 executor.
- "Auditoria de planos é overhead" — os 6 blockers reais provam o contrário em fases destrutivas/integrativas.
