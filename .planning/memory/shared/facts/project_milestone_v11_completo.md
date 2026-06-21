---
name: project-milestone-v11-completo
description: "v11 (Integridade & Auditoria de Spec) — 6 ondas DONE 2026-06-19; SHIPPED tag v11.0 2026-06-20 (SOAK 2 máquinas + span ≥1d fechados)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Milestone **v11 — Integridade & Auditoria de Spec** teve as **6 ondas DONE em 2026-06-19**,
fechamento **PARCIAL / no-tag** (precedente v10). Origem: análise multi-fonte
`docs/research/2026-06-19-arsenal-analysis/`. Disciplina: integridade ANTES de capacidade
(prioridade da revisão NASA).

- **W1** autosync guard-aware (pause-file + conflict-marker) — `44336c5`
- **W2** CI repo-self-consistency gates (`check-versions-lock`+`check-plugin-membership` HARD, `check-source-headers` ADVISORY) + 10 skills nativas com `# SOURCE` + design-suite ref `main`→sha — `ccb3ff0`
- **W3** SOAK gate `scripts/check-soak.sh` (+`docs/process/soak-gate.md`) + surface-budget no idea-doctor (Seção 11) + `/idea` routing eval cases EVAL-023/24/25 — `70f0cd6`
- **W4** `/spec --analyze`+`--converge` — libs `source/skills/spec/lib/spec-grammar.sh`+`spec-analyze.sh`+`spec-converge.sh` + `tests/spec-analyze.bats` (23 asserts) — `e65d0e0` **+ hardening** `4011186`
- **W5** deltas LOW R2/R4/R6/R8 (operating-discipline + idea-doctor Seção 12 debt: + ADR licença) — `4637b1d`
- **W6** ADRs (`v11-spec-kit-analyze-converge`, `v11-license-provenance-quarantine`) + SOAK heartbeat — `0ede0c0`; fix do ledger gitignored — `c60d97a`

**Metodologia (ultracode):** design por painel de 3 + juiz (`wf_449a5952`) ANTES de codar o W4;
verificação adversarial 5-lentes (`wf_99173505`, veredito FIX_NEEDED) DEPOIS — achou e fez corrigir
um bloqueador HIGH (A2 hard-falhava em spec que segue o template oficial) + 9 achados. Dogfood:
o próprio SOAK gate e o idea-doctor pegaram defeitos (incl. o ledger sob `*.log`). Ver
[[learning-broad-gitignore-sweeps-tracked-ledger]].

**✅ TAG `v11.0` SHIPPED 2026-06-20** (`1ba01c8`): SOAK fechado — 2 máquinas reais distintas (MacBook-Air-2 + Mac-mini) + span ≥1d via re-record em 06-20 18:21 (commit 056768e). Foi o **primeiro** dos 3 milestones PARCIAL a fechar; v12.0 e v13.0 seguiram em 2026-06-21 (ver [[project-milestone-v12-qa-security]], [[project-milestone-v13-security-freshness]]). Sucede [[project-milestone-v9-completo]] (v10 ficou parcial). Cuidado de integridade do SOAK em [[learning-automate-the-reminder-not-the-integrity-stamp]].
