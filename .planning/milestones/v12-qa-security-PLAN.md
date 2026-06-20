# v12 — QA & AI-Security · PLAN + status

**Origem:** análise multi-agente `docs/research/2026-06-19-qa-security-arsenal/` (workflow `wf_50d8299b-f69`, 20 agentes).
**ADR:** `docs/decisions/v12-qa-security-absorption.md`.
**Disciplina:** integridade-antes-de-capacidade · conceito-only · `# SOURCE` obrigatório · native-before-dependency.
**Status:** **6 entregas DONE 2026-06-19** (W1–W4 + refresh + ADR/plan), fechamento **PARCIAL/no-tag** (pendente SOAK).

## Requisitos

| ID | Requisito | Itens | Status |
|----|-----------|-------|--------|
| R12-01 | Absorção conceito-only com `# SOURCE` correto; copyleft (OWASP CC BY-SA 4.0; Hercules AGPL-3.0) → zero prosa/código | SEC-01, SEC-04, QA-01, QA-02 | ✅ |
| R12-02 | Doutrina preventiva `credential-isolation` em `source/rules/common/`, propagável | SEC-05 | ✅ |
| R12-03 | `security-reviewer` ganha rubrica LLM Top 10 condicional + prompt-injection-runtime | SEC-01, SEC-02 | ✅ |
| R12-04 | `mcp-hygiene` generaliza critérios MCP nomeados + "Excessive Agency" | SEC-03, SEC-04 | ✅ |
| R12-05 | Cláusula de fronteira artefato-vs-runtime em `antifragile-gates` + ajuste `operating-discipline` #6 | QA-02 | ✅ |
| R12-06 | Índice de cobertura de QA + registro dos 3 gaps | QA-01 | ✅ |
| R12-07 | Nota de governança de IA (cross-map NIST/ISO/CSA/SAIF) | GOV-01 | ✅ |
| R12-08 | 2-4 EVAL adversariais sintéticos no harness existente, ADVISORY até soak | EVAL-01 | ✅ (EVAL-026/27/28) |
| R12-09 | Refresh mensal nativo do muellerberndt (script + snapshot + plist + check idea-doctor) | (pedido explícito) | ✅ |

## Ondas (ordem integridade-antes-de-capacidade)

- **W1 — Integridade & fronteira** (R12-05, R12-02): `antifragile-gates.md` (2 regimes) · `operating-discipline.md` #6 · nova `credential-isolation.md` (+ entry no `manifests/modules.json`). ✅
- **W2 — Vocabulário AI-Security** (R12-03, R12-04): `security-reviewer.md` (OWASP LLM Top 10 + prompt-injection) · `mcp-hygiene.md` (critérios MCP + Excessive Agency). ✅
- **W3 — Referência & QA index** (R12-06, R12-07): `docs/process/qa-coverage-index.md` · `docs/reference/ai-governance-crossmap.md`. ✅
- **W4 — Validação empírica** (R12-01, R12-08): `evals/cases/EVAL-026/027/028` (anti-injection adversarial), ADVISORY. ✅
- **Refresh** (R12-09): `scripts/refresh-ai-security.sh` + snapshot bootstrapped em `security/intel/` (**local/gitignored** — fonte muellerberndt all-rights-reserved, não redistribuível) + `infra/launchd/com.ideiaos.refresh-ai-security.plist` + idea-doctor §13. ✅

## Definition of Done

1. Provenance gate: todo artefato novo/editado com `# SOURCE` + licença real (Hercules AGPL-3.0; OWASP CC BY-SA 4.0). ✅
2. Native-first: zero dep/ferramenta/MCP novo; tudo é extensão de agent/rule/doc/harness existente. ✅
3. Sem duplicação: rejeitados (plano-auditável, red-team-datasets, model-pinning, Agentic-Top-10-separado) fora. ✅
4. Lean: `credential-isolation` propaga via `setup --project-only`; nenhuma rule estoura orçamento. ✅
5. Propagação: `build-adapters.sh` + `build-plugins.sh` rodados; mirrors `.claude`/`.cursor`/`plugins` em dia. ⏳ (close)
6. Evals verdes (novos casos ADVISORY até soak). ⏳ (close)
7. Fechamento: STATE/handoff/README atualizados; learning extraído; SOAK heartbeat v12 gravado. ⏳ (close)

## Pendente para TAG `v12.0`
SOAK ≥2 máquinas + ≥1d sobre o ledger `.planning/soak/v12-qa-security.log` (gate do v11). Ativar o
LaunchAgent mensal na máquina always-on (Mac mini) é per-máquina (ver `MONTHLY-REFRESH-SPEC.md`).
