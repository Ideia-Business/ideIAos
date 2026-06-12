---
gsd_state_version: 1.0
milestone: v3
milestone_name: milestone
status: In Progress
last_updated: "2026-06-12T18:00:00Z"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 9
  completed_plans: 4
  percent: 60
---

# State — IdeiaOS v3

**Atualizado:** 2026-06-12
**Milestone:** v3 — Refinamento e Automação

## Snapshot

| Fase | Status |
|------|--------|
| Fase 09 — agent-contracts | ✅ Complete |
| Fase 10 — token-optimizations | ✅ Complete |
| Fase 11 — instinct-loop-automation | ⬜ Não iniciada |
| Fase 12 — evals-ci | ✅ Complete |
| Fase 13 — security-dx-manifest | ⬜ Não iniciada |

**Progresso:** 3/5 fases · 4/9 planos (estimado)

```
[########################                ] 60%
```

## Próximo Passo

`/gsd-plan-phase 11` — instinct-loop-automation (independente de Fases 10/12)

## Decisões Registradas

- Nome canônico `ideiaos-checker` (não `setup-checker`) — alinhado com filename (Fase 09)
- validate_agent_contracts() chamada antes do build, não como step separado (Fase 09)
- Docs históricos recebem nota "(corrigido na Fase 09)" sem reescrever história (Fase 09)
- opus → sonnet para silent-failure-hunter; processo grep-based validado em 3 casos; ~5x economia de tokens (Fase 10)
- Counter strategic-compact.sh muda para plain-text integer (sem JSON); jq proibido — grep/sed builtins para parse (Fase 10)
- typescript-lsp registrado como kind:lsp, source:null — config-only, não instala pacote npm; installStrategy:stack:typescript como padrão para módulos condicionais (Fase 10)
- Plugin copies (plugins/ideiaos-core/agents/) devem sempre ser sincronizadas com source/agents/ em cada edição de agent (Fase 10)
- Negation criterion grep usa texto completo do critério como padrão (não extração de keyword) — simpler e suficiente para os 22 casos atuais (Fase 12)
- llm-evals job usa steps.check_key output em vez de if-secret idiom — secrets em if: não são confiáveis em branches não-default (Fase 12)
- yaml module ausente no macOS Python3; validação YAML estrutural manual localmente; CI ubuntu-latest tem PyYAML disponível (Fase 12)

## Evidências Recentes

- `de91454` — feat(12-01): run_case_with_model() com execução LLM + política CI pass^k/pass@k
- `0ad8ca0` — feat(12-02): GitHub Actions workflow evals.yml + seção CI/CD no README

## Notas

- Milestone v2.0 arquivado em `.planning/milestones/v2.0-ROADMAP.md` (tag `v2.0`).
- Requisitos em `.planning/REQUIREMENTS.md` (19 requisitos, 15 gaps cobertos).
- Fases 09–13 mapeadas em `.planning/ROADMAP.md`.
- Fase 13 pode ser planejada e executada em paralelo com 11 e 12 (sem dependência).
- modules.json agora tem 71 entries (R3-17 Fase 13 deve verificar consistência com ideiaos-catalog/SKILL.md).
