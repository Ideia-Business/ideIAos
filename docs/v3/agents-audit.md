# SOURCE: IdeiaOS v2

Auditoria dos 15 agents em `source/agents/` para readiness v3.
Data: 2026-06-12. Auditor: 08-01-PLAN executor.

---

## Resumo

A camada de agents do IdeiaOS v2 é funcionalmente sólida: a maioria tem role claro, passo a passo acionável e tools adequadas para o trabalho declarado. Os dois problemas transversais mais graves são (1) dois agents sem campo `model:` no frontmatter (`claude-continuation` e `ideiaos-checker`/`setup-checker`), o que os deixa rodando no default do harness sem garantia de custo ou capacidade, e (2) uma inconsistência de nome entre filename e campo `name:` no `ideiaos-checker.md` (arquivo = `ideiaos-checker`, `name:` = `setup-checker`). Resultado: **7 OK, 6 AJUSTAR, 2 RETRABALHAR**.

---

## Auditoria por Agente

### build-error-resolver

**Role:** Resolve erros de build/compilação/teste (tsc, vite, jest, lint) lendo o output e corrigindo a causa raiz.
Clareza: alta. Role não se sobrepõe com outro agente — o foco em "build quebrado" é bem delimitado.

**Model:** `sonnet` — correto. O trabalho envolve leitura de erros, mapeamento de causa e edição de arquivos. Sonnet é o modelo adequado para raciocínio de causa raiz com Edit/Bash. A sugestão interna de escalar para opus após 1ª tentativa fracassada é um mecanismo de fallback bem desenhado.

**Tools:** Read, Grep, Glob, Edit, Bash — minimal e completo. Bash é necessário para re-rodar o build. Sem over-grant.

**Quando usar:**
- `tsc`/`vite build`/`jest`/`eslint` falhando em CI ou local.
- CI vermelho por erro de compilação ou de tipo.

**Quando NÃO usar:**
- Bug de runtime sem erro de build (use `silent-failure-hunter`).
- Lentidão de performance sem build quebrado (use `performance-optimizer`).

**Passo a passo:** Directedness **High**. Quatro passos claros: rodar o comando, mapear erro→arquivo:linha→causa, corrigir a causa, re-rodar. A instrução "primeira ocorrência manda" é concreta. Ponto mais fraco: o passo 3 diz "corrigir a causa, não silenciar" mas não especifica o que verificar se a causa for externa (ex.: versão de dependência incompatível vs. erro de tipo local) — deixa espaço de interpretação.

**Veredito: OK**

---

### claude-continuation

**Role:** Continua trabalho iniciado no Claude Code lendo memórias e sessões JSONL, recuperando contexto entre Claude Code e Cursor.
Clareza: alta. O role é específico e o par bidirecional com `cursor-continuation` está documentado.

**Model:** **NENHUM declarado** — gap real. O agent executa leitura intensiva de múltiplos arquivos (JSONL potencialmente grandes, múltiplos `.md`), síntese e possivelmente execução de comandos git. Sem `model:`, o harness usará o default do ambiente (geralmente haiku ou o padrão global) — insuficiente para um agent que precisa de raciocínio de síntese sobre contexto extenso.
**Recomendação:** declarar `model: sonnet`. O trabalho é síntese contextual, não alta-stakes — sonnet é suficiente e mais barato que opus.

**Tools:** Nenhuma declarada no frontmatter. O agent, contudo, usa `tail`/`Grep`/`Read`/`Bash` implicitamente no corpo (Fase 4: `git log`, Fase 6: `tail`). A ausência do campo `tools:` significa que as ferramentas disponíveis dependem do contexto de invocação, não do contrato do agent.
**Recomendação:** declarar `tools: Read, Grep, Glob, Bash`.

**Quando usar:**
- Retomar trabalho de sessão anterior do Claude Code no Cursor.
- Usuário pede "continua onde parei", "dá seguimento ao plano da Phase X".

**Quando NÃO usar:**
- Projeto sem `.planning/` nem histórico Claude Code (não há contexto para recuperar).
- Tarefa nova sem relação com sessão anterior.

**Passo a passo:** Directedness **High**. Sete fases bem ordenadas com sub-passos numerados. O formato de output (Resumo/Estado/Decisões/Próximo passo) é preciso. Ponto mais fraco: Fase 6 instrui a usar `tail` via shell mas o agent não tem `Bash` declarado no frontmatter — contradição entre corpo e contrato.

**Veredito: AJUSTAR** (adicionar `model: sonnet` e `tools: Read, Grep, Glob, Bash`)

---

### code-explorer

**Role:** Explora a codebase para responder "onde está X / como Y funciona / quem chama Z" sem modificar nada.
Clareza: alta. "NÃO modifica arquivos" está explícito.

**Model:** `haiku` — correto. Trabalho é busca repetitiva e navegação. Haiku é a escolha certa para minimizar custo em operações de Read/Grep/Glob sem raciocínio complexo.

**Tools:** Read, Grep, Glob — minimal e exato para role read-only. Sem over-grant, sem under-grant.

**Quando usar:**
- Início de tarefa em área desconhecida do código.
- Perguntas "onde fica...", "quem usa...", "como flui...".

**Quando NÃO usar:**
- Local já conhecido — ir direto sem este agent.
- Necessidade de editar — `code-explorer` não tem Edit (use `code-simplifier` ou `refactor-cleaner`).

**Passo a passo:** Directedness **High**. Quatro passos sequenciais (Glob → Grep → Read seletivo → montar mapa) com formato de output estruturado. Ponto mais fraco: o passo "Glob para mapear estrutura relevante" não especifica critério de relevância — um executor novo pode Glob a codebase inteira. Poderia ser "Glob no subdiretório mais provável primeiro".

**Veredito: OK**

---

### code-simplifier

**Role:** Simplifica código complexo sem mudar comportamento — reduz aninhamento, remove indireção desnecessária, melhora nomes.
Clareza: alta. A restrição "sem mudar comportamento" e "testes verdes antes e depois" são critérios objetivos.

**Model:** `sonnet` — correto. Simplificação exige entendimento do comportamento atual e julgamento sobre o que é "indireção desnecessária". Sonnet é adequado; haiku subestimaria a complexidade de raciocínio sobre equivalência semântica.

**Tools:** Read, Grep, Glob, Edit, Bash — completo e justificado. Bash é necessário para rodar testes antes e depois. Sem over-grant.

**Quando usar:**
- Função longa/aninhada difícil de ler, nomes ruins, indireção sem ganho.
- Após uma feature estabilizar (não durante desenvolvimento ativo).

**Quando NÃO usar:**
- Código que precisa de feature nova (simplificação não adiciona funcionalidade).
- Sem cobertura de testes — o agent diz explicitamente "primeiro garantir rede de segurança".

**Passo a passo:** Directedness **High**. Quatro passos claros com a regra anti-abstração explícita ("NÃO introduzir abstração nova por elegância"). Ponto mais fraco: o passo 2 lista técnicas (early returns, extração de função, etc.) mas não prioriza — um executor pode aplicar todas de uma vez, aumentando risco de regressão.

**Veredito: OK**

---

### doc-updater

**Role:** Atualiza documentação (README, comentários de WHY, CHANGELOG) para refletir mudanças de código recém-feitas.
Clareza: alta. O escopo "só o que ficou desatualizado — não reescrever" é uma restrição de escopo clara.

**Model:** `haiku` — correto. Trabalho mecânico de identificar docs afetados e aplicar mudanças pontuais. Não exige raciocínio complexo de causa raiz. Haiku é a escolha certa para custo.

**Tools:** Read, Grep, Glob, Edit — correto e minimal. Bash não é necessário (nenhuma execução de comando). Sem over-grant.

**Quando usar:**
- Após mudança que afeta interface pública, setup ou comportamento documentado.

**Quando NÃO usar:**
- Mudança interna sem reflexo em docs (ex.: refactor interno de função privada).
- Criar documentação nova do zero (este agent atualiza, não cria).

**Passo a passo:** Directedness **Medium**. Os quatro passos são corretos, mas o passo 2 ("Localizar docs afetados") é vago: não especifica como decidir quais arquivos são "afetados". Para um caso com muitos docs (STATE.md, README, CHANGELOG, JSDoc), o executor precisa adivinhar a prioridade. Ponto mais fraco: ausência de critério de prioridade entre arquivos de doc.

**Veredito: AJUSTAR** (adicionar critério de prioridade no passo 2: ex. "priorizar README > CHANGELOG > JSDoc > STATE.md para mudanças de API")

---

### ideiaos-checker

**Role:** Verifica e completa o setup do IdeiaOS em um projeto — manifesto, AIOX, GSD, Lovable, Fase A, Cursor rules, hooks.
Clareza: media. Há um problema de identidade: o **filename** é `ideiaos-checker.md` mas o campo `name:` no frontmatter é `setup-checker`. Esta inconsistência entre filename e `name:` quebra rastreabilidade em manifests e instalação automatizada (modules.json referencia por `name:`).

**Model:** **NENHUM declarado** — gap real. O agent executa scripts bash de diagnóstico, lê múltiplos arquivos de setup e potencialmente roda `setup.sh`. É trabalho estruturado com execução de comandos.
**Recomendação:** declarar `model: sonnet`. O diagnóstico e decisão de aplicar setup exige mais que haiku; não é segurança crítica que exija opus.

**Tools:** Nenhuma declarada no frontmatter. O corpo usa scripts bash explicitamente (Passo 2 tem bloco bash com `check()`, Passo 3 roda `setup.sh`). A ausência de `tools:` é um gap funcional.
**Recomendação:** declarar `tools: Read, Bash`.

**Quando usar:**
- Início de trabalho em projeto novo ou repo clonado freshly.
- Suspeita de setup IdeiaOS incompleto.

**Quando NÃO usar:**
- Projeto claramente não-IdeiaOS (lib pública, etc.).
- Setup já verificado nesta sessão (idempotente, mas consome tempo desnecessariamente).
- Usuário pediu tarefa específica — não interromper fluxo.

**Passo a passo:** Directedness **High**. Cinco passos bem definidos com scripts bash detalhados. O Passo 2 tem até uma função `check()` reutilizável. Ponto mais fraco: o Passo 3 pergunta confirmação ao usuário antes de aplicar — quebrando autonomia do agent em modo agentic. Em v3, considerar flag `--auto-apply` para evitar interrupção.

**Veredito: RETRABALHAR** (corrigir `name:` para `ideiaos-checker` OU renomear arquivo para `setup-checker.md` — escolher um; adicionar `model: sonnet`; adicionar `tools: Read, Bash`)

---

### performance-optimizer

**Role:** Otimiza performance medida — identifica gargalos (renders, queries N+1, bundles, loops quentes) a partir de evidência, não palpite.
Clareza: alta. A distinção "mede antes de mudar" é um princípio operacional claro.

**Model:** `sonnet` — correto. O trabalho envolve leitura de código, identificação de padrões (N+1, re-renders), edição e re-medição. Não é raciocínio de alta-stakes que justifique opus; haiku seria insuficiente para o julgamento de causa de gargalo.

**Tools:** Read, Grep, Glob, Edit, Bash — completo e justificado. Bash é necessário para rodar benchmarks e re-medir. Sem over-grant.

**Quando usar:**
- Sintoma concreto de lentidão com número mensurável (tempo de carga, query lenta, bundle size).

**Quando NÃO usar:**
- "Pode estar lento" sem medida — usar `/benchmark-optimization-loop` primeiro.
- Otimização prematura sem evidência de problema real.

**Passo a passo:** Directedness **Medium**. O processo de 4 passos é correto, mas o passo 2 ("Localizar o gargalo real: N+1, re-render React, loop quente, bundle") lista categorias sem dar metodologia de triagem — o executor não sabe por qual começar. Ponto mais fraco: sem ordem de prioridade entre tipos de gargalo ou critério de escolha.

**Veredito: AJUSTAR** (adicionar no passo 2 uma ordem de investigação: ex. "queries primeiro (impacto maior), depois bundle, depois renders")

---

### planner

**Role:** Quebra uma tarefa ampla em passos executáveis com dependências e ordem, antes de qualquer implementação (planejamento leve ad-hoc).
Clareza: alta. A distinção "planejamento ad-hoc vs. `/gsd-plan-phase` para fases formais" está explícita na descrição.

**Model:** `opus` — justificado. Planejamento é decisão estrutural que afeta toda a execução subsequente. Um plano mal feito com haiku ou sonnet gera retrabalho em todas as etapas. Opus para o planner é o uso mais defensável de um modelo caro.

**Tools:** Read, Grep, Glob — correto para planejamento. O planner não implementa; só lê para entender o contexto. Sem over-grant. Edit/Bash seriam over-grant aqui.

**Quando usar:**
- Tarefa grande/ambígua, múltiplos subsistemas, antes de começar a implementar.

**Quando NÃO usar:**
- Fase formal do roadmap (usar `/gsd-plan-phase`).
- Tarefa trivial de 1 arquivo — ir direto.

**Passo a passo:** Directedness **High**. Quatro passos com técnica nomeada (goal-backward), formato de output estruturado com `needs`/`creates`. "Não implementa — devolve o plano para execução" é uma restrição clara. Ponto mais fraco: o passo "Apontar riscos" não tem critério mínimo — o executor pode listar zero riscos sem violar o contrato.

**Veredito: OK**

---

### pr-test-analyzer

**Role:** Analisa um PR/diff e identifica lacunas de teste — caminhos novos sem cobertura, edge cases não testados, regressões prováveis.
Clareza: alta. O foco "avalia se os testes acompanham o risco do diff" delimita bem o que este agent faz vs. o que não faz (não escreve testes, não revisa código).

**Model:** `sonnet` — correto. A análise de cobertura de risco de um diff exige raciocínio sobre ramificações lógicas, o que está acima do haiku. Não é decisão de segurança que exija opus. Sonnet é adequado.

**Tools:** Read, Grep, Glob, Bash — correto. Bash é necessário para listar arquivos do diff ou rodar cobertura. Sem Edit (corretamente — o agent analisa, não corrige). Sem over-grant.

**Quando usar:**
- Antes de aprovar PR com lógica nova não-trivial.

**Quando NÃO usar:**
- PR de apenas docs/config/estilo (sem lógica nova).

**Passo a passo:** Directedness **High**. Quatro perguntas específicas e checáveis (branches cobertos? edge cases? mocks sem valor?). O formato de output tem tabela estruturada com recomendação binária. Ponto mais fraco: o passo 1 diz "listar arquivos de produção vs. teste alterados" mas não especifica como obter o diff (git diff HEAD~1? diff da branch? PR URL?) — deixa a mecânica de entrada indefinida.

**Veredito: OK**

---

### react-reviewer

**Role:** Revisa componentes React quanto a regras de hooks, padrões de componente, re-renders desnecessários e over-engineering.
Clareza: alta. A referência a `source/rules/ecc/react/react.md` ancora o agente em regras concretas.

**Model:** `sonnet` — correto para o papel de revisor. Embora as tools sejam read-only (Read, Grep, Glob), a análise de padrões React (Rules of Hooks, re-render analysis, over-engineering) exige raciocínio semântico acima do haiku. A comparação com `typescript-reviewer` (mesmo modelo, mesma toolset) é consistente.

**Tools:** Read, Grep, Glob — minimal e correto para role de revisão sem edição. A ausência de Edit é intencional e correta — o revisor aponta, não corrige. Sem over-grant.

**Quando usar:**
- PR/diff com componentes React, hooks customizados, arquivos `.tsx`.

**Quando NÃO usar:**
- Lógica não-React (utils puros — usar `typescript-reviewer`).
- Revisão de performance de renders (usar `performance-optimizer` que tem Bash para medir).

**Passo a passo:** Directedness **High**. Cinco checklist items concretos (Rules of Hooks, estado derivado, props instáveis, over-engineering, acessibilidade). Cada item é verificável. Formato de output com tabela e veredito binário. Ponto mais fraco: o passo 5 ("Acessibilidade básica") é o mais vago — "elementos interativos com role/label?" é pouco específico para um executor saber o que exatamente verificar.

**Veredito: OK**

---

### refactor-cleaner

**Role:** Limpa código morto, imports não usados, duplicação e TODOs resolvidos após uma feature estabilizar.
Clareza: alta. "Remove o que sobrou sem alterar comportamento" é uma restrição clara.

**Model:** `sonnet` — correto. A limpeza de código morto e duplicação exige entendimento semântico (é este import realmente não usado em nenhum path de execução?). Haiku pode cometer falsos positivos. Opus seria over-kill para trabalho mecânico de limpeza.

**Tools:** Read, Grep, Glob, Edit, Bash — completo e justificado. Bash é necessário para confirmar build/testes verdes após remoções. Sem over-grant.

**Quando usar:**
- Fim de ciclo de feature, antes do merge.
- Após simplificação para varrer resíduos.

**Quando NÃO usar:**
- Durante desenvolvimento ativo (código ainda em fluxo pode ter "dead code" intencional).

**Passo a passo:** Directedness **High**. Cinco categorias sequenciais (código morto → imports → duplicação → TODOs → build/testes). A sequência é lógica (progressiva, do mais óbvio para o mais arriscado). Ponto mais fraco: o passo 3 ("Duplicação extraível — mas sem over-abstrair") não dá critério para decidir quando duplicação deve ser extraída vs. deixada — contradição potencial com `code-simplifier` que também cobre duplicação.

**Veredito: AJUSTAR** (adicionar critério mínimo para extração de duplicação: ex. "≥3 ocorrências idênticas ou quase-idênticas")

---

### rls-reviewer

**Role:** Revisa schema/migrations Supabase quanto a Row Level Security — RLS habilitada, policies corretas, service_role isolado.
Clareza: alta. A fusão "database-reviewer ECC + checklist RLS do vault" está bem descrita. Escopo Supabase é explícito.

**Model:** `sonnet` — discutível. RLS malconfigurada é uma falha de segurança séria (exposição de dados de todos os usuários). O checklist inclui itens bloqueantes de segurança. Sonnet pode ser justificado pelo fato de que o checklist é mecânico e estruturado (6 items checáveis), mas há argumento para opus dado o impacto. Mantendo sonnet: o checklist é determinístico o suficiente para não exigir opus, desde que todos os 6 items sejam verificados.

**Tools:** Read, Grep, Glob, Bash — correto. Bash é necessário para o `grep` no diff. Sem Edit (corretamente — o revisor não aplica correções automáticas em migrations). Sem over-grant.

**Quando usar:**
- Antes de `supabase db push` ou aplicar qualquer migration.
- Toda tabela/policy nova ou alterada.

**Quando NÃO usar:**
- Mudança sem DDL nem policy (ex.: mudança só de dados ou configuração sem schema change).

**Passo a passo:** Directedness **High**. Checklist de 6 items com exemplos concretos de violação (ex: `USING (true)` em prod, `service_role` em client-side). O comando grep para localizar DDL está inline. Formato de output com tabela e veredito BLOQUEAR/APROVAR-COM-RESSALVA/LIMPO. Ponto mais fraco: o passo 3 menciona "gotchas: realtime publicando colunas sensíveis" mas não explica como verificar isso — fica vago para um executor não familiar com Supabase realtime.

**Veredito: AJUSTAR** (adicionar instrução concreta para verificar realtime: ex. "checar `supabase/config.toml` para tabelas em `[realtime]` com colunas sensíveis")

---

### security-reviewer

**Role:** Revisa código em busca de vulnerabilidades (injection, secrets vazados, authz quebrada, deps inseguras).
Clareza: alta. A lista de gatilhos ("auth/authz, input do usuário, env/secrets, SQL/queries, integrações externas") delimita o escopo sem ambiguidade.

**Model:** `opus` — correto e bem justificado. Segurança é decisão de alto impacto: um falso negativo (vulnerabilidade não detectada) pode ter consequências sérias. O processo STRIDE leve exige raciocínio sobre trust boundaries que beneficia do modelo mais capaz. Dentre os três agentes em opus (planner, security-reviewer, silent-failure-hunter), este é o de justificativa mais forte.

**Tools:** Read, Grep, Glob, Bash — correto. Bash é necessário para rodar `grep` em patterns de segurança. Sem Edit (o revisor aponta, não corrige automaticamente vulnerabilidades). Sem over-grant.

**Quando usar:**
- Antes de merge de código tocando auth, input de usuário, env/secrets, queries, integrações externas.
- Após absorver conteúdo de terceiros.

**Quando NÃO usar:**
- Refactor puro sem mudança de superfície de ataque.
- Mudança só de UI/estilo sem lógica de dados.

**Passo a passo:** Directedness **High**. Processo STRIDE leve com 4 categorias explícitas (Injection, Secrets, AuthZ, Deps, Exposure) e exemplos concretos ("ANTHROPIC_BASE_URL", "`curl|bash`"). Formato de output com arquivo:linha obrigatório e mitigação específica. Ponto mais fraco: o passo de "Deps" menciona dependência nova conhecida-vulnerável mas não especifica ferramenta (npm audit? snyk?) nem como verificar se é conhecida.

**Veredito: AJUSTAR** (adicionar instrução para checagem de deps: ex. "rodar `npm audit --audit-level=high` ou checar CVE da dep em advisories")

---

### silent-failure-hunter

**Role:** Caça falhas silenciosas — erros engolidos, promises sem await, retornos ignorados, fallbacks que mascaram bugs.
Clareza: alta. "Procura onde o sistema falha SEM gritar" é uma frase de role memorável e precisa.

**Model:** `opus` — justificado. Diagnosticar falhas silenciosas exige raciocínio sobre fluxo assíncrono, tratamento de erros e consequências de ausência de dado — contexto complexo onde haiku/sonnet podem perder nuances. O impacto de um falso negativo (falha silenciosa não detectada = bug intermitente em produção) justifica o custo.

**Tools:** Read, Grep, Glob, Bash — correto. Bash é necessário para os `grep` dos padrões (catch vazio, etc.). Os comandos grep estão inline no corpo, o que é bom. Sem Edit. Sem over-grant.

**Quando usar:**
- "Funciona mas o resultado está errado/vazio".
- Bug intermitente sem stack trace, após incidente sem erro logado.

**Quando NÃO usar:**
- Erro com stack trace claro — debugar diretamente, sem precisar deste agent.

**Passo a passo:** Directedness **High**. Seis padrões específicos com `grep` commands inline — executável diretamente. A inclusão de Supabase como caso especial (`.error` de query não checado) é valiosa para o contexto IdeiaOS. Ponto mais fraco: o passo 5 ("try largo demais escondendo qual linha falhou") não tem `grep` command correspondente — os outros 5 têm, este não.

**Veredito: AJUSTAR** (adicionar grep para try largo: ex. `grep -n "try {" + medir linhas até o catch correspondente`)

---

### typescript-reviewer

**Role:** Revisa código TypeScript quanto a type-safety, uso correto do sistema de tipos e anti-patterns (any, asserts inseguras, generics frágeis).
Clareza: alta. A referência a `source/rules/ecc/typescript/typescript.md` ancora em regras concretas.

**Model:** `sonnet` — correto. Revisão de TypeScript exige entendimento de generics, discriminated unions e narrowing — acima de haiku. Não é decisão de segurança que exija opus. Consistente com `react-reviewer` (mesmo modelo, mesma toolset).

**Tools:** Read, Grep, Glob — minimal e correto. Read-only é adequado para um revisor que aponta mas não corrige. Sem Edit/Bash. Sem over-grant.

**Quando usar:**
- PR/diff tocando `.ts`/`.tsx`.
- Código novo com tipos complexos (generics, discriminated unions).

**Quando NÃO usar:**
- JS puro sem tipos.
- Mudança só de estilo/formatação (deixar pro linter/formatter).

**Passo a passo:** Directedness **High**. Seis items específicos e checáveis (`any`/`as`, non-null `!`, optional vs `undefined`, generics ruins, `import type`, Supabase types). O item Supabase ("tipos importados de `@/integrations/supabase/types`") é uma regra IdeiaOS-específica bem integrada. Ponto mais fraco: o item 3 ("Optional vs `undefined`: consistência") é o mais vago — não diz qual padrão é preferido quando há inconsistência.

**Veredito: OK**

---

## Tabela Final

| Agente | Model atual | Model recomendado | Tools OK? | Directedness | Veredito |
|--------|-------------|-------------------|-----------|--------------|----------|
| build-error-resolver | sonnet | sonnet | Sim | High | OK |
| claude-continuation | NENHUM | sonnet | Nao (falta `tools:`) | High | AJUSTAR |
| code-explorer | haiku | haiku | Sim | High | OK |
| code-simplifier | sonnet | sonnet | Sim | High | OK |
| doc-updater | haiku | haiku | Sim | Medium | AJUSTAR |
| ideiaos-checker | NENHUM | sonnet | Nao (falta `tools:`) | High | RETRABALHAR |
| performance-optimizer | sonnet | sonnet | Sim | Medium | AJUSTAR |
| planner | opus | opus | Sim | High | OK |
| pr-test-analyzer | sonnet | sonnet | Sim | High | OK |
| react-reviewer | sonnet | sonnet | Sim | High | OK |
| refactor-cleaner | sonnet | sonnet | Sim | High | AJUSTAR |
| rls-reviewer | sonnet | sonnet | Sim | High | AJUSTAR |
| security-reviewer | opus | opus | Sim | High | AJUSTAR |
| silent-failure-hunter | opus | opus | Sim | High | AJUSTAR |
| typescript-reviewer | sonnet | sonnet | Sim | High | OK |

---

## Gaps Identificados

**Gap 1 — Dois agents sem `model:` declarado (bloqueante para v3)**
- `claude-continuation`: sem `model:`, sem `tools:`. Agent complexo rodando em default do harness.
- `ideiaos-checker` (name: `setup-checker`): sem `model:`, sem `tools:`. Usa bash extensivamente no corpo sem declarar Bash no frontmatter.
- Impacto: custo imprevisível, capacidade de raciocínio não garantida, contrato de ferramentas indefinido.
- **(corrigido na Fase 09)** `claude-continuation` recebeu `model: sonnet` e `tools: Read, Grep, Glob, Bash`; `ideiaos-checker` recebeu `model: sonnet` e `tools: Read, Bash`.

**Gap 2 — Inconsistência de nome: ideiaos-checker.md vs. `name: setup-checker`**
- O arquivo se chama `ideiaos-checker.md` mas o campo `name:` no frontmatter é `setup-checker`.
- `manifests/modules.json` referencia por `name:`, então o agent é indexado como `setup-checker` mas instalado de `ideiaos-checker.md` — rastreabilidade quebrada.
- Ação: decidir nome canônico e alinhar filename + `name:` + modules.json.
- **(corrigido na Fase 09)** Nome canônico `ideiaos-checker` adotado; frontmatter, setup.sh e plugins alinhados.

**Gap 3 — Tools implícitas no corpo sem declaração no frontmatter**
- `claude-continuation`: usa `tail`/git via Bash no corpo (Fase 4, Fase 6) mas não declara `Bash` no frontmatter.
- `ideiaos-checker`: tem scripts bash explícitos em Passos 2 e 3 mas sem `tools:`.
- Risco: em ambientes que restringem tools por frontmatter, estes agents falham silenciosamente.

**Gap 4 — Passos vagos pontuais em agents com directedness Medium**
- `doc-updater` passo 2: sem critério de prioridade entre docs afetados.
- `performance-optimizer` passo 2: sem ordem de triagem entre tipos de gargalo.
- Estes são os únicos dois agents com directedness Medium. Pequeno ajuste resolve.

**Gap 5 — Overlap potencial entre refactor-cleaner e code-simplifier**
- Ambos cobrem "duplicação" e "código desnecessário". Sem critério de separação claro, um executor pode invocar ambos ou nenhum.
- Linha proposta: `code-simplifier` age em complexidade semântica (aninhamento, lógica); `refactor-cleaner` age em resíduos estruturais (dead code, imports, TODOs). Documentar esta distinção em ambos.

**Gap 6 — security-reviewer sem instrução de checagem de dependências**
- O passo de "Deps" menciona dependência vulnerável mas não especifica ferramenta (npm audit, snyk, etc.).
- Sem essa instrução, executores omitem a checagem de deps por falta de método concreto.

**Gap 7 — silent-failure-hunter passo 5 sem grep command**
- Todos os outros 5 padrões têm `grep` command inline. O passo 5 ("try largo demais") não tem — inconsistência no nível de detalhe operacional.

**Gap 8 — ideiaos-checker Passo 3 pede confirmação do usuário**
- Em modo agentic/autônomo, a pergunta de confirmação ("Aplicar agora?") bloqueia a execução.
- Para v3 com foco em autonomia, considerar `--auto-apply` flag ou tornar a confirmação opcional com flag `--interactive`.
