# ADR — v12: Absorção QA & AI-Security (testzeus-hercules + awesome-ai-security ×2)

**Status:** Aceito · implementado 2026-06-19 · fechamento **PARCIAL/no-tag** (pendente SOAK, precedente v10/v11)
**Contexto-fonte:** `docs/research/2026-06-19-qa-security-arsenal/` (ANALYSIS · PROPOSAL · SECURITY-KNOWLEDGE · MONTHLY-REFRESH-SPEC)
**Sucede:** [v11 — Integridade & Auditoria de Spec]; reusa a disciplina de quarentena/proveniência do ADR `v11-license-provenance-quarantine.md`.

## Contexto

Pedido do usuário: analisar 3 repos externos de QA/segurança e absorver melhorias no IdeiaOS,
com tropa multi-agente (workflow `wf_50d8299b-f69`, 20 agentes, 4 fases). Disciplina:
integridade-antes-de-capacidade (NASA, herdada do v11).

## Mapa de licenças (verificado autoritativamente via GitHub API)

| Repo | Licença real | Absorção |
|---|---|---|
| `test-zeus-ai/testzeus-hercules` | **AGPL-3.0** (copyleft forte) | conceito-only, **zero código/prosa** |
| `TalEliyahu/Awesome-AI-Security` | **MIT** | fatos/links com citação |
| `muellerberndt/awesome-ai-security` | **SEM LICENÇA** (all-rights-reserved) | só fatos públicos via fonte primária; **zero prosa** |

> **Lição de proveniência (dogfood):** um agente do workflow alucinou "Hercules = Apache-2.0".
> A API confirmou **AGPL-3.0** — diferença que separa "código reutilizável" de "proibido importar".
> Corrigido nos docs contra a fonte autoritativa. Reforça: licença declarada por LLM não é fonte —
> verificar sempre no primário (`gh api repos/<o>/<r> --jq .license.spdx_id`). Ver
> [[learning-soak-span-is-record-delta-not-wallclock]] como precedente de "verificar, não supor".

## Decisão

**Absorver SÓ o delta conceito-only, aditivo, sem nenhuma dependência/ferramenta/MCP novo.** O valor
está em **taxonomias públicas estáveis** (OWASP LLM Top 10, MITRE ATLAS, governança) e **conceitos de
disciplina**, não em código. 9 absorções confirmadas (4 ondas), 4 rejeitadas.

### Absorvido (conceito-only, ADVISORY até soak)
- **W1 (integridade/fronteira):** cláusula artefato-exit-code vs runtime-NL em `antifragile-gates` +
  ajuste em `operating-discipline` #6 (QA-02); nova rule `credential-isolation` — doutrina preventiva,
  segredo nunca no contexto do LLM (SEC-05).
- **W2 (vocabulário AI-Sec):** rubrica OWASP LLM Top 10 condicional + prompt-injection-runtime no
  `security-reviewer` (SEC-01/02); critérios MCP nomeados (SlowMist/TTPs) + "Excessive Agency" em
  `mcp-hygiene` (SEC-03/04).
- **W3 (referência):** `docs/process/qa-coverage-index.md` (índice + 3 gaps: API-contract,
  visual-regression, mobile-emulation) (QA-01); `docs/reference/ai-governance-crossmap.md`
  (NIST/ISO-42001/CSA/SAIF) (GOV-01).
- **W4 (validação):** EVAL-026/027/028 adversariais (unicode-invisível, data:URI base64, BOM/handoff)
  no harness `evals/` existente, ADVISORY (EVAL-01).
- **Refresh mensal:** `scripts/refresh-ai-security.sh` (curl+diff+sha, nunca executa conteúdo) +
  snapshot **local-per-máquina** em `security/intel/` (**gitignored** — muellerberndt é
  all-rights-reserved/sem-licença, não redistribuímos a prosa; cada máquina mantém seu baseline)
  + plist launchd + check ADVISORY no idea-doctor §13.

### Rejeitado (anti-over-absorption)
- Plano-do-agente auditável → duplica GSD (`PLAN.md`)/`gsd-forensics`/`cost-tracking`.
- Red-team via datasets externos → premissa falsa (`evals/` já existe); mis-mira guards regex; +superfície.
- Model/dataset provenance pinning → product-layer (cfoai/nfideia), não OS (prevention-in-OS-vs-remediation).
- OWASP Agentic Top 10 como rubrica separada → não paga complexidade hoje; cross-ref no SEC-01.

## Consequências

- **+** Vocabulário de AI-security nomeado e auditável que não existia em lugar nenhum do OS; doutrina
  preventiva de credential-isolation fecha o vão deixado pelo ferramental hoje só reativo.
- **+** Intel de AI-security não apodrece: refresh mensal nativo, CLI-first, anti-injection.
- **−** Mais 1 rule sempre-on (`credential-isolation`) — pago: doutrina-piso, lean (~50 linhas).
- **Provenance gate:** todo artefato leva `# SOURCE` com a licença real; OWASP citado como CC BY-SA 4.0
  conceito-only; Hercules AGPL-3.0 conceito-only (zero código/prosa).
- **SOAK:** v12 fecha PARCIAL/no-tag; tag `v12.0` só após soak ≥2 máquinas + ≥1d (gate do v11).
