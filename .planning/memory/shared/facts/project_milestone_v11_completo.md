---
name: project-milestone-v11-completo
description: "v11 (Integridade & Auditoria de Spec) — SHIPPED 2026-06-20, tag v11.0 (ec965b1→1ba01c8); 6 ondas DONE; SOAK fechado (2 máquinas reais + span ≥1d)"
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

**SOAK FECHADO + TAG (2026-06-20 18:21):** v11.0 **SHIPPED** — tag anotada `ec965b1` no commit
`1ba01c8` (work), pushed para origin. O ledger `.planning/soak/v11-arsenal.log` tinha 2 máquinas
reais (MacBook-Air-2 @ 06-19 17:51 · Mac-mini @ 06-19 18:30); a janela do span abriu em
2026-06-20 17:51:44 e um **re-record na MacBook-Air-2 @ 18:21:55** (idea_doctor+regressão PASS)
levou o span a ≥1d → `check-soak.sh v11-arsenal` exit 0 → `git tag` (mecanismo @devops via
`AIOX_ACTIVE_AGENT=devops` p/ o push, sob autorização do usuário).

**Lição confirmada:** o span ≥1d só fecha RE-GRAVANDO um heartbeat depois de 1 dia real numa
máquina REAL — esperar não basta, e gravar de cloud/CI fraudaria o ≥2-máquinas (ver
[[learning-soak-span-is-record-delta-not-wallclock]]). Convenção: tags de release são anotadas
(como v9.0). Sucede [[project-milestone-v9-completo]]; v12.0/v13.0 ainda na fila do SOAK
([[project-milestone-v12-qa-security]], [[project-milestone-v13-security-freshness]]).
