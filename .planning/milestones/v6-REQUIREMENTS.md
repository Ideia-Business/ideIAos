# Requirements — IdeiaOS v6 (Resiliência + Camada de Marketing)

**Total de requisitos v6:** 10
**Origem:** análise comparativa AIOX-CORE × OpenSquad × IdeiaOS (2026-06-15, vault `Decisions/Comparativo AIOX-CORE vs OpenSquad vs IdeiaOS.md`)

## Tema A — Absorção das 3 indicações técnicas (Fases 23-25)

### R6-01 (P1) — Bash gates anti-alucinação
Padrão `test -s` binário (input antes / output depois de cada step) absorvido do OpenSquad nos hooks e skills do IdeiaOS que validam saída de etapa. Princípio: "não confie no Read tool (alucinável); confie no exit code binário". **Critério:** ≥1 helper reutilizável (`assert_nonempty`/`gate_output`) + aplicado em ≥3 pontos reais (memory-export, build-adapters, observe) + documentado em rule.

### R6-02 (P1) — Resiliência / retomada de spawn (Agent Immortality adaptado)
Captura de estado antes de operação que pode falhar + retomada idempotente, aplicada primeiro ao spawn background do instinct loop (a lição runaway provou o valor). **Critério:** spawn de `/instinct-analyze` grava breadcrumb; se morrer no meio, a próxima sessão detecta e retoma/limpa sem duplicar; teste reproduz crash + retomada.

### R6-03 (P2) — Geração de agents/skills fundamentada em pesquisa
Skill/processo que pesquisa padrões reais do domínio antes de criar um novo agent/skill (vs persona genérica). Inspirado no Design phase do OpenSquad. **Critério:** skill `/forge-agent` (ou extensão do skill-creator) que produz spec fundamentada com fontes citadas.

### R6-04 (P2) — Validador de paridade multi-IDE
`build-adapters.sh` ganha validação de equivalência entre targets Claude e Cursor (não só frontmatter). **Critério:** `build-adapters.sh --validate-parity` reporta divergências; exit 1 se componente existe num target e falta no outro sem justificativa.

## Tema B — Camada de Marketing acionável (Fase 26)

### R6-05 (P1) — Orquestrador `/marketing` (a "sessão de Marketing")
Skill orquestradora acionável que recebe pedido de marketing em linguagem natural e conduz o pipeline (discovery → design → build → review → publish), absorvendo o paradigma do OpenSquad adaptado à arquitetura IdeiaOS. **Critério:** `/marketing` invocável direto e roteável; conduz ≥1 fluxo completo end-to-end (ex.: carrossel/post).

### R6-06 (P1) — Deia orquestra Marketing
Matriz do `/idea` ganha rotas: "criar post/carrossel/blog/newsletter/VSL/roteiro/campanha/conteúdo/thread" → camada Marketing. **Critério:** `/idea "cria um carrossel sobre X"` roteia para `/marketing`; documentado na matriz e no manifesto IDEIAOS.md.

### R6-07 (P1) — 22 best-practices de conteúdo via quarentena
As 22 best-practices do OpenSquad absorvidas via `scan-absorbed.sh` para `source/rules/marketing/`, com atribuição MIT. **Critério:** ≥20 em quarentena → scan PASS → promovidas; header de atribuição `# SOURCE: OpenSquad MIT`; zero `<!--`.

### R6-08 (P2) — Sherlock (investigação de perfis) como skill
Skill que investiga perfis reais via Chrome DevTools MCP (que já temos) para calibrar geração com métricas reais. Adaptado do Sherlock. **Critério:** skill de research de marketing documentada e acionável usando o MCP existente.

### R6-09 (P2) — Agents de conteúdo
≥4 agents de marketing com model routing (estrategista, copywriter, designer, revisor/publisher), orquestrados pelo `/marketing`. **Critério:** em `source/agents/` com frontmatter model+tools.

## Tema C — Sugestão pendente varrida (Fase 27)

### R6-10 (P3) — Test hardening
Gap da análise (IdeiaOS só 3 suites; AIOX cobertura em erosão; OpenSquad engine não-testável). Testes shell para scripts/hooks críticos. **Critério:** ≥5 novas suites em `tests/` rodando no CI estrutural.

## Coverage

| Req | Fase |
|-----|------|
| R6-01 | 23 antifragile-gates |
| R6-02 | 24 agent-resilience |
| R6-03, R6-04 | 25 grounded-build-parity |
| R6-05..R6-09 | 26 marketing-layer |
| R6-10 | 27 test-hardening |

---

## Tema D — Indicações da análise GSD × OpenSpec (Fases 28-31) [adicionado 2026-06-16]

Origem: vault `Decisions/Comparativo GSD vs OpenSpec.md`. Documentadas aqui para a próxima sessão fechar junto com 23/24/25/27.

### R6-11 (P1) — Blindar linhagem/pin do GSD
Travar `@opengsd/get-shit-done-redux@1.1.0` exato + documentar definitivamente a linhagem (redux ≠ gsd-pi; org open-gsd ≠ gsd-build) em `versions.lock` (nota), STATE e handoff. Fecha a causa-raiz do pin revertido 3×. **Critério:** nota de linhagem no versions.lock + doctor avisa se o pin sair de 1.1.0 da linha redux; nenhuma confusão redux/Pi possível.

### R6-12 (P2) — Padrão context-packet nos handoffs
Adotar os 3 conceitos do context-packet (token budget + anti-injection wrapper + idempotência por hash) no nosso sistema de handoffs (`.aiox/handoffs/`, `handoff-consolidation.md`) — SEM depender do pacote (está quieto). **Critério:** handoffs ganham budget de tokens + wrapper anti-injection + hash de idempotência; documentado em rule.

### R6-13 (P2) — Camada delta-spec brownfield (conceito OpenSpec)
Nova capability opcional do IdeiaOS: corpus de specs vivas com deltas (ADDED/MODIFIED/REMOVED/RENAMED requirements → merge em source-of-truth → archive datado), para os produtos brownfield (nfideia, ideiapartner, cfoai). COMPLEMENTA o GSD (não substitui). **Critério:** skill/estrutura `specs/<capability>/spec.md` + fluxo de delta + archive; piloto num produto. (Fase maior — pode ficar como spike se o tempo apertar.)

### R6-14 (P3) — Avaliar gsd-browser (opt-in)
Piloto do gsd-browser como substituto +barato/determinístico do chrome-devtools MCP numa skill visual (frontend-visual-loop/web-quality). **Critério:** avaliação documentada (ADR) com decisão adotar/adiar; nenhuma troca forçada.

### R6-15 (P3) — agent-inbox sob demanda
Documentar o agent-inbox como MCP opt-in para testes de auth/email nos produtos (nunca em prod, higiene de MCP). **Critério:** doc de uso opt-in; não instalado by default.

## Coverage Tema D

| Req | Fase |
|-----|------|
| R6-11 | 28 gsd-lineage-lock |
| R6-12 | 29 context-packet-handoffs |
| R6-13 | 30 openspec-delta-spec |
| R6-14, R6-15 | 31 tooling-eval-optin |
