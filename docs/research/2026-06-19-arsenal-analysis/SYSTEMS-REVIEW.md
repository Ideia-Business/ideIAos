# SYSTEMS-REVIEW.md — Revisão NASA de Sistemas (IdeiaOS)

## Veredito de fitness: **FIT_WITH_RISKS**

O IdeiaOS é um sistema genuinamente bem-engenheirado — não é um canivete com lâminas demais. Está **apto a voar**, e as absorções v11 propostas **preservam a integridade**. Mas opera **perto do teto de superfície navegável** e está preso, na fronteira de integridade, por automação não-supervisionada que pode contornar seus próprios guards. As ações de maior alavancagem **não são adicionar capacidade** — são endurecer o escritor autosync e puxar a superfície de volta para baixo do roteador `/idea`.

---

## Forças do sistema

1. **Disciplina de proveniência real e auditável, não aspiracional.** 41/46 skills carregam header `# SOURCE`; toda absorção externa (ECC, OpenSpec, agent-skills, mattpocock, context-packet) aterrissa em `security/quarantine/` com LICENSE preservada e é congelada atrás de um ADR em `docs/decisions/`. A doutrina "absorver só o delta, nunca re-absorver" é **imposta por artefatos**, não só declarada.

2. **Defesas causalmente ligadas a incidentes e conectadas ao caminho de commit real.** A regressão de deny 5/5→2/5 produziu o check 7e no `idea-doctor.sh` (FAIL se qualquer produto Lovable cair abaixo de deny≥19) + teste de regressão (`tests/idea-doctor/test-lovable-mcp-containment.sh`) + wiring em CI. O semver trap do GSD produziu `check-versions-lock.sh` no `.git/hooks/pre-commit` com enforcement single-writer e warning **direcional** (o warning genérico induzira 3 reverts). O drift manifesto/build-array produziu `check-plugin-membership.sh`. **Antifragilidade funcionando como projetada** — cada mordida endureceu uma costura específica.

3. **O princípio antifragile-gates é estruturalmente sólido e aplicado consistentemente.** `gates.sh` valida artefatos por `test -s` / exit code binário, nunca confiando no Read tool, com split claro hook-contract (exit 0, nunca bloqueia o IDE) vs build-contract (exit 1, falha alto). `idea-doctor.sh` é uma auditoria read-only genuinamente abrangente (10 seções: health + drift + security).

4. **Higiene de decisão sob pressão excelente.** O write-path do v10 Lovable MCP foi BLOQUEADO por uma regra pré-comprometida ("indeterminate-votes-block", não racionalização post-hoc); o milestone parcial foi honestamente marcado no-tag; o v10-MILESTONE-AUDIT corrige a própria imprecisão retórica ("inmensurável no instrumento fork" ≠ "impossível via MCP"). O sistema **recusa capacidade irreversível voltada para fora sem evidência positiva**.

5. **O orquestrador `/idea` (Deia) é a mitigação explícita de superfície.** Ponto de entrada único em linguagem natural que roteia para a camada certa — o operador navega intenção, não o catálogo. O modelo de 5 camadas (aiox-core / gsd / lovable / learning-loop / continuation) dá ao sprawl um modelo mental coerente; a rule de linguagem ubíqua dos três-CONTEXT combate ativamente a colisão conceitual.

---

## Riscos sistêmicos priorizados

### Risco 1 — git-autosync: escritor paralelo que contorna os próprios guards · **SEVERIDADE: HIGH**
**O quê:** O daemon git-autosync (`git add -A` + commit + push em ciclo) é um single-point-of-failure estrutural que **bypassa os pre-commit guards de que o sistema depende**. Já contaminou (documentadamente) uma cirurgia git multi-repo (varreu conflict markers + package-lock para uma branch não-relacionada e pushou), bloqueou um push para um clone stale, e pode capturar a janela de live-reload das deny rules em `.claude/settings.json`.

**Por que importa:** `check-versions-lock`, `check-memory-not-on-main` e `check-plugin-membership` são enforçados **apenas** no `.git/hooks/pre-commit` (por-máquina, instalado via `install-git-hooks.sh`) e em suites de CI — mas o caminho de commit do próprio autosync é um escritor paralelo que **não necessariamente atravessa esses guards** e roda não-supervisionado em várias máquinas com clones possivelmente stale. Um auto-committer correndo contra git cirúrgico é exatamente como a deny-regression e a contaminação de conflict-marker aconteceram. **É o vetor mais provável de uma regressão silenciosa de integridade chegar à `main` — que a Lovable lê.**

**Mitigação:** Tornar o autosync **guard-aware** — recusar commit quando houver conflict markers, churn de lockfile, ou paths de memória no working tree, e quando a branch local não for fast-forward para origin. Adicionar self-pause/lock que o daemon respeite durante cirurgia git de IA (o learning já prescreve bootout manual — **codifique-o**). Rodar `idea-doctor.sh` (não só as suites unitárias) e `check-versions-lock` em CI no push, para que uma máquina regredida seja pega **centralmente**, não só pela próxima auditoria manual.

### Risco 2 — Superfície cognitiva/operacional além do limiar de navegação segura · **SEVERIDADE: MEDIUM**
**O quê:** Uma máquina fresca expõe ~103 skills globais (67 gsd-* + 36 IdeiaOS/vendored), 31 agentes+personas, ~20 rules ativas, ~3700 linhas de contexto sempre-carregado (CLAUDE.md + rules). A camada GSD vendorizada (67 skills, muitas quase-duplicatas: gsd-plan-phase / gsd-mvp-phase / gsd-ultraplan-phase / gsd-spec-phase / gsd-ui-phase) é a contribuinte dominante e **NÃO é autoria do IdeiaOS** — logo a menos controlável.

**Por que importa:** Um operador IA precisa desambiguar dezenas de verbos sobrepostos a cada turno; um humano não segura o catálogo na memória de trabalho. Isso eleva a probabilidade de mis-routing e erode a propriedade "uma ferramenta óbvia" de que sistemas mission-critical dependem. É o custo estrutural da taxa de absorção v2→v10.

**Mitigação:** Apoiar-se em `gsd-surface`/`gsd-ns-*` (já presentes) para shipar PROFILES curados de skills que escondem clusters não-essenciais por default, expondo o conjunto completo só sob demanda. Tratar a cobertura de roteamento do `/idea` como **contrato testado** (asserir que cada linha de intenção documentada resolve para exatamente uma camada). Periodicamente rodar `/improve-architecture` sobre o próprio catálogo de skills para aposentar/fundir verbos quase-duplicados.

### Risco 3 — Passes LLM do v11 (`--analyze`/`--converge`) que o gate binário não consegue verificar · **SEVERIDADE: MEDIUM**
**O quê:** Os passes propostos para o v11 são passes de LLM, não shell determinístico — o gate antifragile só consegue asserir que **um arquivo de relatório foi escrito** (`test -s`), não que o lint cross-artefato estava **correto**. O próprio REPORT.md sinaliza isso.

**Por que importa:** Introduz uma classe de capacidade onde a própria doutrina de gate-binário (a coisa que torna os outros gates confiáveis) **não consegue verificar correção, só existência**. Mal-rotulada como "gated", criaria falsa confiança de que spec/plan/código são consistentes quando o pass LLM silenciosamente perdeu um drift — o oposto de mission assurance.

**Mitigação:** Manter como **gate duro** qualquer sub-check que PODE ser shell (ex.: o parser de cenário de 4-hashtags já em `spec-validate.sh`, zero-padding de ID, existência de nome-de-capability); marcar o julgamento LLM **explicitamente como ADVISORY** no header do relatório, para que nenhum step downstream o trate como gate pass/fail. Adicionar regressão baseada em fixture que alimenta um drift spec-vs-código conhecido e asserir que `--analyze` o detecta.

### Risco 4 — Velocidade de absorção acima do cool-down necessário para detectar dívida latente · **SEVERIDADE: LOW**
**O quê:** v2→v10 em ~7 dias, vários milestones shipados no mesmo dia (≥3 em 2026-06-12, 2 em 2026-06-16). O v10 fechou PARCIAL com write-path bloqueado e C/D parqueadas.

**Por que importa:** Ships no mesmo dia comprimem a janela em que os modos de falha de uma absorção emergem (a deny-regression foi achada por uma auditoria manual POSTERIOR, não no ship). Mantido nessa cadência, dívida acumula mais rápido que o learning loop a aposenta, e "shipado" passa a significar "merged" em vez de "provado durável".

**Mitigação:** Adotar um período de **soak**: nenhum milestone é tagueado DONE até `idea-doctor` + suites de regressão passarem em ≥2 máquinas por ≥1 dia pós-merge. O sistema já tem o instrumento (milestone audits + idea-doctor); tornar o soak um **gate, não uma cortesia**. Manter a prática saudável de marcar milestones parciais no-tag.

### Risco 5 — Disciplina de proveniência/quarentena forte mas não fechada · **SEVERIDADE: LOW**
**O quê:** 5 de 46 skills não têm header `# SOURCE`, e o pin do design-suite é um seed local (`design-suite-commit=local-seed-2026-06-02, ref=main`) em vez de um hash de commit upstream resolvido.

**Por que importa:** A reivindicação de integridade "absorver o delta, atribuir tudo" é tão forte quanto seu módulo não-atribuído mais fraco; um ref flutuante `main` numa suite vendorizada significa que "pinado" não é de fato reproduzível para essa dependência.

**Mitigação:** Adicionar guard `check-source-headers` (WARN) no `idea-doctor` sobre `source/skills/*/SKILL.md`, e resolver `design-suite-commit` para um hash upstream real via `update-design-suite.sh`, para que a suite vendorizada seja byte-reproduzível como os pins GSD/aiox.

---

## Veredito sobre as absorções propostas

**SOUND e apropriadamente contido.** O REPORT.md conclui corretamente que "nenhuma fonte justifica absorção massiva" e roteia quase tudo para ALREADY_HAVE ou LOW. A disciplina de confrontar **só o delta**, tratar conteúdo externo como **dado** (anti-injection), e rejeitar o que viola mcp-hygiene/token-economy (nenhum MCP novo, nenhum plugin) é exatamente a postura certa para integridade de missão, e é consistente com os ADRs congelados.

**Endossado com dois guard-rails:**
1. **O único candidato genuíno** — spec-kit → `/spec --analyze` + `--converge` como **SUBCOMANDOS** de /spec (não skills novas) — é a forma correta porque adiciona **zero superfície top-level nova** e reusa o parser de `spec-merge.sh`. Mas sua natureza de pass-LLM **deve ser rotulada ADVISORY, não gated** (ver Risco 3), e `--converge` deve permanecer estritamente **append-only** para preservar a invariante de delta brownfield.
2. **Os deltas LOW** (escada de simplicidade do ponytail, recursive-decomposition, instruction-priority, marcador `// debt:`, rubric de 5 eixos de instinct) estão corretamente escopados como **edições de rules EXISTENTES** propagadas por `build-adapters.sh` — **não devem gerar novos arquivos de rule**, ou re-incorrem o custo de superfície que o relatório tenta evitar.

O conceito reflexion GPL-only e a SKIP list explícita (mattpocock inteiro, re-absorção GSD/OpenSpec, modos ultra/coercion) estão corretamente excluídos. **Líquido: as absorções propostas PRESERVAM a integridade; o único modo de falha seria scope-creep durante a implementação** (skills/rules novas em vez de subcomandos/edições) — que o `/grelha` sobre o recorte do v11 deve capturar.

---

## Ações de maior alavancagem (ordenadas)

1. **Tornar o git-autosync guard-aware e centralmente observável** — recusar auto-commit quando conflict markers / churn de lockfile / paths de memória estiverem staged ou quando a branch não for fast-forward para origin, e rodar `idea-doctor.sh` + `check-versions-lock` em CI no push (não só as suites unitárias). Fecha o SPOF de maior severidade — o escritor paralelo que bypassa os pre-commit guards e já causou dois incidentes documentados de integridade.

2. **Shipar PROFILES curados de skills** via a maquinaria existente `gsd-surface`/`gsd-ns-*` para que uma máquina fresca exponha ~15-25 skills essenciais por default em vez de 103, e asserir o roteamento `/idea` como **contrato testado** (cada linha de intenção documentada resolve para exatamente uma camada). Ataca a superfície diretamente sem deletar capacidade.

3. **Instituir um gate de SOAK de milestone** — nenhum DONE/tag até `idea-doctor` + suites de regressão passarem em ≥2 máquinas por ≥1 dia pós-merge. Converte os instrumentos de auditoria existentes em um governador de velocidade; teria pego a regressão deny 5/5→2/5 no ship em vez de numa auditoria manual posterior.

4. **Ao implementar o v11, manter a linha:** `--analyze`/`--converge` são SUBCOMANDOS de /spec e os deltas LOW são EDIÇÕES de rules existentes — zero novas skills ou rules top-level — e marcar todos os passes de julgamento-LLM como **ADVISORY (não gated)**. Rodar `/grelha` sobre o recorte primeiro, como o relatório recomenda.

5. **Fechar o gap de proveniência** — adicionar guard WARN no `idea-doctor` para headers `# SOURCE` ausentes (5/46 skills), e resolver `design-suite-commit` de um ref flutuante `main` para um hash upstream real, para que toda dependência vendorizada seja byte-reproduzível como os pins GSD/aiox.

---

## Fechamento

O IdeiaOS é um sistema genuinamente bem-engenheirado. A **cultura de engenharia é o ativo real**: todo incidente produziu uma defesa conectada, testada, causalmente ligada (check 7e da deny-regression, check-versions-lock do semver trap, gates.sh da falha de confiar-no-Read-tool); a proveniência é auditável até quarentena + ADR + headers `# SOURCE`; e o time demonstravelmente bloqueia capacidade irreversível (write-path do v10) por **evidência positiva, não otimismo**. Isso é comportamento de mission-assurance.

Os contrapesos honestos: (1) os incidentes citados **não são isolados** — autosync-races-surgery e deny-regression são o mesmo padrão estrutural (um escritor paralelo não-supervisionado correndo contra git cirúrgico distribuído), e esse padrão é o caminho mais credível para uma regressão silenciosa chegar à `main` que a Lovable lê; (2) a superfície de 103 skills / 31 agentes, dominada pela camada GSD vendorizada que o projeto não controla, excede o que um operador navega com segurança sem que o roteador `/idea` e os profiles curados façam mais trabalho do que fazem hoje; (3) a cadência de absorção foi rápida o bastante para que "shipado" ocasionalmente tenha liderado "provado durável".

Nenhum desses é nível AT_RISK hoje, porque as defesas continuam pegando as regressões — mas as pegam via auditorias manuais posteriores, o que é **adjacente-à-sorte em escala**. **Veredito FIT_WITH_RISKS:** o sistema é apto a voar, as absorções v11 propostas preservam a integridade, e o movimento de maior alavancagem **não é adicionar capacidade** mas endurecer o escritor autosync e puxar a superfície de volta para baixo do roteador. Faça os guards rodarem **onde o daemon commita** e em CI, e o sistema avança para um FIT sem qualificação.
