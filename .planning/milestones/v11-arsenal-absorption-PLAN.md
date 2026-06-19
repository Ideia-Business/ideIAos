# Milestone v11 — Integridade & Auditoria de Spec (absorção pós-análise 2026-06-19)

> **Origem:** análise multi-fonte + validação 2-juízes + revisão NASA (`docs/research/2026-06-19-arsenal-analysis/`).
> **Tese:** integridade ANTES de capacidade. A NASA classificou o IdeiaOS **FIT_WITH_RISKS** e nomeou o maior lever como *endurecer o autosync*, não adicionar features. Por isso as ondas de hardening vêm primeiro; o único delta de capacidade que vale milestone (`/spec --analyze`/`--converge`) vem depois, com núcleo determinístico obrigatório.
> **Disciplina (NASA guard-rails):** zero novas skills/rules top-level — só SUBCOMANDOS de skills existentes e EDIÇÕES de rules existentes. Passes LLM = ADVISORY, nunca gated. `--converge` = append-only. SOAK antes de tag.

## Ondas

| Onda | Escopo | Status | Evidência |
|------|--------|--------|-----------|
| **W1 — Autosync guard-aware** | pause-file + conflict-marker guards no heredoc canônico (setup-dev-machine.sh) + patch idempotente step 2d (ideiaos-update.sh) + helper autosync-pause.sh + instalado nesta máquina | ✅ **DONE 2026-06-19** | commit `44336c5`; syntax 4/4, conflict-guard detecta+sem-FP, pause skip e2e, happy-path intacto |
| **W2 — Centralizar detecção + proveniência** (NASA #1+#5) | CI roda o SUBCONJUNTO repo-self-consistency no push (não só unit suites); guard `check-source-headers` (WARN); resolver `design-suite-commit` de ref flutuante `main` → hash real | ✅ **DONE 2026-06-19** | ver nota W2 abaixo |
| **W3 — SOAK gate + profiles de skills** (NASA #4+#2) | Gate de SOAK: nenhum milestone DONE/tag até idea-doctor+regressão passarem em ≥2 máquinas por ≥1 dia (doc + check). Profiles curados via `gsd-surface` (máquina fresca expõe ~15-25 skills, não ~103); `/idea` routing como contrato testado | ⬜ TODO | — |
| **W4 — `/spec --analyze` + `--converge`** (R1, único delta de capacidade) | Subcomandos em `source/skills/spec/` (NÃO skills novas). **Núcleo determinístico = HARD gate** (grep IDs órfãos, requisitos sem cenário, cross-ref de paths spec↔código, reusa parser de `spec-merge.sh`). Passes LLM rotulados **ADVISORY** no header. `--converge` **append-only**. Fixture-regression (drift conhecido → `--analyze` detecta). Atualizar `delta-spec.md` (fronteira /spec×GSD×gsd-code-review) | ⬜ TODO | precede: `/grelha` sobre o recorte (recomendado pela validação) |
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

## Divergências dos juízes (DECISÃO DO USUÁRIO — ver VALIDATION.md)

- **Timing do W4 (v11):** Juiz A = fechar v10 (Lovable MCP, C/D parqueadas) ANTES; Juiz B = fazer já, com cortes. Ambos concordam na FORMA (determinístico + ADVISORY + R11-03 fora). **Aberto.**
- **R5:** DROP/adiar (peso) vs KEEP-LOW. **Aberto** — default adiar.

## Fontes confrontadas (veredito)
spec-kit=PARTIAL (W4+W5) · ponytail=PARTIAL-LOW (W5) · voltagent/awesome-agent-skills=PARTIAL-LOW (W5) · vídeo/superpowers=PARTIAL-LOW (W5/R4) · **mattpocock=ALREADY_HAVE** (v9, nada a fazer).

## Próximo passo (retomada)
W1 e W2 estão DONE. Retomar em **W3** (SOAK gate + profiles de skills) — ondas de integridade primeiro. W4 (a feature) idealmente precedida de `/grelha` sobre o recorte. Recomenda-se contexto fresco por onda (disciplina de SOAK aplicada ao próprio trabalho).
