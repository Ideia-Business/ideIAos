# SOURCE: IdeiaOS v2

# Evals — Roster de Casos

Todos os casos da suíte de regressão IdeiaOS, mapeados ao incidente real de origem.

## Legenda de Métricas

| Métrica | Significado | Quando usar |
|---|---|---|
| pass@k | Aprovado se ocorrer em ≥1 de k tentativas | Capacidades de produtividade |
| pass^k | Aprovado apenas se ocorrer em TODAS as k tentativas | Invariantes de segurança e dados financeiros |

## Roster

| ID | Título | Source (incidente) | Modo | Métrica | Severidade |
|---|---|---|---|---|---|
| EVAL-001 | Billing: nunca INSERT cego em client_subscriptions | ideiapartner/docs/INC-372-PLANO-VINCULACAO.md | review | pass^k | 🔴 |
| EVAL-002 | Webhook Asaas sem externalReference: fallback 3-estratégias | ideiapartner/docs/ASAAS_WEBHOOK_FALLBACK.md | dev | pass@k | 🔴 |
| EVAL-003 | RLS: REVOKE SELECT quebra INSERT … RETURNING * | nfideia/docs/learnings/2026-06-05-revoke-select-quebra-insert-returning-star.md | review | pass^k | 🔴 |
| EVAL-004 | React Query: cache vaza entre tenants no signed-out | nfideia/docs/learnings/2026-05-29-react-query-cache-vazamento-multi-tenant-signed-out.md | review | pass^k | 🔴 |
| EVAL-005 | Data sem timezone vira mês anterior em BRT | nfideia/docs/learnings/2026-05-29-data-sem-timezone-vira-mes-anterior-em-brt.md | dev | pass^k | 🔴 |
| EVAL-006 | Deno Edge: import ausente causa falha silenciosa | nfideia/docs/learnings/2026-05-30-deno-edge-import-ausente-falha-silenciosa.md | review | pass^k | 🔴 |
| EVAL-007 | Webhook: handler tolera snake_case, camelCase e múltiplos tipos | nfideia/docs/learnings/2026-05-29-webhook-naming-mismatch-snake-vs-camel-e-multiplos-tipos-de-payload.md | dev | pass@k | 🟡 |
| EVAL-008 | CNPJ alfanumérico: validação e normalização corretas | nfideia/docs/learnings/2026-05-31-cnpj-alfanumerico-algoritmo-e-normalizacao.md | dev | pass^k | 🔴 |
| EVAL-009 | Callback service-to-service não deve assumir JWT de usuário | nfideia/docs/learnings/2026-05-30-callback-service-to-service-nao-usa-jwt.md | review | pass^k | 🔴 |
| EVAL-010 | Validator throw engolido por handler de infra + jsonb stale em retry | nfideia/docs/learnings/2026-05-29-validator-throw-capturado-por-handler-infra-e-jsonb-stale-em-retry.md | review | pass^k | 🔴 |
| EVAL-011 | CRM: card duplica após outcome de reunião — fix idempotente | ideiapartner/docs/bugs/CRM_CARD_DUPLICATION_AFTER_MEETING_OUTCOME.md | dev | pass@k | 🟡 |
| EVAL-012 | Reunião fantasma: investigar causa raiz antes de patch | ideiapartner/docs/bugs/PHANTOM_MEETING_GHOST_EVENTS.md | review | pass@k | 🟡 |
| EVAL-013 | Cancelamento de reunião não aparece na UI | ideiapartner/docs/bugs/MEETING_CANCEL_NOT_VISIBLE.md | dev | pass@k | 🟡 |
| EVAL-014 | Proposta: hidratação de lead falhando (v7.73) | ideiapartner/docs/bugs/PROPOSAL_LEAD_HYDRATION_FIX_v7.73.md | dev | pass@k | 🟡 |
| EVAL-015 | Mesma métrica deve bater entre telas diferentes | ideiapartner/docs/CROSS_SCREEN_METRIC_CONSISTENCY.md | review | pass^k | 🔴 |
| EVAL-016 | Cache cross-module: invalidar ao mutar dado compartilhado | ideiapartner/docs/CROSS_MODULE_CACHE_INVALIDATION.md | review | pass^k | 🔴 |
| EVAL-017 | Deploy Lovable: 400 em função adjacente por import quebrado | nfideia/docs/learnings/2026-05-29-deploy-400-em-funcao-adjacente-import-quebrado-por-lovable-ai.md | dev | pass@k | 🟡 |
| EVAL-018 | Onboarding: categorias de entrega não aparecem (INC-368) | ideiapartner/docs/INC-368-ONBOARDING-DELIVERY-CATEGORIES.md | dev | pass@k | 🟡 |
| EVAL-019 | scan-absorbed.sh: HTML comment em source/ é falso positivo bloqueante | IdeiaOS/.planning/STATE.md (decisão 03-04) | review | pass@k | 🟡 |
| EVAL-020 | scan-absorbed.sh: substrings 'nc '/'jq ' em código são falso positivo | IdeiaOS/.planning/STATE.md (decisões 03-04, 05-01) | review | pass@k | ⚪ |
| EVAL-021 | Modo review: não editar arquivos ao receber pedido de correção | IdeiaOS/source/contexts/review.md (Fase 07) | review | pass^k | 🔴 |
| EVAL-022 | Modo research: mapear terreno e entregar plano, sem escrever código | IdeiaOS/source/contexts/research.md (Fase 07) | research | pass@k | 🟡 |

**Total: 22 casos** (14 pass^k invariantes · 8 pass@k produtividade)
