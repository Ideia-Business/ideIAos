---
gsd_state_version: 1.0
milestone: v13
milestone_name: Security Freshness Gate
status: partial
last_updated: "2026-06-20"
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# State — IdeiaOS

**Atualizado:** 2026-06-20

## Snapshot

| Item | Status |
|------|--------|
| v2.0/v3/v4 (plano maior ECC) | ✅ SHIPPED |
| v5 (memória cross-IDE) | ✅ SHIPPED |
| v6 (Resiliência + Marketing + GSD/OpenSpec) | ✅ SHIPPED 2026-06-16 — tag v6.0 |
| v7 (Delta-Spec Brownfield + Robustez) | ✅ SHIPPED 2026-06-16 — tag v7.0 |
| v8 (Camada de Disciplina) | ✅ SHIPPED 2026-06-16 — tag v8.0 |
| v9 (Camada de Alinhamento) | ✅ SHIPPED 2026-06-17 — tag v9.0 |
| **v10 (Integração Lovable MCP, read-only)** | 🟡 PARCIAL/no-tag (2026-06-18/19) — Fase A read-only SHIPPED+validada e2e (`IN_SYNC`); Fase B veredito 🔴 BLOQUEAR publish-via-MCP; Fases C/D PARQUEADAS-GATED. Ver `.planning/v10-MILESTONE-AUDIT.md`. |
| **v11 (Integridade & Auditoria de Spec)** | ✅ **SHIPPED 2026-06-20 — tag v11.0** (`ec965b1`→`1ba01c8`): 6 ondas (autosync guard-aware, CI self-consistency, SOAK gate, `/spec --analyze`/`--converge`). SOAK fechado (2 máquinas reais + span ≥1d). |
| **v12 (QA & AI-Security)** | 🟡 PARCIAL/no-tag 2026-06-19 (`8d18650`) — absorção conceito-only de 3 repos; `credential-isolation`, OWASP LLM no `security-reviewer`, refresh mensal AI-security. **Tag v12.0 na fila SOAK** (2 máquinas ✓; span fecha 2026-06-20 22:36). |
| **v13 (Security Freshness Gate)** | 🟡 PARCIAL/no-tag 2026-06-20 — núcleo W1-W4 (`check-security-freshness.sh` + idea-doctor §14 + rule) + surfacing opção C (hook post-commit advisory, zero footprint versionado) + propagação 4 produtos. **Tag v13.0 na fila SOAK** (2 máquinas ✓; span fecha 2026-06-21 17:46). |

## Milestone atual — fila SOAK (código entregue; fechando tags)

Os milestones de código v11–v13 estão entregues. A fila operacional é só o **SOAK** (gate de durabilidade cross-máquina, ≥2 máquinas distintas + span ≥1d) para tagar v12.0 e v13.0:

- **v11.0** — ✅ TAGUEADO 2026-06-20 (SOAK fechado: 2 máquinas reais + span ≥1d via re-record 18:21 na MacBook-Air-2).
- **v12.0** — 2 máquinas ✓ (heartbeats 2026-06-19 + Mac mini 2026-06-20 18:51); span fecha 2026-06-20 22:36:36. **Tag agendada** p/ hoje 22:45 (task local `close-soak-v12-tag-tonight`).
- **v13.0** — 2 máquinas ✓ (MacBook-Air-2 + Mac mini, 2026-06-20); span fecha 2026-06-21 17:46:26. **Tag agendada** p/ amanhã 17:50 (task local `close-soak-v13-tag-tomorrow`).

**v13 — Security Freshness Gate (resumo):** segurança verificada periodicamente e **por sistema** (padrão SOAK aplicado a dívida de segurança): gatilho determinístico risk-weighted (superfície × idade) → `@security-reviewer` → re-selo. Nunca gateia PR de feature. W1-W4 DONE (`8779d88` + surfacing opção C `a6ab59d`). Ligar `SECFRESH_GATE_ENABLED=1` é decisão pós-1º-ciclo (R13-07 estreia advisory). Planos por milestone: `.planning/milestones/v{10..13}-*`.

## Decisões Tecnicas Canonicas

### GSD — Linhagem Definitiva
- Usamos `@opengsd/get-shit-done-redux@1.1.0` (linha VIVA/estável, org open-gsd).
- redux 1.x ≠ gsd-pi 3.x (produto diferente, NÃO migrar). open-gsd ≠ gsd-build (legado).
- versions.lock blindado (fase 28); guards anti-Pi-drift em check-versions-lock.sh + idea-doctor.sh.

## Próximo passo

Fila SOAK no **piloto automático**: 2 tasks locais agendadas fecham v12.0 (hoje 22:45) e v13.0 (amanhã 17:50) — cada uma re-grava heartbeat, verifica span ≥1d e cria a tag, abortando sem taguear se algum gate falhar. Após ambas, a fila SOAK zera (v11/v12/v13 tagueados). Detalhe operacional vivo: `STATE.md` (raiz) + `docs/CONTINUATION_HANDOFF.md`.

## Pendências (opt-in, decisão do usuário)
- **v10 write-path (C/D) PARQUEADO-GATED:** reabre só com apetite por write-path + medição de A2 fora do MCP. ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md`.
- **SECFRESH_GATE_ENABLED=1 (v13):** ligar só após observar o 1º ciclo real do gate de frescor.
- **gsd-browser:** reavaliar quando publicar npm/crates (ADR `docs/decisions/`).
- **DeepSeek V4 Pro:** habilitar nos PRODUTOS (cfoai/nfideia etc.), fora do escopo IdeiaOS.
- **Suíte de Design:** pin re-ancorado à proveniência real `b7e3af80` (verificado por content-match 2026-06-20: 5/7 skills idênticas + overlays IdeiaOS em design-system/banner-design). ⚠️ NÃO rodar `update-design-suite.sh` (clone-por-sha cai no HEAD e apaga o dataset).
