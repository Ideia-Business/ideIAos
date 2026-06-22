# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Tasks: v14.4-write-path-security

**Change:** v14.4-write-path-security
**Capability(ies):** cockpit
**Gerado em:** 2026-06-22

Estas tasks derivam do delta e são consumíveis pelo GSD (`/gsd-execute-phase v14.4`) **somente após**
as pré-condições do gate (grupo 2) estarem resolvidas. Formato: `- [ ] N.M descrição`.

> **Natureza deste contrato:** é um **gate**, não um milestone de entrega. As tasks de implementação
> (grupos 3–4) ficam **bloqueadas** até o grupo 2 fechar Q1–Q3. Nada de código cross-máquina entra
> antes disso (R-WP10).

---

## 1. Ratificação do contrato

- [ ] 1.1 Operador revisa os 11 requisitos do delta (`delta/cockpit.md`) e a proposta
- [ ] 1.2 Validar delta: `bash source/skills/spec/lib/spec-validate.sh specs/_changes/v14.4-write-path-security` (exit 0)
- [ ] 1.3 Merge: `bash source/skills/spec/lib/spec-merge.sh . v14.4-write-path-security --yes` → contrato vivo em `specs/cockpit/spec.md`
- [ ] 1.4 Confirmar archive em `specs/_archive/<AAAA-MM-DD>-v14.4-write-path-security/`

---

## 2. Pré-condições do gate — DECISÕES BLOQUEANTES (Q1–Q3, sem código de execução)

- [ ] 2.1 **Q7/A4** — verificar estado de signing-git: `git config --get commit.gpgsign` e `gpg.format`. Decide O2 (chave dedicada no keychain) vs O3 (SSH-signed commits/tags reusando a infra git)
- [ ] 2.2 **Q1** — desenhar bootstrap de confiança das chaves de máquina (TOFU + pin): quem assina a lista de `allowedSigners` sem CA? Registrar a decisão como ADR
- [ ] 2.3 **Q2** — desenhar revogação de chave de máquina comprometida sem canal já-confiável (problema PKI sem CA). Registrar como ADR
- [ ] 2.4 **Q3** — provar viabilidade do step-up sem relying-party server: `LocalAuthentication` (Touch ID) **via o agentd-origem** (server-side, fora do browser) produzindo o token assinado de uso único
- [ ] 2.5 **Q4** — desenhar registro de nonces-vistos no alvo + tolerância de clock entre máquinas assimétricas (anti-replay)
- [ ] 2.6 **Q5** — decidir separar ref-de-telemetria de ref-de-comando: o `origin` (GitHub) deve sequer ver o ref de comando?
- [ ] 2.7 **Q6** — enumerar por provedor (Vercel/Railway/Supabase) qual tem caminho keychain-nativo e qual deixa valor no env-da-borda (least-privilege real)
- [ ] 2.8 **Q8** — desenhar o protocolo de ACK idempotente sobre o bus eventual (~15min)
- [ ] 2.9 **Q9** — ratificar detecção≠prevenção do ledger como risco residual aceito (ou endurecer)

> **Gate duro:** 2.2/2.3/2.4 (Q1/Q2/Q3, CRÍTICAS) **bloqueiam** todo o cross-máquina. Enquanto
> abertas, só o caminho same-machine do grupo 3.1 é permitido.

---

## 3. Implementação incremental (bloqueada pelo grupo 2)

- [ ] 3.1 **Fase A — same-machine** (não exige Q1–Q3): `rotate sensível` na própria máquina sob janela-de-privilégio-com-teardown (R-WP5/R-WP6). Maturar 1 ciclo (SOAK) antes de prosseguir
- [ ] 3.2 Capacidade de assinatura por-máquina bootstrapada e verificada (depende de 2.1–2.3)
- [ ] 3.3 **Fase B — cross-máquina read-only** (forçar re-coleta) com comando assinado fail-closed (R-WP1/R-WP2) + ACK idempotente (R-WP8)
- [ ] 3.4 **Fase C — rotate cross-máquina** sensível/alto com step-up assinado (R-WP3) + janela-com-teardown
- [ ] 3.5 **Fase D — deploy / revoke critical** por último, sempre com out-of-band (O4) (R-WP10)
- [ ] 3.6 Ledger encadeado por hash com assinatura do emissor (R-WP9)

---

## 4. Testes (gates por exit-code — `antifragile-gates`)

- [ ] 4.1 Cobrir cada cenário ADICIONADO com teste automatizado (fail-closed, replay, binding divergente, teardown rollback)
- [ ] 4.2 Gate Zero-Leak estendido ao canal de comando: valor de segredo em ref/payload/ledger/log reprova (R-WP4)
- [ ] 4.3 Teste de assinatura: comando sem assinatura / só-sha256 / chave-não-fixada → recusa (R-WP1)
- [ ] 4.4 Teste anti-replay: token expirado / nonce reusado → recusa (R-WP3)
- [ ] 4.5 Teste de fronteira: cada verbo de R-WP7 (reveal/exec/push/MCP/mass-revoke/auto-rotate/**custódia de chave-mestra central**) → recusa mesmo autenticado
- [ ] 4.6 Teste de rate-limit (R-WP11): rajada de `rotate`/`deploy` acima do threshold por `ref`+`subject` → recusa/backpressure
- [ ] 4.7 Rodar suite completa e garantir green

---

## 5. Frescor de segurança

- [ ] 5.1 `@security-reviewer` sobre o diff da fase v14.4 (STRIDE + OWASP-LLM)
- [ ] 5.2 `bash scripts/check-security-freshness.sh --record PASS @security-reviewer` (re-selo após a revisão)
