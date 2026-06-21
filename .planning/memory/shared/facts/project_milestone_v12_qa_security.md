---
name: project-milestone-v12-qa-security
description: "v12 (QA & AI-Security) — 4 ondas + refresh mensal DONE 2026-06-19 (commit 8d18650), conceito-only de 3 repos externos; SHIPPED tag v12.0 2026-06-21"
metadata:
  node_type: memory
  type: project
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Milestone **v12 — QA & AI-Security** implementado e commitado em 2026-06-19 (`8d18650`,
branch `work`), fechamento **PARCIAL/no-tag** (precedente v10/v11). Origem: pedido do usuário
para absorver melhorias de QA/segurança de 3 repos externos via tropa multi-agente.

**Análise:** workflow `wf_50d8299b-f69` (20 agentes, 4 fases: recon → delta → verify adversarial
→ synthesize). Artefatos em `docs/research/2026-06-19-qa-security-arsenal/` (ANALYSIS, PROPOSAL,
SECURITY-KNOWLEDGE, MONTHLY-REFRESH-SPEC). Licenças via GitHub API: **Hercules AGPL-3.0**,
**TalEliyahu MIT**, **muellerberndt SEM LICENÇA**. Veredito: quase nada absorvível como código —
valor em taxonomias públicas (OWASP LLM Top 10, MITRE ATLAS) + disciplina. 9 absorções confirmadas,
4 rejeitadas (anti-over-absorption).

- **W1** `antifragile-gates` (2 regimes: artefato-exit-code vs runtime-NL) + `operating-discipline` #6 + nova rule `credential-isolation` (SEC-05, + entry no `modules.json`)
- **W2** `security-reviewer` (OWASP LLM Top 10 condicional + prompt-injection-runtime) + `mcp-hygiene` (critérios MCP SlowMist/TTPs + "Excessive Agency")
- **W3** `docs/process/qa-coverage-index.md` (índice + 3 gaps: API-contract/visual-regression/mobile-emulation) + `docs/reference/ai-governance-crossmap.md`
- **W4** `evals/cases/EVAL-026/027/028` (anti-injection adversarial: unicode-invisível/data:URI/BOM, ADVISORY)
- **Refresh mensal** `scripts/refresh-ai-security.sh` (curl+diff+sha, nunca executa) + snapshot **LOCAL/gitignored** (muellerberndt sem licença → [[learning-gitignore-third-party-verbatim-snapshot]]) + `infra/launchd/com.ideiaos.refresh-ai-security.plist` + idea-doctor §13

ADR `docs/decisions/v12-qa-security-absorption.md`; plano `.planning/milestones/v12-qa-security-PLAN.md`.
Tudo conceito-only com `# SOURCE`. Verificado: idea-doctor **73/1/0**, readme 120/120, evals 3 casos.
Propagado a `.claude`/`.cursor`/`plugins`. Dogfood pegou alucinação de licença (Hercules Apache→AGPL).

**✅ TAG `v12.0` SHIPPED 2026-06-21** (`57daf9c`): SOAK fechado — 2 máquinas reais + span ≥1d via re-record manual na Mac mini. A task agendada `close-soak-v12-tag-tonight` **disparou 06-20 22:45 mas ABORTOU antes de taggear** (ledger sem re-record → bailou num gate inicial); executei os passos manualmente com confirmação do usuário e a task one-shot já está `enabled:false`. Refresh mensal AI-security já ATIVADO na Mac mini (launchd, 2026-06-20). Sucede [[project-milestone-v11-completo]]; cuidado de integridade do SOAK em [[learning-automate-the-reminder-not-the-integrity-stamp]].
