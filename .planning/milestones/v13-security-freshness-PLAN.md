# v13 — Security Freshness Gate · PLAN + status

**Origem:** sessão de design 2026-06-20 (grilling + 3 decisões via AskUserQuestion).
**ADR:** `docs/decisions/v13-security-freshness-gate.md` (**Aceito**).
**Disciplina:** gatilho determinístico · LLM só na revisão · proporcionalidade (risco × idade) · zero dep nova · SOAK antes de tag.
**Status:** 🟡 **PARCIAL/no-tag** (2026-06-20) — núcleo W1-W4 (`8779d88`) + surfacing por produto opção C (`a6ab59d`) + propagação 4 produtos DONE. Tag `v13.0` aguarda SOAK (≥2 máquinas + span ≥1d).

> **Desvio do plano (registrado):** o R13-02/R13-09 previam "`check-security-freshness.sh` **por sistema**" (cópia versionada em cada produto). Implementado como **1 engine no IdeiaOS + `SECFRESH_ROOT` override** chamado por um hook `post-commit` local — **zero script versionado nos produtos**. Razão: os 2 produtos em `main` (nfideia/ideiapartner) são Lovable; qualquer arquivo *tracked* commitado em `main` dispara rebuild. O 1-engine entrega o mesmo intent (frescor por sistema) honrando a restrição Lovable-main. Promover a cópia self-contained por produto (via branch+PR) fica como could-have de v13.x.

## Princípio
Rigor = `risco da superfície tocada × idade da última revisão`. Nunca gateia PR de feature; gateia o **tag/release** (IdeiaOS) e **avisa** (Lovable). Reusa o padrão SOAK aplicado a dívida de segurança.

## Requisitos

| ID | Requisito | Itens | Status |
|----|-----------|-------|--------|
| R13-01 | Ledger `.security/review-ledger.log` por sistema (append-only, formato `epoch\|iso\|commit\|revisor\|veredito\|escopo`) + **bootstrap-baseline** no HEAD atual via `setup.sh --project-only` | a marcação | ✅ |
| R13-02 | `scripts/check-security-freshness.sh` — gatilho determinístico (`git diff <último_selo>..HEAD` + path-globs + score + idade → tier) **+ `--record`** (roda revisão/grava selo) | espelha `check-soak.sh` | ✅ |
| R13-03 | Risk-weighting config — pesos (3/1/0), globs por superfície, limiares (N=10/20, T=90/180d, crítico-30d); defaults conservadores e **tunáveis** | à prova de gaming | ✅ (em **defaults do script + env `SECFRESH_*` + `.security/policy.sh`** — NÃO `core-config.yaml`, que só existe no `.aiox-core` PRISTINE) |
| R13-04 | `idea-doctor §14` — lê o ledger, computa staleness, emite tier (OK silencioso / WARN); FAIL-soft só no contexto de tag-gate | leitura/emissão | ✅ |
| R13-05 | **Tag-gate** — tier egrégio bloqueia `git tag` no IdeiaOS (compõe com `check-soak`); produtos Lovable = WARN no doctor (sem tag pra travar) | onde morde | ✅ |
| R13-06 | Rule `source/rules/common/security-freshness.md` — doutrina (proporcionalidade, globs, escada, dois regimes); propagável via `setup --project-only` | a doutrina | ✅ |
| R13-07 | **1º ciclo advisory-puro** — flag de maturação: estreia com tag-gate DESLIGADO (WARN em todos); liga só após observar 1 ciclo (espírito SOAK) | de-risk do rollout | ✅ |
| R13-08 | Testes — caminho de FALHA (ledger stale → tier egrégio → tag bloqueada) + install do hook (husky-path, throttle, não-bloqueio) | prova o gate | ✅ (engine 10/10 + install 14/14; auto-descobertos pela regressão do `check-soak` via `tests/*/test-*.sh`) |
| R13-09 | Propagação aos 5 sistemas (IdeiaOS + 4 produtos) com **bootstrap-baseline** em cada + ADR/plan/README/STATE/handoff | rollout | ✅ (IdeiaOS = engine host; 4 produtos = surfacing layer local; rule auto-propaga via post-merge) |

## Ondas (ordem integridade-antes-de-capacidade)

- **W1 — Núcleo determinístico** (R13-01, R13-02, R13-03): ledger + `check-security-freshness.sh` (trigger + `--record`) + config de pesos/globs/limiares. O gatilho binário primeiro, sem nada de LLM. Bootstrap-baseline embutido.
- **W2 — Leitura & escada** (R13-04): `idea-doctor §14` lê o ledger e emite OK/WARN; mapeia os 3 tiers. Ainda sem travar nada.
- **W3 — Gate & doutrina & maturação** (R13-05, R13-06, R13-07): tag-gate (egrégio → bloqueia `git tag` no IdeiaOS, compõe com SOAK) + rule `security-freshness.md` + flag de 1º-ciclo-advisory (gate desligado na estreia).
- **W4 — Validação & rollout** (R13-08, R13-09): testes do caminho de FALHA + CI + propagação aos 5 com bootstrap-baseline + docs.

## Definition of Done

1. **Antifragile:** gatilho 100% determinístico (git/globs/contagem/tempo — zero LLM); revisão = `@security-reviewer`; selo determinístico. Verificado por `test -s`/exit-code, nunca Read tool.
2. **Não-enrijece:** nenhum PR de feature bloqueado em nenhum dos 5; só o `git tag` do IdeiaOS no tier egrégio.
3. **Bootstrap-baseline** em todos os 5 → dia-1 com `score=0` (sem vermelho instantâneo).
4. **1º ciclo advisory-puro:** tag-gate liga só após observação de 1 ciclo; limiares ajustáveis sem redeploy.
5. **Testes** provam o caminho de FALHA (stale → egrégio → tag bloqueada); CI wired.
6. **Propagação:** `build-adapters`/`build-plugins` rodados; rule nos 5; ADR/plan/README/STATE/handoff atualizados; aprende-se com nfideia (rules tracked-em-main → via PR, nunca auto-main).
7. **idea-doctor verde** (§14 ADVISORY até maturar).

## Pendente para TAG `v13.0`
SOAK ≥2 máquinas + ≥1d sobre `.planning/soak/v13-security-freshness.log` (gate herdado do v11). Ligar o tag-gate (R13-07) é decisão pós-observação do 1º ciclo.

## Riscos & decisões adiadas
- **Rollout 5-de-uma-vez** (escolha do usuário, não dogfood-first): risco de WARN ruidoso → mitigado por bootstrap-baseline + 1º-ciclo-advisory + limiares tunáveis.
- **Adiado:** promover OWASP LLM Top 10 de ADVISORY→bloqueante; bloquear PR em superfície crítica (3ª opção "onde morde", não escolhida); wirar `@security-reviewer` automático no PR. Tudo could-have de v13.x.
