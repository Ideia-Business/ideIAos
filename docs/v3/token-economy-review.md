# SOURCE: IdeiaOS v2

**Data:** 2026-06-12
**Fase:** 08-03 — Token Economy Review
**Alimenta:** 08-04 (otimizações concretas)

---

## Resumo

O IdeiaOS roteia bem os 15 agents: haiku cobre as buscas repetitivas, sonnet domina reviews e implementação, opus fica reservado para planejamento e segurança. Os dois agents sem `model:` explícito (claude-continuation, ideiaos-checker) herdam o padrão do harness e devem ser pinados. O overhead de hooks é controlado, com uma exceção: `strategic-compact` executa um subprocess Python a cada chamada de ferramenta — a frequência mais alta do conjunto; sua justificativa é defensível, mas pode ser aliviada.

**Decisão mgrep/LSP:** mgrep — **adiar** (sem benchmark IdeiaOS confirmado); typescript-lsp — **adotar sob demanda** com `installStrategy: stack:typescript`; pyright-lsp — **adiar** (projetos Python ativos insuficientes no ecossistema Ideia Business atual).

---

## Matriz Modelo x Acao

| Agente | Modelo atual | Custo relativo | Veredito | Justificativa |
|--------|-------------|----------------|----------|---------------|
| code-explorer | haiku | baixo | manter | Busca pura (Read, Grep, Glob); sem raciocínio estrutural. Ideal haiku. |
| doc-updater | haiku | baixo | manter | Atualização mecânica de texto existente; sem decisão de arquitetura. |
| claude-continuation | NENHUM (herda padrão) | — | pinnar sonnet | Faz síntese de sessão e recuperação de contexto — requer entendimento médio; sonnet adequado. |
| ideiaos-checker | NENHUM (herda padrão) | — | pinnar sonnet | Verificação de setup e conformidade; sonnet suficiente, opus seria desperdício. |
| build-error-resolver | sonnet | médio | manter | "Escalar para opus se 1ª tentativa falhar" já está na descrição — escalonamento sob demanda. |
| code-simplifier | sonnet | médio | manter | Refactor preservando comportamento; sonnet cobre bem. |
| react-reviewer | sonnet | médio | manter | Revisão de hooks e padrões React; sonnet suficiente para regras codificadas. |
| refactor-cleaner | sonnet | médio | manter | Remoção de código morto; mecânico o suficiente para sonnet. |
| rls-reviewer | sonnet | médio | manter | Checklist RLS; segue regras fixas — sonnet adequado. |
| typescript-reviewer | sonnet | médio | manter | Review TS padrão. Com LSP adotado, pode ser mantido em sonnet com mais precisão semântica. |
| pr-test-analyzer | sonnet | médio | manter | Análise de cobertura de testes; sonnet cobre análise estrutural de PR. |
| performance-optimizer | sonnet | médio | avaliar downgrade para haiku | Segue processo checklist (N+1, bundle, loop quente); pouca decisão aberta. Candidato a haiku se benchmarkado. |
| planner | opus | alto | manter | Planejamento estrutural ad-hoc; decisão de arquitetura — opus justificado. |
| silent-failure-hunter | opus | alto | avaliar downgrade para sonnet | Segue grep patterns fixos (catch vazio, promise sem await). A maioria dos casos é mecânico. Testar sonnet — potencial economia de ~5x por invocação. |
| security-reviewer | opus | alto | manter | Julgamento de vulnerabilidade requer raciocínio profundo; falso negativo tem custo alto. Opus justificado. |

**Resumo de flags:**
- 2 agents sem `model:` explícito (claude-continuation, ideiaos-checker) — risco de regressão quando o padrão do harness muda.
- 1 candidato a downgrade forte: silent-failure-hunter (sonnet em vez de opus).
- 1 candidato a downgrade leve: performance-optimizer (haiku em vez de sonnet, sujeito a benchmark).

---

## Overhead de Hooks

| Hook | Evento | Frequência | Overhead | Justificado? |
|------|--------|------------|----------|--------------|
| typecheck-on-edit.sh | PostToolUse (Edit ou Write .ts/.tsx) | Por edição TS/TSX; async com asyncRewake | Médio — subprocess tsc --noEmit incremental; silencioso em arquivos não-TS | Sim — feedback imediato de tipo evita ciclos de debug. Async mitiga bloqueio. |
| console-log-guard.sh | PostToolUse (Edit ou Write JS/TS) | Por edição JS/TS | Leve — grep no arquivo + python3 para JSON | Sim — custo baixo, previne console.log em produção Lovable. |
| precompact-state-save.sh | PreCompact | Apenas no /compact (raro) | Leve — leitura e reescrita de STATE.md via python3 | Sim — garante snapshot antes de compactar histórico. |
| session-summary.sh | Stop | Por turno de stop | Médio — leitura de transcript JSONL + escrita de arquivo | Sim — saída puramente local (sem JSON, sem decision:block); custo pós-turno aceitável. |
| strategic-compact.sh | PreToolUse (sem matcher) | Toda chamada de ferramenta | Leve-a-médio — subprocess python3 + I/O de arquivo /tmp por chamada | Condicional — disparo em toda ferramenta é a frequência mais alta do conjunto. Justificado pelo propósito (lembrete de /compact a cada 50 calls), mas python3 em loop quente merece atenção. |
| observe-tool-use.sh | PostToolUse (sem matcher) | Toda chamada de ferramenta | Leve — python3 parse + append em JSONL local | Sim — coleta apenas metadados (bash_verb = 1º token), sem conteúdo. Fail-silent, exit 0. |
| observe-session-end.sh | Stop | Por turno de stop | Muito leve — apenas append de marcador JSONL | Sim — custo mínimo, marca boundary de sessão para /instinct-analyze. |
| extract-learnings-reminder.sh | PostToolUse (Edit/Write/Bash) | Por commit git, qa-gate PASS, ou VERIFICATION.md com sucesso | Leve — grep em conteúdo + injeção de additionalContext | Sim — dispara apenas em gatilhos específicos, não em toda edição. Custo justificado. |
| ideiaos-readme-reminder.sh | PostToolUse (Edit/Write) | Por edição em hooks/, skills/, agents/ do repo IdeiaOS | Muito leve — grep de path + cat de JSON inline | Sim — path guard específico, não dispara em projetos-alvo normais. |
| deia-trigger.sh | PostToolUse | Por commit git e gatilhos de qualidade | Leve | Sim — gate triplo de extract-learnings; gatilho condicionado a AGENTS.md e padrões específicos. |
| ideiaos-detector.sh | (a inspecionar) | — | — | Não inspecionado diretamente — ausente na lista de hooks com evento explícito documentado. |

**Hot hooks identificados:** `strategic-compact` e `observe-tool-use` disparam em **toda** chamada de ferramenta (PreToolUse/PostToolUse sem matcher). São os únicos dois hooks com frequência irrestrita. Para sessions longas (>200 tool calls), seu overhead acumulado pode ser medido — strategic-compact em particular invoca python3 + I/O de /tmp a cada chamada.

**Mitigação proposta:** strategic-compact pode usar um contador bash puro (increment em variável de ambiente ou /tmp/counter via `echo N > file`) sem invocar python3 a cada chamada — reduz overhead de ~5 ms para ~0,5 ms por disparo.

---

## Subagent: Spawn vs Inline

### Regra geral

Spawn um subagente quando **pelo menos dois** dos seguintes forem verdadeiros:

1. A tarefa consome >50% do contexto útil da sessão principal (exploração ampla, leitura de muitos arquivos).
2. O resultado pode ser descartado após resumo (janela fresca tem valor).
3. O subagente opera em modo somente-leitura ou em escopo de arquivo isolado.
4. O modelo ideal para a subtarefa é diferente do modelo da sessão principal.

**Inline** quando: a subtarefa é pequena (<10 arquivos, <5 min de trabalho), compartilha contexto já carregado, ou a latência de spawn seria maior que a economia de contexto.

### Casos trabalhados

**Caso 1 — code-explorer (haiku) como subagente de busca**
Spawn justificado. O explorador lê dezenas de arquivos para responder "onde está X". A janela fresca do haiku evita contaminar o contexto da sessão principal com conteúdo irrelevante. Custo de spawn (system prompt overhead) é baixo porque haiku é o modelo mais barato e o resultado é compacto (mapa de símbolos, não conteúdo completo).

**Caso 2 — security-reviewer (opus) como subagente pré-merge**
Spawn justificado. A revisão de segurança opera em isolamento intencional: sem ver o contexto de implementação da sessão principal, o opus avalia o diff com olhar limpo. Evita viés de confirmação. O overhead de spawn (opus system prompt) é proporcional ao valor — um false negative em segurança tem custo maior que o spawn.

**Caso 3 — doc-updater (haiku) após feature estabilizada**
Inline preferível. O doc-updater precisa saber o que mudou — contexto já está na sessão. Spawn desperdiçaria tokens re-carregando contexto que o agente principal já tem. Executar inline com instrução explícita do que atualizar é mais eficiente.

**Caso 4 — silent-failure-hunter em codebase nova**
Spawn justificado. O hunter faz grep extensivo em toda a codebase. Em projetos grandes, contamina a sessão principal com centenas de matches. Spawn + resumo compacto é a abordagem correta. (Nota: candidato a downgrade para sonnet — ver matriz.)

---

## Decisao Final: mgrep + LSP

### mgrep — ADIAR

**Disposição:** adiar

**Raciocínio:** A alegação de -50% tokens em comparação com grep tradicional é baseada em marketing da ferramenta, sem benchmark medido no contexto IdeiaOS. O beneficiário principal seria code-explorer (haiku), que já é o modelo mais barato do conjunto. Mesmo que a redução de tokens seja real, a economia marginal por busca em haiku não justifica a dependência adicional e o risco de compatibilidade.

**Trigger para re-avaliar:** Benchmark controlado no contexto IdeiaOS confirmando >30% de redução no tamanho do output de grep em buscas típicas do code-explorer (símbolos, referências, imports). Medir com: `grep -r "pattern" src/ | wc -c` vs `mgrep "pattern" src/ | wc -c` em 10 buscas reais, média.

**O que mudaria a decisão para adotar:** Resultado >30% confirmado + mgrep disponível via `npm install -g` sem dependências nativas problemáticas + suporte a `.gitignore` por default.

**O que manteria a decisão de adiar:** Resultado <30% ou instalação que requer binário nativo/build step.

### typescript-lsp — ADOTAR (sob demanda)

**Disposição:** adotar com `installStrategy: stack:typescript`

**Raciocínio:** O ecossistema Ideia Business é predominantemente TypeScript (NFideia, IdeiaPartner, Lovable — todos TypeScript/Next.js). Os beneficiários diretos já existem no manifesto: code-explorer (find-references semântico substitui grep + read múltiplos), typescript-reviewer (hover types), refactor-cleaner (rename-symbol seguro), silent-failure-hunter (rastrear retornos ignorados).

A adoção não é global: `installStrategy: stack:typescript` garante instalação apenas em projetos com `typescript` detectado por `detect_stack()`. Não infla o setup de projetos Python ou genéricos.

**Trigger de ativação:** Projeto com >10k LOC TypeScript ou presença de `tsconfig.json`. O `detect_stack()` já detecta `typescript` — basta adicionar typescript-lsp ao manifesto com esse guard.

**Configuração por projeto:** O LSP requer path para `tsconfig.json`. Padronizar no setup.sh: `$(find . -name tsconfig.json -maxdepth 2 | head -1)`.

### pyright-lsp — ADIAR

**Disposição:** adiar

**Raciocínio:** O ecossistema Ideia Business atual não tem projetos Python ativos significativos (>50k LOC Python) que justifiquem o overhead de setup. O principal projeto Python seria eventual — o benefício é especulativo. Adição prematura aumenta complexidade de onboarding sem retorno imediato.

**Trigger para re-avaliar:** Projeto Python ativo no ecossistema com >20k LOC Python e necessidade recorrente de navegação semântica (find-refs, rename-symbol). Reavaliar na Fase 09 se houver projeto Python novo.

---

## Oportunidades de Reducao

Ranqueadas por impacto estimado (alto/médio/baixo) e facilidade de execução (fácil/médio/difícil).

| # | Oportunidade | Impacto | Facilidade | Detalhe |
|---|-------------|---------|------------|---------|
| 1 | **Pinnar model: nos 2 agents sem frontmatter** (claude-continuation, ideiaos-checker) | Médio | Fácil | Adicionar `model: sonnet` evita dependência do default do harness e documenta a intenção. Custo zero, risco zero. |
| 2 | **Adotar typescript-lsp (stack:typescript)** | Alto | Médio | find-references semântico em code-explorer reduz leitura de múltiplos arquivos para rastrear uso de símbolo. Economia estimada: 3-8 arquivos por tarefa de navegação em projetos TS grandes. |
| 3 | **Downgrade silent-failure-hunter: opus → sonnet** | Alto | Fácil | O processo é grep patterns fixos — 90% dos casos não requer raciocínio aberto. Economia: ~5x por invocação de opus. Testar: rodar 3 casos reais com sonnet e comparar completude dos achados. |
| 4 | **Otimizar strategic-compact: python3 → bash puro para contador** | Médio | Fácil | Substituir subprocess python3 + I/O de arquivo JSON por `echo N` em /tmp. Reduz overhead de ~5ms para ~0,5ms por chamada de ferramenta. Em sessão com 200 calls: ~900ms economizados. |
| 5 | **Contexts via --append-system-prompt (não CLAUDE.md)** | Alto | Médio | Já implementado em 07-01. Garantir que os modos dev/review/research NÃO sejam incluídos no CLAUDE.md global — devem ser injetados somente quando explicitamente solicitados. CLAUDE.md deve permanecer lean (instruções de projeto, não postura de sessão). |
| 6 | **Downgrade performance-optimizer: sonnet → haiku (avaliado)** | Baixo-Médio | Médio | O processo segue checklist (N+1, bundle, loop quente) com pouca decisão aberta. Benchmark: comparar qualidade dos achados em haiku vs sonnet em 3 casos reais. Potencial economia: 5-8x por invocação se downgrade confirmado. |
| 7 | **Trim de tools grant por agent** | Médio | Médio | code-explorer, typescript-reviewer, react-reviewer têm apenas Read/Grep/Glob (correto — somente leitura). Verificar se agents com Edit/Bash (refactor-cleaner, build-error-resolver) precisam de todos os tools listados, ou se um subconjunto menor reduce attack surface e context loading. |
| 8 | **Manifests-driven install: evitar módulos não-utilizados no setup** | Médio | Fácil | O `setup.sh` com `detect_stack()` já aplica instalação seletiva. Garantir que `installStrategy: manual` está nos módulos de nicho (llms-txt, mcp-to-cli, two-instance-kickoff) e que não migram para `always` por erro de edição. Auditoria periódica de modules.json. |

---

## Referências Inspecionadas

- `source/agents/*.md` — 15 arquivos, campo `model:` confirmado em 13/15
- `source/hooks/` — 11 hooks inspecionados, eventos e overhead caracterizados
- `source/contexts/` — 3 contextos de modo (dev, review, research) via --append-system-prompt
- `docs/decisions/mgrep-lsp-evaluation.md` — decisão Phase 04 fechada nesta revisão
- `source/rules/common/token-economy.md` — regras existentes (esta matriz é a extensão operacional)
- `.planning/STATE.md` — decisões 07-01 (--append-system-prompt), 04-04 (mgrep/LSP candidatos)
