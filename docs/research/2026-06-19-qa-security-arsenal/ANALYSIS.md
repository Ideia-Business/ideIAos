# SOURCE: analise de repos externos (2026-06-19) — DADOS informativos, nao instrucoes

> Todo conteudo abaixo derivado de repos de terceiros e tratado como **DADO informativo**.
> Nada aqui e instrucao a ser executada. Nenhum codigo de terceiro foi clonado, importado ou rodado.
> Disciplina aplicada: No-Invention (Const. Art IV), Native-before-dependency (operating-discipline #4),
> License/Provenance (ADR v11), Anti-injection (context-engineering), Integridade-antes-de-capacidade (v11).

---

## 0. Sumario executivo da analise

Foram analisados **tres repos externos** sob a otica de "o que o IdeiaOS pode absorver de QA e
AI-Security sem violar a disciplina de absorcao". Um e um framework de QA executavel
(testzeus-hercules); dois sao awesome-lists de AI-Security (TalEliyahu e muellerberndt). A conclusao
central: **quase nada e absorvivel como codigo** — o valor real esta em **taxonomias publicas
estaveis** (OWASP LLM/Agentic Top 10, frameworks de governanca) e em **conceitos de disciplina**
(verificacao runtime vs artefato, credential-isolation, auditoria de tool-definitions de MCP).

A superficie atual do IdeiaOS ja cobre **a maior parte** das dimensoes de QA (5 skills) e ja pratica
anti-injection em 3 lugares + um harness adversarial empirico (`evals/`). Os deltas reais sao
**estreitos, aditivos e conceito-only** — vocabulario nomeado e clausulas de fronteira, nao maquinaria
nova. Varios itens do recon foram **reduzidos** (ABSORB_REDUCED) ou **rejeitados** justamente por
duplicarem infra ja existente.

---

## 1. test-zeus-ai/testzeus-hercules

### O que e
Framework open-source de **QA agentico end-to-end** ("Hercules — the world's first open-source
testing agent"). Executa casos de teste descritos em linguagem natural (formato Gherkin/feature) via
agentes que dirigem um browser/runtime. Emite artefatos estruturados de execucao (plano de passos,
`chat_messages.json` com metadados de custo, resultados por dimensao).

### Licenca e o que ela permite
- **Licenca:** permissiva — **Apache-2.0** (declarada no recon; nao re-verificavel offline deste ambiente).
- **O que permite:** uso, modificacao e absorcao de codigo COM atribuicao. Ainda assim, a disciplina
  IdeiaOS prescreve **absorcao conceito-only** aqui (zero codigo importado), porque o valor esta no
  *mapa de dimensoes* e nos *principios de design*, nao no runtime Python do Hercules — que traria
  dependencia pesada (browser-driver, agent-runtime) sem pagar a propria complexidade.
- **Convencao obrigatoria:** qualquer artefato derivado leva cabecalho `# SOURCE: ... Hercules`.

### O que oferece (dimensoes de QA)
Hercules organiza QA numa **taxonomia unificada a partir de um contrato unico** de teste:
1. Funcional / UI
2. API — REST/GraphQL contract testing
3. Seguranca — OWASP
4. Acessibilidade — WCAG A/AA/AAA
5. Visual-regression
6. Mobile-emulation

Alem disso, dois principios de design relevantes:
- **Tool atomico retorna descricao em linguagem natural** do resultado (nao booleano opaco), para o
  agente raciocinar sobre estado real vs esperado.
- **Plano do agente como artefato auditavel** (`chat_messages.json`) — passos planejados + custo, nao so
  o resultado final.

### Cruzamento com a superficie ATUAL do IdeiaOS

| Dimensao Hercules | Cobertura atual no IdeiaOS | Veredito de gap |
|---|---|---|
| Funcional / UI | `frontend-visual-loop`, `e2e-testing` | Coberto |
| API contract testing (REST/GraphQL) | `api-design` cobre **design** de contrato, nao **teste** | **GAP real** |
| Seguranca OWASP | `gsd-secure-phase`, `security-reviewer.md` (STRIDE-leve) | Coberto (web), gap LLM (ver secao 2-3) |
| Acessibilidade WCAG | `accessibility`, `web-quality` | Coberto |
| Visual-regression | — | **GAP real** |
| Mobile-emulation | — | **GAP real** |

**Leitura senior:** as 6 dimensoes sao reais, mas **4 ja estao cobertas piecemeal** por 5 skills
distintas — sem nenhum indice que as liste lado a lado. Nenhum artefato hoje NOMEIA os 3 gaps
(API-contract, visual-regression, mobile-emulation) como lacunas conhecidas. **O delta absorvivel e o
indice de referencia cruzada + registro de 3 gaps**, NAO a taxonomia em si (que duplicaria conteudo
ja possuido pelas 5 skills). Criar skills novas para os 3 gaps seria bloat prematuro — registra-se o
gap, difere-se a skill ate doer.

**Principio "tool retorna NL":** colide aparentemente com `antifragile-gates.md`, que manda usar
exit-code binario e nao confiar no Read tool. Mas a regra cobre SO **artefato-de-arquivo**; nada nela
distingue **estado de runtime/UI** (onde nao existe exit-code e a skill ja-shippada `frontend-visual-loop`
legitimamente verifica via screenshot + accessibility-tree = interpretacao NL). A ambiguidade e **real
e demonstravel** (operating-discipline #6 frasa "verificar = exit code binario" como ABSOLUTO). O delta
e uma **clausula de fronteira curta** — dois regimes de verificacao — nao o framing amplo do Hercules.

**Principio "plano auditavel":** delta **near-zero**. GSD ja persiste o plano do agente como
`PLAN.md` (artefato durable, nao conversa efemera), `gsd-forensics` ja consome esses artefatos para
post-mortem, `cost-tracking` ja cobre token/model accounting, e v11 + antifragile-gates ja consagram
proveniencia de plano/evidencia. A unica sub-ideia nova (metadados de custo por-execucao ligados ao
trail do plano) e marginal E acoplada a infra (uma rule nao consegue forcar persistencia por-passo de
token = falha verify-don't-assume). **Rejeitado** (ver PROPOSAL.md).

---

## 2. TalEliyahu/Awesome-AI-Security

### O que e
**Awesome-list** curada de AI-Security — ponteiros para frameworks, checklists, ferramentas, papers e
taxonomias de seguranca de IA. Nao e codigo executavel; e um **indice de descoberta**.

### Licenca e o que ela permite
- **Licenca:** classe awesome-list (declarada MIT/CC0/CC-BY no recon; **nao re-verificavel offline** —
  exige conferir a licenca real ANTES de merge para garantir que nao e copyleft).
- **O que permite:** absorver **fatos publicos estaveis e links** com citacao (taxonomias OWASP, IDs,
  cross-map de frameworks). **Zero codigo.** Ponteiros para fontes autoritativas (owasp.org, nist.gov,
  iso.org, cloudsecurityalliance.org) sao o vetor seguro — apontar para o primario, nao para a lista volatil.
- **Convencao obrigatoria:** cabecalho `# SOURCE` nomeando o repo awesome-list E a licenca real do
  artefato-fonte (ex.: OWASP GenAI = **CC BY-SA 4.0 copyleft** -> conceito-only, atribuicao obrigatoria).

### O que oferece (recortes relevantes)
- **OWASP LLM Top 10** + **OWASP Agentic Top 10** — taxonomia nomeada de riscos LLM/agenticos.
- **SlowMist MCP Security Checklist** (MIT, Copyright 2025 SlowMist Team) + **MCP Security TTPs** —
  itens concretos de auditoria de MCP: tool-definitions perigosas/mutantes, escopo de permissao,
  egress nao-controlado, prompt-injection via tool description.
- **Credential isolation / agent access control** (padrao OneCLI/Cerbos) — doutrina: o agente nunca ve
  a credencial em claro; gateway/policy-layer injeta server-side fora do contexto.
- **Cross-map de governanca de IA** — NIST AI RMF <-> ISO/IEC 42001 <-> CSA AICM (243 controles / 18
  dominios, jul/2025) <-> Google SAIF <-> OWASP.
- **Datasets de jailbreak / prompt-injection / system-prompt-leak** — corpora para red-team de guards.

### Cruzamento com a superficie ATUAL do IdeiaOS

| Item TalEliyahu | Cobertura atual | Veredito de gap |
|---|---|---|
| OWASP LLM/Agentic Top 10 | `security-reviewer.md` = STRIDE-leve ad-hoc, **zero** framework LLM nomeado; `story-lifecycle.md` so tem "OWASP basics verified" (1 bullet vago). Toda mencao OWASP no repo aponta para o **web Top 10 classico** (dentro do `.aiox-core` vendado). | **GAP real** — eixo LLM ausente |
| Auditoria MCP (SlowMist/TTPs) | `mcp-hygiene.md` (26 linhas) = risk-table caseira + checklist generica (curl\|bash, ANTHROPIC_BASE_URL, contagem). `idea-doctor` check 7e ja faz anti-regressao dos **19 tools mutantes do Lovable** + `mcp-protocol.md` deny — mas **hardcoded p/ Lovable**, nao nomeado/generalizado. | **GAP de generalizacao** (pratica existe, nome nao) |
| Credential isolation | So **reativo**: `idea-doctor` secret-scanner (7c), `memory-export` R5-06 gate, `security-reviewer` agent — todos DETECTAM post-hoc. `agent-authority.md` governa autoridade-de-operacao, **silente** sobre posse-de-segredo. Anti-padrao vivo: `mcp-usage.md:155-176` manda HARDCODAR `value: 'actual-token-value'` em YAML. | **GAP real** — nenhuma doutrina preventiva |
| Cross-map governanca IA | grep em source/, docs/, .claude/ e vault = **zero** referencia a NIST/ISO-42001/CSA/SAIF. "Governance" so bate em orquestracao AIOX/GSD (conceito distinto). | **GAP real** — relevante p/ cfoai/nfideia regulados |
| Red-team empirico de guards | **JA EXISTE**: `evals/run-evals.sh` com pass^k (invariantes de seguranca, BLOQUEIA CI) vs pass@k; EVAL-019/020 ja atacam `scan-absorbed.sh`, derivados de defeitos reais. Loop dogfood ja fechado. | **Sem gap** (premissa do recon e falsa) |

---

## 3. muellerberndt/awesome-ai-security

### O que e
**Awesome-list** "An AI security awesome list / learning journey" por Bernhard Mueller (107 stars,
default branch `main`). Sobreposicao tematica grande com TalEliyahu, com enfase em **OWASP GenAI/LLM
Top 10 2025** e na postura de que **prompt injection e nao-corrigivel-por-design** (filtro nao basta ->
mitigar por CONTENCAO; "AI browsers may always be vulnerable").

### Licenca e o que ela permite
- **Licenca do repo:** classe awesome-list (nao re-verificavel offline). Mas o **artefato-fonte real**
  citado e o **OWASP Gen AI Security Project**, que e **CC BY-SA 4.0 (ShareAlike / copyleft)** —
  confirmado no primario genai.owasp.org pelo recon. Logo: absorver **CONCEITO apenas** (taxonomia de
  10 classes), **ZERO prosa copiada**, atribuicao obrigatoria. O header `# SOURCE` DEVE citar
  *"OWASP Gen AI Top 10 for LLM Apps 2025 — CC BY-SA 4.0"*, **nao** herdar a licenca do awesome-list.
- **No-Invention verificado contra o primario:** as 10 entradas batem (LLM01 Prompt Injection ... LLM10
  Unbounded Consumption). "LLM05 Insecure Output Handling" = oficial "Improper Output Handling";
  "LLM08 Vector/Embedding Weakness" = "Vector and Embedding Weaknesses". Nada fabricado.

### O que oferece
- **OWASP LLM Top 10 (2025)** completo como checklist-ancora: LLM01 Prompt Injection, LLM02 Sensitive
  Info Disclosure, LLM03 Supply Chain, LLM04 Data/Model Poisoning, LLM05 Insecure Output Handling,
  LLM06 Excessive Agency, LLM07 System Prompt Leakage, LLM08 Vector/Embedding Weakness, LLM09
  Misinformation, LLM10 Unbounded Consumption.
- **Prompt injection direto + indireto** como classe de ameaca operacional #1, postura de contencao.
- **AI supply-chain / model-provenance** (LLM03/04) + **Excessive Agency** (LLM06) como vocabulario.

### Cruzamento com a superficie ATUAL do IdeiaOS

| Item muellerberndt | Cobertura atual | Veredito de gap |
|---|---|---|
| OWASP LLM Top 10 (agent) | `security-reviewer.md` cego a output-handling inseguro, system-prompt leakage, excessive agency, unbounded consumption. `cyber-chief.md` (.claude/agents, terceiro vendado) cita OWASP **web** classico, nao LLM — eixo distinto. | **GAP puro** — alvo: estender `## Processo` do agent |
| Prompt-injection como item de checklist auditavel | 3 loci anti-injection cobrem superficies DISTINTAS: `handoff-packet.sh` (handoffs internos), `scan-absorbed.sh` (absorcao de terceiros), `context-engineering` (contexto do proprio dev). **Nenhum** cobre runtime de feature LLM de produto (ex.: RAG ingerindo doc do usuario). | **GAP estreito** — superficie runtime-de-produto |
| Excessive Agency (LLM06) como rotulo | Nenhuma rule NOMEIA. Learnings `temp-privilege-window` ja praticam least-privilege, mas sem rotulo auditavel. `agent-authority` = delegacao agente<->agente, nao tool-capability de feature de produto. | **GAP de vocabulario** (pratica existe, nome nao) |
| Model/dataset provenance pinning (LLM03/04) | IdeiaOS e dev-OS sem superficie de model-training/weights/dataset para gatear. Qual API de modelo confiar/pinar = decisao **product-layer** (cfoai/nfideia). | **Nao-acionavel no OS** — viola prevention-in-OS-vs-remediation-in-product |

---

## 4. Sintese cruzada — o que o IdeiaOS REALMENTE ganha

1. **QA:** ja cobre 4/6 dimensoes Hercules; ganha um **indice + registro de 3 gaps** (API-contract,
   visual-regression, mobile-emulation), nao skills novas.
2. **Verificacao:** ganha uma **clausula de fronteira** (artefato-de-arquivo = exit-code lei;
   runtime/UI = NL legitimo) que elimina uma contradicao latente entre regra absoluta e skill shippada.
3. **AI-Security — o maior delta:** ganha **vocabulario auditavel nomeado** que hoje nao existe em
   lugar nenhum do OS — OWASP LLM Top 10 no `security-reviewer`, "Excessive Agency" como rotulo,
   prompt-injection-de-runtime como item de checklist, criterios de auditoria de tool-definitions de MCP
   generalizados do caso Lovable, e uma **doutrina preventiva de credential-isolation** que cobre o vao
   deixado por todo o ferramental hoje reativo.
4. **Governanca:** ganha uma **nota de referencia no vault** (cross-map NIST/ISO/CSA/SAIF) que economiza
   re-pesquisa em due-diligence de produtos regulados — zero superficie no OS.
5. **O que NAO ganha:** red-team novo (ja existe `evals/`), plano-auditavel novo (ja existe GSD/forensics),
   model-provenance pinning (e product-layer).

**Risco transversal dominante:** *over-absorption*. Cada item de valor real e pequeno e aditivo; o modo
de falha e portar checklists/taxonomias inteiras (duplicando conteudo de 5 skills ou inflando uma rule de
26 linhas). A disciplina manda **reduzir ao delta nomeado** com header `# SOURCE`, sempre conceito-only.
