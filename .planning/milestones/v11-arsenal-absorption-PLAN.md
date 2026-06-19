# Milestone v11 — Integridade & Auditoria de Spec (absorção pós-análise 2026-06-19)

> **Origem:** análise multi-fonte + validação 2-juízes + revisão NASA (`docs/research/2026-06-19-arsenal-analysis/`).
> **Tese:** integridade ANTES de capacidade. A NASA classificou o IdeiaOS **FIT_WITH_RISKS** e nomeou o maior lever como *endurecer o autosync*, não adicionar features. Por isso as ondas de hardening vêm primeiro; o único delta de capacidade que vale milestone (`/spec --analyze`/`--converge`) vem depois, com núcleo determinístico obrigatório.
> **Disciplina (NASA guard-rails):** zero novas skills/rules top-level — só SUBCOMANDOS de skills existentes e EDIÇÕES de rules existentes. Passes LLM = ADVISORY, nunca gated. `--converge` = append-only. SOAK antes de tag.

## Ondas

| Onda | Escopo | Status | Evidência |
|------|--------|--------|-----------|
| **W1 — Autosync guard-aware** | pause-file + conflict-marker guards no heredoc canônico (setup-dev-machine.sh) + patch idempotente step 2d (ideiaos-update.sh) + helper autosync-pause.sh + instalado nesta máquina | ✅ **DONE 2026-06-19** | commit `44336c5`; syntax 4/4, conflict-guard detecta+sem-FP, pause skip e2e, happy-path intacto |
| **W2 — Centralizar detecção + proveniência** (NASA #1+#5) | CI roda o SUBCONJUNTO repo-self-consistency no push (não só unit suites); guard `check-source-headers` (WARN); resolver `design-suite-commit` de ref flutuante `main` → hash real | ✅ **DONE 2026-06-19** | ver nota W2 abaixo |
| **W3 — SOAK gate + profiles de skills** (NASA #4+#2) | Gate de SOAK (doc + check). Profiles via `installStrategy` (já existe). `/idea` routing como contrato testado | ✅ **DONE 2026-06-19** | ver nota W3 abaixo |
| **W4 — `/spec --analyze` + `--converge`** (R1, único delta de capacidade) | Subcomandos em `source/skills/spec/lib/`. Núcleo determinístico HARD reusando a grammar. Passes LLM ADVISORY. `--converge` append-only. Fixture-regression. Rule delta-spec atualizada | ✅ **DONE 2026-06-19** | ver nota W4 abaixo; design-panel `wf_449a5952` |
| **W5 — Deltas LOW (PR de hardening, escopo cortado)** | **R2:** só a linha "feature nativa antes de dependência" no `operating-discipline.md` item 4 (NÃO a escada de 6). **R4:** rule curta de precedência de instrução (CLAUDE.md-usuário > skill > default) que REFERENCIA o OVERRIDE do harness, sem colidir com agent-authority/Constitution. **R6:** marcador `// debt:` comment-agnóstico + check WARN no idea-doctor com escopo `source/`+`scripts/` (ignorar próprio exemplo + terceiros). **R8:** nota de quarentena no ADR de licença (reflexion=GPL, zero código). **R3/R7:** backlog (só com gatilho operável). **R5:** adiar (gate confidence≥0.7 do /evolve já funciona) | ⬜ TODO | cada delta com corte individual; NÃO em lote cego |
| **W6 — ADR + fechamento** | ADR `v11-spec-kit-analyze-converge.md` ("minerar prompts, não importar premissa greenfield") + ADR de licença (R8). Atualizar STATE/ROADMAP/README. SOAK antes de tag (W3). Milestone parcial = no-tag (precedente v10) | ⬜ TODO | — |

## Nota W2 — entregue (2026-06-19)

**Entregue:**
- `scripts/check-source-headers.sh` (NOVO) — guard de proveniência ADVISORY. Deriva a lista vendorizada da linha `SUITE=` do `update-design-suite.sh` (fonte única → sem deriva declarativo×imperativo). Default exit 0; `--strict` exit 1 se faltar.
- Back-fill de `# SOURCE:` nas 10 skills nativas (9 `IdeiaOS` + `memory-sync` `IdeiaOS v5`). Guard agora verde (39 com SOURCE · 7 vendorizadas-via-pin · 0 faltando).
- `versions.lock` + `.design-suite-version`: `design-suite-ref` resolvido de `main` (flutuante) → `b7e3af80f6e331f6fb456667b82b12cade7c9d35` (concreto, reproduzível). `commit` mantido honesto como `local-seed-2026-06-02` com nota auto-documentada (re-vendor alinha).
- `idea-doctor.sh`: Seção 5 agora WARN quando `design-suite-commit` não é hash real (seed local); Seção 11 NOVA roda o guard de proveniência via `--strict`.
- `.github/workflows/evals.yml`: path filters ampliados (`scripts/**`, `versions.lock`, `manifests/**`, `.github/workflows/**`) + 2 HARD gates (`check-versions-lock`, `check-plugin-membership`) + 1 step advisory (`check-source-headers --strict` → `::warning::` non-blocking).
- README sincronizado (118/118).

**Correções de premissa (surfaced — operating-discipline #1/#2):**
1. Plano dizia "5/46 sem `# SOURCE`" → real era **17/46** (7 vendorizadas + 10 nativas). Convenção real = comentário `# SOURCE:` APÓS o frontmatter (não nas 3 primeiras linhas). Guard é data-driven, não hardcoded.
2. Plano dizia "CI roda `idea-doctor.sh`" → idea-doctor AUDITA uma máquina-dev (install global `~/.claude`) e FALHARIA num runner fresco (Seção 1). CI roda só o SUBCONJUNTO repo-self-consistency (versions-lock + plugin-membership + source-headers). Registrar no ADR de fechamento (W6).

**Resíduo honesto (não-bloqueante):** o conteúdo vendorizado da Suíte ainda é seed local; `idea-doctor` Seção 5 sinaliza com WARN + comando de alinhamento. Re-vendor para hash real = housekeeping futuro (fora do escopo de uma onda de CI/proveniência — muda conteúdo de 7 skills L2 + re-aplica overlay OKLCH).

## Nota W3 — entregue (2026-06-19)

**Entregue:**
- `scripts/check-soak.sh` (NOVO) — SOAK gate: ledger append-only por milestone (`.planning/soak/<m>.log`), `--record` (roda idea-doctor+regressão estrutural, grava heartbeat), verify (≥2 máquinas + ≥1 dia → exit 0), `--status`, bypass por env. Dogfoodado: exit 1 quando não-soaked, 0 no cenário 2-máquinas/2d, 2 em invocação ruim. **Auto-aplica ao v11** (não pode tagear na sessão de build).
- `docs/process/soak-gate.md` (NOVO) — política + mecanismo + integração com W6 (no-tag até soak) + relação com profiles. (`docs/ideiaos/` é gitignored/gerado — por isso `docs/process/`.)
- **Profiles:** descoberto que a superfície de máquina fresca **já é curada** por `installStrategy` no `manifests/modules.json` — `always`=25 (perfil default, dentro do alvo 15-25), `stack:<x>`=10, `manual`=11. NÃO era ~103. Deliverable virou: documentar o contrato + guard de orçamento no `idea-doctor` Seção 11 (WARN se `always` > teto 28). Sem mudança de produto unilateral (no-invention).
- **/idea routing como contrato testado:** EVAL-023 (bug intermitente→`/gsd-debug`), EVAL-024 (publicar→`/lovable-handoff`, invariante anti-main 🔴), EVAL-025 (vuln pré-deploy→agent `security-reviewer`). 22→25 casos; frontmatter OK; dry-run pega os 3.
- `idea-doctor` Seção 11 renomeada → "Proveniência & superfície"; README sincronizado.

**Correção de premissa (surfaced):** plano dizia "máquina fresca expõe ~103 skills" e "profiles via gsd-surface" → real: o `installStrategy` do manifesto JÁ cura para 25 always (alvo já atingido). gsd-surface (skill GSD) é para surfacing contextual, não para o perfil de install. O delta real era documentar + guardar contra regrowth, não construir mecanismo.

**Resíduo honesto:** o ledger de soak do v11 começa de fato no W6 (heartbeats contra o estado RC, não commits intermediários — por isso o heartbeat de teste foi removido). As 3 eval cases de routing são LLM-scored (rodam no CI sob demanda / `run-evals.sh --ci`), não no gate estrutural.

## Nota W4 — entregue (2026-06-19)

Precedido por **design-panel** (3 designs independentes + juiz, `wf_449a5952`) em vez de `/grelha` (usuário pediu completar, não grilling interativo).

**Entregue:**
- `source/skills/spec/lib/spec-grammar.sh` (NOVO) — gramática COMPARTILHADA (ponto único de verdade: `gram_is_req_header`, `gram_req_name`, `gram_is_scenario`, `gram_is_delta_section`, `gram_is_block_break`, `gram_scan_reqs`). Cópia literal das condições de validate/merge → unificação futura trivial; **não** refatora os gates existentes (escopo/risco). Honra learning declarative-vs-imperative-drift.
- `source/skills/spec/lib/spec-analyze.sh` (NOVO) — gate da SPEC VIVA pós-merge. **HARD:** A1 req-sem-cenário, A2 cenário-nível-errado, A3 header-duplicado, A4 delta-token-vazado. **ADVISORY:** A5 cross-ref path-morto + passes LLM. Exit 0/1/2; `--advisory-only` nunca falha.
- `source/skills/spec/lib/spec-converge.sh` (NOVO) — ponte **append-only** spec↔código: quarentena `_changes/_converge-<TS>/` (RELATORIO + delta-candidato MODIFICADO/TODO + proposta stub). Garantia 4-camadas + sha256 before/after + rollback. **Round-trip provado:** candidato valida limpo no `spec-validate.sh`.
- `tests/spec-analyze.bats` (NOVO) — fixture-regression dual-mode (1 defeito HARD por capability + A5 advisory + cap sã + produto-clean). **18/18 asserts verdes.**
- `SKILL.md` + `delta-spec.md` (fronteira /spec --analyze × gsd-code-review × GSD) + espelho `.claude/rules` via build-adapters.
- **CI + SOAK wiring:** evals.yml roda `tests/*.bats` (bash fallback) — **corrige o órfão pré-existente** `spec-merge.bats` (nunca rodava no CI) + adiciona o novo. `check-soak.sh` também varre `tests/*.bats`.

**Correções de premissa (surfaced):** (1) o design-panel assumiu um harness `bats` instalado — na real `bats` não está instalado e o CI só globava `tests/{v6-hooks,idea-doctor}/test-*.sh`; `spec-merge.bats` é dual-mode (roda via `bash`) mas estava órfão do CI. Resolvido: rodar via bash fallback + wire. (2) A2 com `[aá]rio` em bracket multibyte não casava sob a locale; troquei pelo prefixo `[Cc]en`/`[Ss]cen` (robusto, espelha validate L54).

**Incidental:** o build-adapters materializou `.cursor/rules/ideiaos-lovable-mcp-protocol.mdc` (espelho cursor da rule v10 que nunca fora commitado) — incluído no commit por ser artefato gerado legítimo.

**Resíduo:** verificação adversarial multi-lente (workflow) roda após o commit; achados viram follow-up.

## Divergências dos juízes (DECISÃO DO USUÁRIO — ver VALIDATION.md)

- **Timing do W4 (v11):** Juiz A = fechar v10 (Lovable MCP, C/D parqueadas) ANTES; Juiz B = fazer já, com cortes. Ambos concordam na FORMA (determinístico + ADVISORY + R11-03 fora). **Aberto.**
- **R5:** DROP/adiar (peso) vs KEEP-LOW. **Aberto** — default adiar.

## Fontes confrontadas (veredito)
spec-kit=PARTIAL (W4+W5) · ponytail=PARTIAL-LOW (W5) · voltagent/awesome-agent-skills=PARTIAL-LOW (W5) · vídeo/superpowers=PARTIAL-LOW (W5/R4) · **mattpocock=ALREADY_HAVE** (v9, nada a fazer).

## Próximo passo (retomada)
W1, W2, W3 (integridade) e W4 (capacidade — `/spec --analyze`/`--converge`) estão DONE. Falta **W5** (deltas LOW de hardening: R2/R4/R6 com corte individual; R8 nota GPL; R3/R7 backlog; R5 adiar) e **W6** (ADRs + fechamento + SOAK antes de tag — milestone parcial = no-tag). Verificação adversarial do W4 roda em workflow pós-commit.
