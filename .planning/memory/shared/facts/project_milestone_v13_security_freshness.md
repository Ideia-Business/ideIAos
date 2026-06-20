---
name: project-milestone-v13-security-freshness
description: v13 Security Freshness Gate — núcleo + surfacing opção C + propagação 4 produtos (PARCIAL/no-tag 2026-06-20)
metadata: 
  node_type: memory
  type: project
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

**v13 — Security Freshness Gate ("Selo de Frescor de Segurança")** — fechamento PARCIAL/no-tag 2026-06-20. Padrão SOAK aplicado a dívida de segurança: rigor = (risco da superfície tocada) × (idade da última revisão). Gatilho **determinístico** (git diff + path-globs risk-weighted + idade → tier) → revisão `@security-reviewer` → re-selo determinístico. **Nunca gateia PR de feature**; só o `git tag` do IdeiaOS no tier egrégio (advisory no 1º ciclo).

**Entregue:**
- Núcleo W1-W4 (`8779d88`): `scripts/check-security-freshness.sh` (`--tier|--status|--bootstrap|--record|--gate`) + ledger `.security/review-ledger.log` (commitado no IdeiaOS; exceção `!.security/review-ledger.log` no `.gitignore`) + idea-doctor **§14** (ADVISORY, **nunca FAIL** — FAIL travaria o SOAK) + rule `source/rules/common/security-freshness.md` + sandbox 10/10.
- Surfacing por produto = **decisão do usuário: opção C** (`a6ab59d`): hook **`post-commit` advisory** por produto (post-commit não bloqueia por construção). `SECFRESH_ROOT` override → **1 engine no IdeiaOS audita qualquer repo** → produto NÃO versiona script (zero trigger Lovable em `main`). `setup_security_freshness_layer()` no `setup.sh --project-only` (bootstrap ledger local + install husky-aware via `core.hooksPath` + `.git/info/exclude`). Template `source/templates/security/post-commit-security-freshness.sh`. Throttle 6h. Sandbox 14/14.
- Propagação 4 produtos (local-only, surgical — NÃO rodou `setup --project-only` completo p/ evitar churn de rule-mirror em main): nfideia `.husky/post-commit` (excluído), ideiapartner/lapidai/cfoai `.git/hooks/post-commit`. 4/4 verificados binariamente, **0 tracked churn**. Rule auto-propaga via post-merge (lapidai já recebeu).

**Config (R13-03):** pesos/globs/limiares em **defaults do script + env `SECFRESH_*` + `.security/policy.sh`** — NÃO em `core-config.yaml` (que só existe no `.aiox-core` PRISTINE, ver [[project-aiox-core-pristine-overlay]]).

**Pendente p/ tag `v13.0`:** SOAK ≥2 máquinas + span ≥1d sobre `.planning/soak/v13-security-freshness.log` (1 máquina/0d). Ligar `SECFRESH_GATE_ENABLED=1` é decisão pós-1º-ciclo (R13-07). Mesma situação de [[project-milestone-v11-completo]] e [[project-milestone-v12-qa-security]]. Padrão técnico em [[learning-local-tooling-via-env-root-and-git-exclude]].
