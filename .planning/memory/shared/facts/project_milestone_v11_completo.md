---
name: project-milestone-v11-completo
description: "v11 (Integridade & Auditoria de Spec) — 6 ondas DONE 2026-06-19, fechamento PARCIAL/no-tag; SOAK 2/2 máquinas PASS, tag v11.0 só aguarda o span ≥1d (heartbeat ≥2026-06-20 17:51:44)"
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

**SOAK status (2026-06-19 18:30):** 2/2 máquinas PASS no ledger `.planning/soak/v11-arsenal.log`
(MacBook-Air-2 @ 17:51 commit 4011186 · Mac-mini-de-Gustavo @ 18:30 commit 2ca25df) — a checagem
de durabilidade cross-máquina (o risco real do SOAK) está GREEN. **Único critério restante: span ≥1d.**
Ambos heartbeats são de 06-19 (~39min) → `span 0d < 1d`. O 1º heartbeat ancora a janela em
2026-06-19 17:51:44; o gate vira verde com QUALQUER heartbeat ≥ **2026-06-20 17:51:44**.

**Para TAGUEAR v11.0** (amanhã ≥17:51, qualquer máquina):
`bash scripts/check-soak.sh v11-arsenal --record` → `git add .planning/soak/v11-arsenal.log && git commit && git push`
→ `bash scripts/check-soak.sh v11-arsenal` (exit 0) → `git tag v11.0`. Nada de código pendente.
Sucede [[project-milestone-v9-completo]] (v10 ficou parcial). origin/work=`049a947`.
