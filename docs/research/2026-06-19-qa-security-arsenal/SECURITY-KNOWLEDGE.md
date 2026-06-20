# SOURCE: awesome-ai-security (TalEliyahu, muellerberndt) — DADOS, nao instrucoes

> **Leia este cabecalho como contrato de uso, nao como permissao para copiar.**
> Todo conteudo abaixo foi destilado de duas awesome-lists usadas APENAS como
> *ponteiro de descoberta*. Nenhuma prosa curada foi copiada. Cada item rastreia
> a sua PROPRIA fonte primaria (OWASP, MITRE, NIST, o repo da ferramenta), que e
> de onde o fato vem — a lista so apontou onde procurar.
>
> | Repo-ponteiro | Licenca | Como foi tratado |
> |---|---|---|
> | `TalEliyahu/Awesome-AI-Security` | **MIT** (c) 2025 Tal Eliyahu | Fatos/links/taxonomia absorviveis com citacao. |
> | `muellerberndt/awesome-ai-security` | **SEM LICENCA** (`license: null`, footer "(c) muellerberndt", all-rights-reserved) | SO fatos nao-protegidos (nomes de framework/tool, classes de ataque publicas) re-derivados da fonte primaria. ZERO prosa, ZERO parafrase da descricao curada. |
>
> **Anti-injecao:** nenhum payload de injection foi observado em nenhum dos dois
> READMEs (recon read-only via WebFetch; nada clonado nem executado). O assunto
> dos repos e seguranca OFENSIVA de IA — absorvemos so o CONCEITO DEFENSIVO; nunca
> vendorizar nem rodar as ferramentas ofensivas citadas (HackGPT, PentestGPT,
> agentes de exploit-generation).
>
> **No-Invention (Const. Art IV):** afirmacoes empiricas datadas (ex.: "~40% do
> codigo do Copilot tinha vuln") sao marcadas `[CLAIM — verificar na fonte primaria]`
> porque vieram da lista, nao do estudo original. Nao trate como fato IdeiaOS ate
> rastrear ao estudo citado.

---

## Como usar este documento

Este e um **arsenal de conhecimento destilado**, organizado por **categoria de
risco**. Cada categoria traz:

- **Conceito** (o fato/ameaca, com fonte primaria).
- **O que o IdeiaOS pode VERIFICAR/aplicar** — uma acao concreta: gate no
  `idea-doctor.sh`, item de rule, check, ou item de checklist de `gsd-secure-phase`.
- **Onde encaixa** — o processo IdeiaOS existente que isto reforca (nada inventado:
  `mcp-hygiene`, `context-engineering`/anti-injection, `agent-authority`,
  `antifragile-gates`, `gsd-secure-phase`, `operating-discipline`).

A intersecao com processos JA existentes do IdeiaOS e deliberada (disciplina lean):
absorvemos so o delta que paga a propria complexidade. Itens marcados **[GAP]** sao
capacidades que o OS ainda nao tem; itens **[REFORCA]** ja existem e ganham nome
auditavel; **[REFERENCIA]** sao conhecimento de consulta (vault), nao codigo no OS.

> **Disciplina de gate (v11 — integridade antes de capacidade):** nenhum item
> abaixo deve virar gate HARD (exit 1) sem soak/validacao empirica. Todos os novos
> checks nascem **ADVISORY/WARN** ate provarem-se estaveis.

---

## 0. Rubricas-ancora (frameworks canonicos)

Antes das categorias de ataque, fixar as **rubricas nomeadas** que dao vocabulario
auditavel — substituem "parece seguro" por "verificado contra a lista X".

| Framework | Fonte primaria | Papel no IdeiaOS |
|---|---|---|
| **OWASP Top 10 for LLM Applications (2025)** | `genai.owasp.org` | Rubrica fixa do review de seguranca de QUALQUER feature que toca LLM. |
| **OWASP Agentic Security / Agentic Top 10** | `genai.owasp.org` (Agentic Security Initiative) | Rubrica para o PROPRIO fleet de agentes (AIOX + waves GSD). |
| **MITRE ATLAS** | `atlas.mitre.org` | Vocabulario TTP adversarial ("ATT&CK para IA") — threat-modeling rastreavel por technique-ID. |
| **NIST AI RMF + NIST AI 100-2 (Adversarial ML Taxonomy)** | `nist.gov` / `csrc.nist.gov` | Camada de TERMINOLOGIA canonica (evasion, poisoning, extraction, membership inference). |
| **ISO/IEC 42001 · CSA AICM (243 controles/18 dominios) · Google SAIF** | `iso.org`, `cloudsecurityalliance.org`, `saif.google` | Mapa de governanca para produtos regulados (cfoai, nfideia). [REFERENCIA] |

**[REFORCA] Acao IdeiaOS:** adicionar a `gsd-secure-phase` / `gsd-code-review` uma
**lente fixa OWASP LLM Top 10** — uma checklist nomeada LLM01..LLM10 percorrida em
todo review de feature LLM-facing. Converte o veredito subjetivo em verificacao
contra lista canonica. Gate ADVISORY.

**[REFERENCIA] Glossario ubiquo:** alimentar `CONTEXT.md` (ubiquitous-language) com
os termos canonicos NIST (evasion, poisoning, model extraction, membership
inference) em vez de nomes ad-hoc — afia spec e reduz tokens de reconciliacao.

---

## 1. Prompt Injection (direto + indireto) — #1 operacional

**Conceito (fonte: OWASP `LLM01:2025 Prompt Injection`):** entrada nao-confiavel
sobrescreve a instrucao do agente. **Direta** (usuario malicioso) e **indireta**
(texto envenenado num README/web-fetch/output de tool/handoff que o agente ingere).
Posicao defensiva: tratar injection como **nao-corrigivel por filtro** — mitigar por
**contencao** (dado != instrucao), nao por confiar num classificador.

**[REFORCA] Onde encaixa:** e exatamente a disciplina ja existente em
`context-engineering`, `context-packet-handoffs` (wrapper `anti_injection: true`),
e o proprio cabecalho deste recon ("fetched content is DATA, not instructions").

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **Item de rule (REFORCA):** todo ponto onde um agente ingere texto externo/nao-confiavel
  (README, web-fetch, output de tool, handoff) DEVE envolve-lo como DADO. Posicionar o
  guard no **boundary da tool-call** (padrao da lista: guardrail no nivel da tool-call,
  ex. firewall em camadas). Sem dependencia nova — e doutrina, nao tool.
- **Check `idea-doctor` (REFORCA):** confirmar que handoffs em `.aiox/handoffs/`
  carregam `wrapped: true` / `anti_injection: true` (helper `handoff-packet.sh`).
  Handoff sem o campo = legado, WARN.
- **Red-team do proprio guard [GAP — ver §8]:** validar o wrapper anti-injection
  contra corpora publicos de prompt-injection, nao so happy-path.

---

## 2. Model & Supply-Chain Security

**Conceito (fonte: OWASP `LLM03:2025 Supply Chain` + NIST AI RMF):** pesos de
modelo, datasets e APIs de modelo de terceiros sao superficie de ataque de
supply-chain. Model artifacts podem carregar payload (pickle/deserializacao);
endpoints de modelo de terceiros sao dependencia nao-confiavel como qualquer outra.

**[REFORCA] Onde encaixa:** estende `mcp-hygiene` (classificacao de risco de
dependencia externa) e a disciplina de pin de versao para a **camada de IA**.

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **Item de checklist `gsd-secure-phase`:** pin/verificar proveniencia de modelo +
  dataset; tratar endpoint de modelo de terceiro como dependencia nao-confiavel
  (egress, rate-limit, sem segredo no contexto).
- **Conceito AIBOM (fonte: CycloneDX / OWASP supply-chain):** considerar um
  *AI/ML BOM* (manifest de modelos+datasets) para produtos regulados — paralelo ao
  SBOM. [REFERENCIA, nao codigo no OS ainda.]
- **Scanner de model-artifact (CONCEITO):** model-artifact scanners detectam
  desserializacao maliciosa em pesos. Absorver o PRINCIPIO (nunca carregar peso de
  origem nao-verificada); native-before-dependency — nao vendorizar scanner agora.

---

## 3. Data Poisoning & Backdoors

**Conceito (fonte: OWASP `LLM04:2025 Data and Model Poisoning`; NIST AI 100-2):**
envenenar dados de treino/fine-tune/RAG insere comportamento malicioso ou backdoor.
Pesquisa recente mostra **[CLAIM — verificar na fonte primaria]** que poisoning de
tamanho ~constante (poucos pontos) funciona mesmo em escala web — i.e., a defesa
"o dataset e grande demais para ser envenenado" e falsa.

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **Item de checklist:** qualquer produto que faca fine-tune ou indexe conteudo
  user-supplied num vector store DEVE tratar a fonte de ingestao como nao-confiavel
  (validar/curar antes de indexar; isolar tenant).
- **Vector/memory store security (fonte: OWASP supply-chain + ATLAS):** RAG e
  superficie de injection indireta — texto recuperado e DADO, nunca instrucao
  (cross-link §1). Item de rule.

---

## 4. MLSecOps (ciclo de vida)

**Conceito (fonte: NIST AI RMF; CSA AICM):** seguranca de IA e continua ao longo do
ciclo (dados -> treino -> deploy -> monitoramento), nao um gate unico. Inclui
monitoring/logging/anomaly-detection do comportamento do modelo em runtime.

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **[REFORCA] operating-discipline #6 (Verify, Don't Assume):** a "evidencia" de uma
  feature de IA segura e uma metrica de runtime/benchmark, nao "parece certo" (§8).
- **Item de checklist:** features LLM-facing em producao devem ter logging/anomaly
  detection do output (deteccao de drift/abuse). [GAP — hoje nao ha padrao no OS.]

---

## 5. OWASP LLM Top 10 (2025) — checklist operacional

Fonte primaria: `genai.owasp.org`. Use como rubrica direta no review (cite o ID).

| ID | Risco | O que o IdeiaOS verifica |
|---|---|---|
| **LLM01** | Prompt Injection | §1 — wrap externo como DADO; guard no boundary da tool-call. |
| **LLM02** | Sensitive Information Disclosure | Saida do LLM nao vaza segredo/PII; cross-link §7. |
| **LLM03** | Supply Chain | §2 — proveniencia de modelo/dataset/API. |
| **LLM04** | Data & Model Poisoning | §3 — ingestao nao-confiavel; RAG = dado. |
| **LLM05** | Improper Output Handling | §7 — tratar output do LLM como nao-confiavel (sanitizar antes de exec/render). |
| **LLM06** | Excessive Agency | §7 — least-privilege de tool; agent-authority. |
| **LLM07** | System Prompt Leakage | nao colocar segredo no system prompt; red-team com datasets de system-prompt-leak (§8). |
| **LLM08** | Vector & Embedding Weaknesses | §3 — seguranca do vector store; isolamento de tenant. |
| **LLM09** | Misinformation | output factual = verificar (operating-discipline #6). |
| **LLM10** | Unbounded Consumption | rate-limit/quota; deter model-stealing (§6). |

**[REFORCA] Acao:** embutir esta tabela como checklist de `gsd-secure-phase` para
qualquer fase LLM-facing. Gate ADVISORY (cada item = PASS/WARN/N-A com nota).

---

## 6. Privacy & Extraction Attacks

**Conceito (fonte: NIST AI 100-2 — taxonomia de privacidade):** classes coerentes de
ameaca a dados quando um produto faz fine-tune sobre ou armazena dados de usuario num
contexto LLM:
- **Training-data extraction** (modelo memoriza e regurgita dado de treino).
- **Model stealing / extraction** (reconstruir o modelo via consultas).
- **Membership inference** (descobrir se um registro estava no treino).
- **Watermarking** de output gerado por IA (defesa/atribuicao).

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **Item de checklist "privacidade em features de IA":** proteger contra memorizacao/
  extracao; rate-limit + monitorar a API para deter model-stealing; considerar
  watermark em output de IA.
- **[REFORCA] Credential isolation (padrao OneCLI/Cerbos — fonte: TalEliyahu, secao
  Tools):** o agente NUNCA ve a credencial em claro — um gateway/policy-layer injeta
  no request e autoriza por politica fine-grained. **Liga direto ao incidente
  `IDEIA_CHAT_SYSADMIN_PASSWORD`:** separa AUTORIDADE-de-operacao (ja em
  `agent-authority.md`) de POSSE-de-segredo. Item de rule: segredo nao transita pelo
  contexto do LLM. Absorver o PRINCIPIO; nao adotar Cerbos/OneCLI como dep.

---

## 7. Agent & MCP Security (+ output handling)

**Conceito (fonte: OWASP Agentic Top 10; MITRE ATLAS; SlowMist MCP Security
Checklist; MAESTRO threat-modeling multi-agente; AIDEFEND mitigation map):**
- **Excessive Agency (LLM06):** agente com mais capacidade que a tarefa exige =
  superficie de abuso (tool abuse, goal hijacking, credential exfil).
- **MCP-specific TTPs:** tool-definitions perigosas, permissoes amplas, egress
  nao-controlado em manifests de MCP. Conceito **mcp-scan**: varrer manifests por
  definicoes/permissoes inseguras.
- **Execution sandboxing:** codigo gerado por LLM deve rodar isolado (microVM:
  E2B/Firecracker, microsandbox/libkrun) quando nao-confiavel.
- **Improper Output Handling (LLM05):** output do LLM e nao-confiavel — sanitizar
  antes de executar/renderizar/persistir.

**[REFORCA/GAP] O que o IdeiaOS pode VERIFICAR/aplicar:**
- **Upgrade de `mcp-hygiene.md` [REFORCA]:** a rule ja limita servidores/tools ativos
  por heuristica caseira. Absorver itens CONCRETOS da SlowMist MCP Checklist + TTPs de
  MCP: auditar **tool-definitions perigosas**, **egress** e **permissoes** dos
  manifests. Alinha direto com o trabalho v10 (deny-list de 19 tools mutantes do
  Lovable MCP). **Check `idea-doctor`:** estender a auditoria de MCP para sinalizar
  manifest com tool mutante sem deny correspondente (conceito mcp-scan, CLI-first).
- **Least-privilege de tool [REFORCA]:** `agent-authority` + `temp-privilege-window`
  ja codificam "nao conceda mais capacidade que a tarefa precisa" — nomear isto como
  mitigacao de *Excessive Agency* (OWASP) da rastreabilidade. Threat-model nomeado
  ("tool abuse / goal hijacking / credential exfil") para o PROPRIO fleet, mapeado a
  ATLAS/MAESTRO.
- **Execution sandboxing [GAP — principio]:** decidir QUANDO o sandbox do harness +
  deny rules de FS basta vs quando isolar em microVM. Absorver o PRINCIPIO (isolar
  execucao nao-confiavel), nao a dep (native-before-dependency).
- **Output handling [item de rule]:** output de LLM tratado como dado nao-confiavel
  antes de exec/render — cross-link com o cuidado anti-injection (§1).

---

## 8. Secrets, Output & Validacao por Evidencia (red-team do proprio OS)

**Conceito (fontes: OWASP LLM02/LLM07; benchmarks JailbreakBench, RobustBench,
TrustLLM, Stanford AIR-Bench; datasets de jailbreak/prompt-injection/system-prompt da
lista TalEliyahu):** nao se DECLARA uma feature LLM "segura" — mede-se contra um
benchmark/dataset publico. LLM-as-Judge + guardrail scanners dao um score repetivel
que serve de **artefato de evidencia** que o gate exige.

**O que o IdeiaOS pode VERIFICAR/aplicar:**
- **[REFORCA] Secrets em saida/memoria:** `idea-doctor` §7c ja escaneia segredos em
  texto plano na memoria de projeto. Manter; nao endurecer heuristica sem soak
  (licao `secret-scanner-observer-effect`).
- **[GAP] Red-team dos proprios guards (dogfood):** validar EMPIRICAMENTE o wrapper
  anti-injection (`handoff-packet.sh`) e o secret-scanner contra corpora publicos de
  jailbreak/prompt-injection/system-prompt-leak. Operacionaliza
  `operating-discipline #6` ("Verify, Don't Assume") aplicando red-team de injection
  ao PROPRIO OS — fecha o loop dogfood que ja pegou defeitos antes (licao
  `dogfood-review-tool-catches-own-defect`). Comecar com um punhado de prompts
  adversariais canned (native-before-dependency) antes de vendorizar scanner (Garak/
  PyRIT/Rebuff/Vigil/Purple Llama — cada um rastreia ao proprio repo; NVIDIA Garak,
  Microsoft PyRIT, ProtectAI Rebuff, Meta Purple Llama/PromptGuard).
- **[REFORCA] Codigo gerado por IA = fonte de vuln (fonte: estudos citados;
  `[CLAIM ~40% do output do Copilot com vuln — verificar na fonte primaria]`):**
  justifica que codigo escrito por agente passa pelo MESMO (ou mais estrito) review de
  seguranca que codigo humano — ja em `gsd-code-review` + "Verify, Don't Assume" +
  disciplina NASA "integridade antes de capacidade" (v11).
- **[GAP] AI-assisted SAST CLI-first (fonte: Semgrep + LLM — IDOR/broken-access):**
  recomendar **Semgrep** como camada SAST CLI-first em repos de produto (alinha
  Const. Art I / token-economy MCP->CLI). Regras + raciocinio LLM pegam falha de
  logica que regra-sozinha perde. Recomendacao, nao gate HARD.

---

## 9. Apendice — Mapa de fontes primarias (autoridade)

Cite SEMPRE a fonte primaria, nunca a awesome-list, ao afirmar um fato num doc IdeiaOS.

| Dominio | Fonte primaria (autoridade) |
|---|---|
| LLM Top 10 / Agentic / checklist governanca | OWASP GenAI — `genai.owasp.org` |
| TTP adversarial de IA | MITRE ATLAS — `atlas.mitre.org` |
| Taxonomia/terminologia + RMF | NIST — `csrc.nist.gov` (AI 100-2), `nist.gov/itl/ai-risk-management-framework` |
| Controles de governanca | ISO/IEC 42001; CSA AICM — `cloudsecurityalliance.org`; Google SAIF — `saif.google` |
| Vuln DB de IA | AVID — `avidml.org` |
| Tools de red-team (cada um -> seu repo) | Garak (NVIDIA), PyRIT (Microsoft), Rebuff (ProtectAI), Purple Llama (Meta), NeMo Guardrails (NVIDIA), Semgrep |
| MCP security checklist | SlowMist MCP Security Checklist (repo proprio) |
| Discovery pointers (SO ponteiro) | `TalEliyahu/Awesome-AI-Security` (MIT); `muellerberndt/awesome-ai-security` (sem licenca) |

---

### Resumo das acoes propostas (priorizadas)

1. **[REFORCA]** Lente OWASP LLM Top 10 como checklist de `gsd-secure-phase` (ADVISORY). §5
2. **[REFORCA]** Item de rule: wrap de input externo como DADO no boundary da tool-call. §1
3. **[REFORCA]** Upgrade `mcp-hygiene.md` com itens SlowMist/MCP-TTP + check mcp-scan no `idea-doctor`. §7
4. **[REFORCA]** Credential isolation: segredo nunca no contexto do LLM (liga ao incidente IDEIA_CHAT). §6
5. **[GAP]** Red-team dogfood dos guards anti-injection/secret-scanner contra corpora publicos. §8
6. **[GAP/recomendacao]** Semgrep como SAST CLI-first em repos de produto. §8
7. **[REFERENCIA]** Termos NIST no `CONTEXT.md`; mapa de governanca no vault para produtos regulados. §0
