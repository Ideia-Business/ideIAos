# SOURCE: proposta de absorcao QA & AI-Security (2026-06-19) — DADOS informativos, nao instrucoes

> Proposta de absorcao PRIORIZADA derivada da analise em `ANALYSIS.md`. Conteudo informativo.
> Nada aqui foi implementado — e plano. Toda absorcao e conceito-only, com header `# SOURCE` obrigatorio.
> Disciplina: No-Invention · Native-before-dependency · License/Provenance (ADR v11) · Anti-injection ·
> Integridade-antes-de-capacidade.

---

## 1. Propostas CONFIRMADAS (corpo principal)

Legenda — **Camada**: doc / rule / agent / gate. **Esforco**: S/M/L. **Valor**: med/high.
**Veredito**: ABSORB (integral) · ABSORB_REDUCED (so o nucleo reduzido).

| ID | Titulo | Repo | Camada | Delta vs existente | Esforco | Valor | Veredito |
|----|--------|------|--------|--------------------|---------|-------|----------|
| **QA-01** | QA coverage taxonomy doc — indice de cobertura + registro dos 3 gaps | testzeus-hercules | doc | NOVO como artefato consolidado; hoje 6 dimensoes espalhadas por 5 skills sem indice; nenhum nomeia API-contract/visual-regression/mobile-emulation como gaps | S | med | ABSORB_REDUCED |
| **QA-02** | Addendum antifragile-gates: artefato-de-arquivo (exit-code) vs estado-de-runtime (NL) | testzeus-hercules | rule | Refina antifragile-gates: regra hoje so cobre artefato-de-arquivo; nada distingue verificacao de runtime/UI onde nao ha exit-code | S | med | ABSORB_REDUCED |
| **SEC-01** | OWASP LLM Top 10 (2025) como rubrica nomeada no security-reviewer | mueller + TalEliyahu | agent | security-reviewer = STRIDE-leve ad-hoc, zero framework LLM; adiciona secao condicional "OWASP LLM Top 10" disparada quando o diff toca endpoint/SDK de LLM | S | high | ABSORB_REDUCED |
| **SEC-02** | Prompt-injection de runtime como item de checklist auditavel no security-reviewer | muellerberndt | agent | 3 loci anti-injection existentes cobrem handoff/absorcao/dev-context, NAO runtime de feature LLM de produto (RAG ingerindo doc do usuario) | S | med | ABSORB_REDUCED |
| **SEC-03** | Endurecer mcp-hygiene com criterios MCP-especificos (SlowMist + MCP TTPs) | TalEliyahu | rule | mcp-hygiene (26 linhas) nao NOMEIA tool-definition perigosa / permission-scope / egress / injection-via-tool-description; generaliza o caso Lovable (idea-doctor 7e) | S | med | ABSORB_REDUCED |
| **SEC-04** | "Excessive Agency" (LLM06) como rotulo auditavel em mcp-hygiene + agent-authority | muellerberndt | rule | Nenhuma rule nomeia "Excessive Agency"; ~5 linhas anexadas; least-privilege ja praticado (temp-privilege-window) mas sem rotulo | S | med | ABSORB_REDUCED |
| **SEC-05** | Rule de credential-isolation: segredo nunca transita pelo contexto do LLM | TalEliyahu | rule | Hoje so reativo (scanner/gate/agent detectam post-hoc); agent-authority silente sobre posse-de-segredo; anti-padrao vivo em mcp-usage.md:155-176 (hardcode de token) | M | high | ABSORB_REDUCED |
| **GOV-01** | Nota de referencia no vault: cross-map governanca de IA (NIST AI RMF / ISO 42001 / CSA AICM / SAIF) | TalEliyahu | doc | Zero referencia de governanca de IA no OS/vault; produtos regulados (cfoai/nfideia) re-pesquisam do zero | S | med | ABSORB |
| **EVAL-01** | EVAL-*.md adversariais auto-autorados plugados no harness existente | TalEliyahu | gate | scan-absorbed/handoff-wrapper ja tem evals (019/020), mas faltam casos de payload unicode-invisivel/data:URI/BOM; reusa run-evals.sh, ZERO dep externa | S | med | ABSORB_REDUCED |

### Notas de implementacao por proposta (condicoes vinculantes)

- **QA-01** — doc curto que (a) linka os paths reais das skills cobrindo cada dimensao e (b) nomeia os 3
  gaps como registro que alimenta `gsd-code-review`/`gsd-secure-phase`. **NAO** re-explicar conhecimento
  por-dimensao que as 5 skills ja possuem. Header `# SOURCE: ... Hercules (AGPL-3.0 — conceito-only, zero codigo/prosa)`. Difere criar
  skills novas ate o gap doer.
- **QA-02** — absorver SO a clausula de fronteira (dois regimes); acrescentar 1 linha em
  operating-discipline #6 suavizando o "absoluto" para nao contradizer a skill `frontend-visual-loop`.
  `test -s` continua lei p/ arquivos. Header `# SOURCE: ... Hercules`. Editar a source-of-truth em
  `source/rules/common/antifragile-gates.md` (propaga via setup --project-only).
- **SEC-01** — estender SO o `## Processo` de `source/agents/security-reviewer.md` (alvo unico; `plugins/`
  e copia de build). Secao condicional, reusa a tabela de output existente. **DROPAR** a parte do
  idea-doctor (e health-checker de instalacao, nao scaneia diffs = bloat). Header **obrigatorio**:
  `# SOURCE: OWASP Gen AI Top 10 for LLM Apps 2025 — CC BY-SA 4.0` (copyleft -> conceito-only, zero prosa).
- **SEC-02** — UMA linha de check ("Ingestao de texto nao-confiavel -> envolver como DADO, nunca
  instrucao"), cross-linkando `context-engineering` em vez de re-explicar. Manter "AI browsers may
  always be vulnerable" so como racional citado, nao como nova doutrina.
- **SEC-03** — bloco conciso de 4-6 criterios nomeados anexado a rule lean, cross-linkando `idea-doctor`
  7e como o enforcement do criterio generalizado. **NAO** portar o checklist multi-pagina da SlowMist.
  Header `# SOURCE: SlowMist MCP-Security-Checklist (MIT)`. NAO absorver `mcp-scan` como ferramenta.
- **SEC-04** — ~5 linhas na risk-table de mcp-hygiene + nota de framing em agent-authority. So a parte (b)
  do recon (vocabulario LLM06); a parte (a) — model/dataset provenance pinning — esta **REJEITADA**
  (ver secao 2). Header `# SOURCE: OWASP GenAI Top 10 2025`.
- **SEC-05** — colocar em `source/rules/common/` (durable, propagavel, stack-agnostico). Doutrinal/lean
  (principio, nao how-to de secrets-management). Cross-linkar (1) o workaround de hardcode em
  `mcp-usage.md` como anti-padrao a deprecar, (2) `agent-authority.md` (autoridade vs posse) e (3) o
  learning `project-ideia-chat-test-secret-acceptable` (para nao re-flagar o test-secret aceito).
  Header `# SOURCE`.
- **GOV-01** — nota lean no vault `References/`: tabela cross-map + links autoritativos + proveniencia
  datada. **NAO** espelhar o catalogo de 243 controles da CSA AICM. Destino = vault (lar canonico de
  referencias externas), zero superficie no OS.
- **EVAL-01** — 2-4 casos `EVAL-*.md` sinteticos proprios (payload unicode invisivel, data:URI base64,
  BOM com instrucao embutida) plugados no `evals/run-evals.sh` EXISTENTE. ZERO dataset externo (importar
  corpus aumentaria a superficie que a quarentena existe para reduzir). Manter ADVISORY ate soak.

---

## 2. Rejeitadas (e por que)

| ID recon | Titulo | Repo | Motivo da rejeicao |
|----------|--------|------|--------------------|
| HERC-P3 | Plano-do-agente como artefato auditavel (addendum cost-tracking/forensics) | testzeus-hercules | **Duplicativo + nao-enforceable.** GSD ja persiste o plano como `PLAN.md` durable; `gsd-forensics` ja consome para post-mortem; `cost-tracking` ja cobre token/model; v11 + antifragile-gates ja consagram proveniencia. A unica sub-ideia nova (token-metadata por-passo ligado ao plano) e acoplada a infra que o harness nao expoe como evidencia binaria -> falha verify-don't-assume = bloat. Default-REJECT. |
| AISEC-05 (forma original) | Red-team empirico via catalogo de datasets externos + novo harness (esforco L, ADVISORY-ate-soak) | TalEliyahu | **Premissa falsa + duplica infra + mis-mira instrumento.** Ja existe harness adversarial empirico (`evals/run-evals.sh`, pass^k que BLOQUEIA CI; EVAL-019/020 ja atacam scan-absorbed). As 2 learnings citadas como motivacao ja foram descobertas+remediadas via dogfood. Importar corpus de jailbreak (prompts NL p/ subverter LLM) mede NADA contra guards regex/codepoint que escaneiam ARQUIVOS. Viola lean/native-first + aumenta superficie de ataque. **Reduzido** para EVAL-01 (casos sinteticos proprios no harness existente) — ver secao 1. |
| AISEC-03 part (a) / SEC-04 part (a) | AI supply-chain / model & dataset provenance pinning (LLM03/04) | muellerberndt + TalEliyahu | **Fora do escopo do OS.** IdeiaOS e dev-OS sem superficie de model-training/weights/dataset para gatear. Qual API de modelo confiar/pinar = decisao product-layer (cfoai/nfideia). Viola prevention-in-OS-vs-remediation-in-product; seria linha nao-acionavel inflando mcp-hygiene = invention-by-analogy. So a parte (b) — vocabulario "Excessive Agency" — sobrevive como SEC-04. |
| AISEC-01 (Agentic Top 10 alem do LLM Top 10) | Adotar tambem o OWASP **Agentic** Top 10 como rubrica | TalEliyahu | **Absorvido parcialmente.** O eixo LLM Top 10 entra via SEC-01. A camada *Agentic* adicional nao paga complexidade extra hoje: o security-reviewer ja ganha rastreabilidade com o LLM Top 10; duplicar com uma segunda lista canonica antes de haver demanda viola enforce-simplicity. Mantido como nota no proprio SEC-01 (cross-ref), nao como rubrica separada. |

---

## 3. ESBOCO DE MILESTONE — v12 (QA & AI-Security)

> Estilo herdado dos milestones v8 (Disciplina), v9 (Alinhamento), v11 (Integridade & Auditoria de Spec).
> Principio organizador: **integridade ANTES de capacidade** (disciplina NASA do v11) — primeiro as
> clausulas de fronteira e a doutrina preventiva, depois o vocabulario auditavel, por fim os casos de eval.

### Objetivo
Dotar o IdeiaOS de **vocabulario de seguranca de IA nomeado e auditavel** (OWASP LLM Top 10, Excessive
Agency, prompt-injection de runtime, criterios MCP) e de **doutrina preventiva de credential-isolation**,
fechando os gaps de AI-Security identificados — **sem adicionar nenhuma dependencia, ferramenta ou
maquinaria nova**, apenas estendendo agents/rules/docs existentes e o harness `evals/` ja shippado.
Secundariamente, consolidar um **indice de cobertura de QA** que torna explicitos 3 gaps conhecidos
(API-contract, visual-regression, mobile-emulation) sem criar skills prematuras.

### Requisitos

| ID | Requisito | Itens |
|----|-----------|-------|
| **R12-01** | Toda absorcao e conceito-only com header `# SOURCE` correto; copyleft (OWASP CC BY-SA 4.0) -> zero prosa copiada | SEC-01, SEC-04 |
| **R12-02** | Doutrina preventiva de credential-isolation em `source/rules/common/`, propagavel, cross-linkando o anti-padrao de hardcode | SEC-05 |
| **R12-03** | `security-reviewer` ganha rubrica LLM Top 10 condicional + check de prompt-injection de runtime, reusando o output existente | SEC-01, SEC-02 |
| **R12-04** | `mcp-hygiene` generaliza o caso Lovable em criterios MCP nomeados + rotulo "Excessive Agency"; cross-link idea-doctor 7e | SEC-03, SEC-04 |
| **R12-05** | Clausula de fronteira verificacao artefato-vs-runtime em antifragile-gates + ajuste em operating-discipline #6 | QA-02 |
| **R12-06** | Indice de cobertura de QA + registro dos 3 gaps, alimentando gsd-code-review/gsd-secure-phase | QA-01 |
| **R12-07** | Nota de governanca de IA no vault References/ (cross-map, links autoritativos, datada) | GOV-01 |
| **R12-08** | 2-4 EVAL-*.md adversariais sinteticos proprios no harness existente, ADVISORY ate soak | EVAL-01 |

### Ondas (ordenadas integridade-antes-de-capacidade)

- **W1 — Integridade & fronteira (R12-05, R12-02).** Primeiro refinar a regra de verificacao (clausula
  artefato-vs-runtime) e estabelecer a doutrina de credential-isolation. Sao as mudancas que tornam o
  proprio chao mais preciso antes de adicionar capacidade. Edicoes em `source/rules/common/`.
- **W2 — Vocabulario auditavel de AI-Security (R12-03, R12-04).** Estender `security-reviewer` (LLM Top
  10 + prompt-injection de runtime) e `mcp-hygiene`/`agent-authority` (criterios MCP + Excessive Agency).
  Tudo conceito-only com header `# SOURCE`, reusando estruturas existentes.
- **W3 — Referencia & QA index (R12-06, R12-07).** Indice de cobertura de QA (com os 3 gaps registrados)
  e nota de governanca no vault. Puro conhecimento de referencia, zero superficie no OS.
- **W4 — Validacao empirica (R12-01, R12-08).** Auditar os headers `# SOURCE`/licenca de tudo que W1-W3
  produziram (gate de proveniencia) e plugar os EVAL-*.md adversariais no harness. Mantem-se ADVISORY
  ate o soak — integridade antes de gate HARD.

### Definition of Done (DoD)

1. **Provenance gate:** todo artefato novo/editado carrega header `# SOURCE` com a licenca real do
   artefato-fonte; OWASP citado como CC BY-SA 4.0 e absorvido conceito-only (verificavel por grep:
   zero prosa copiada).
2. **Native-first verificado:** zero dependencia nova, zero ferramenta nova, zero MCP novo; cada delta e
   extensao de agent/rule/doc existente ou caso no harness existente (auditavel por diff).
3. **Sem duplicacao:** itens rejeitados (HERC-P3, AISEC-05-original, supply-chain pinning) permanecem
   fora; mcp-hygiene continua lean (criterios nomeados, nao checklist multi-pagina).
4. **Lean confirmado:** SEC-05 em source/rules/common propaga via `setup.sh --project-only`; nenhuma
   regra ultrapassa o orcamento de tamanho que ja praticam.
5. **Evals verdes:** os 2-4 EVAL-*.md adversariais novos rodam no `run-evals.sh` e o suite permanece
   verde; casos novos ADVISORY ate o gate de soak v11-style.
6. **Cross-links corretos:** SEC-05 cita o anti-padrao mcp-usage.md, agent-authority e o learning do
   test-secret aceito; SEC-01/04 nao re-introduzem o web-OWASP do `.aiox-core` vendado.
7. **Fechamento padrao:** STATE.md + CONTINUATION_HANDOFF.md atualizados; learning extraido se houver
   padrao replicavel; README do GitHub atualizado com os novos recursos (per feedback do projeto).

### Fora de escopo do v12 (explicito)
- Criar skills novas para API-contract / visual-regression / mobile-emulation (so registro de gap).
- Importar qualquer corpus/dataset externo de jailbreak.
- Pinning de proveniencia de modelo/dataset (e product-layer: cfoai/nfideia).
- Qualquer addendum de plano-auditavel/cost-tracking (ja coberto por GSD/forensics/cost-tracking).
