# VALIDATION.md — Camada de Validação Consolidada (Dois Juízes + Reconciliação)

> **Método:** cada recomendação passou por duas lentes independentes — **Juiz A (Valor/ROI/Encaixe Estratégico)** e **Juiz B (Risco/Custo/Manutenção/Integração)**. Onde os dois convergem, o stance é **ROBUSTO**. Onde divergem materialmente, sinalizamos **DECISÃO DO USUÁRIO**. A revisão NASA de sistemas está em `SYSTEMS-REVIEW.md`.

## Tabela-resumo

| Rec | Juiz A (Valor/ROI) | Juiz B (Risco/Manut.) | Stance reconciliado | Confiança final |
|-----|--------------------|-----------------------|---------------------|-----------------|
| **R1** — `/spec --analyze`/`--converge` | KEEP (HIGH) | KEEP (MEDIUM) | **KEEP — condicionado a núcleo determinístico** (ROBUSTO) | **HIGH na direção, MEDIUM na blindagem** |
| **R2** — escada de 6 degraus de simplicidade | KEEP (MEDIUM) — "só o degrau novo" | DOWNGRADE (MEDIUM) | **DOWNGRADE → absorver só "feature nativa antes de dependência"** (ROBUSTO na substância) | **MEDIUM** |
| **R3** — recursive-decomposition (orchestration) | DOWNGRADE (MEDIUM) | DOWNGRADE (MEDIUM) | **DOWNGRADE — só com critério operável** (ROBUSTO) | **MEDIUM** |
| **R4** — precedência de instrução | KEEP (HIGH) | KEEP (MEDIUM) | **KEEP — cuidado de posicionamento** (ROBUSTO) | **HIGH no valor, MEDIUM na casa** |
| **R5** — rubric 5 eixos p/ promoção de instinct | DROP (MEDIUM) | KEEP (LOW) | **DIVERGÊNCIA → decisão do usuário** (tende a DROP/adiar) | **LOW** |
| **R6** — marcador `// debt:` + idea-doctor | KEEP (MEDIUM) | DOWNGRADE (MEDIUM) | **DOWNGRADE — só com escopo restrito** (ROBUSTO na substância) | **MEDIUM** |
| **R7** — taxonomia 9 eixos no /grelha | DOWNGRADE (MEDIUM) | DOWNGRADE (LOW) | **DOWNGRADE → backlog** (ROBUSTO) | **LOW–MEDIUM** |
| **R8** — conceito reflexion (GPL) | DROP (MEDIUM) | DROP (MEDIUM) | **DROP → nota de quarentena no ADR** (ROBUSTO) | **MEDIUM** |
| **v11** — milestone "Auditoria da Camada de Spec" | DOWNGRADE (HIGH) | KEEP-com-cortes (MEDIUM) | **DIVERGÊNCIA → decisão do usuário (forma vs timing)** | **MEDIUM-HIGH** |

---

## R1 — `/spec --analyze` + `--converge` (auditoria cross-artefato)

### Juiz A (Valor/ROI)
**Forças:**
- Ataca o diferencial estratégico declarado do IdeiaOS (delta-spec brownfield) exatamente onde ele é hoje cego. Confirmou por inspeção que `lib/` só tem `spec-merge.sh` + `spec-validate.sh` (syntax intra-delta), zero cross-artefato. **O GAP é real, não inventado.**
- Minera o prompt do spec-kit sem importar a premissa greenfield que o tornaria redundante — única fonte que entrega capacidade NOVA em vez de polir existente.
- `--converge` (gap-to-code, append-only) é o mais alinhado ao valor brownfield: reusa o parser de `spec-merge.sh`, esforço incremental contido, encaixe nativo.

**Fraquezas:**
- Os 6 passes de `--analyze` e o gerador `--converge` são LLM, não shell determinístico. O gate (`test -s` no relatório) prova que o arquivo existe, NÃO que a auditoria está correta — violação direta de antifragile-gates. Vender auditoria de spec com veredito alucinável é pior que não ter auditoria.
- Risco de teatro de qualidade: usuário confia no relatório verde e para de revisar manualmente; falso-negativo (gap não detectado) é mais perigoso que a ausência da ferramenta.

**Stance A:** KEEP · Confiança HIGH

### Juiz B (Risco/Manutenção)
**Forças:**
- GAP confirmado por inspeção direta (mesma conclusão de A).
- Entra como SUBCOMANDO de /spec (não skill nova) → não infla o catálogo de skills nem o token de descoberta; integração limpa via build-adapters.sh.
- `--converge` append-only + reuso do parser de spec-merge.sh é o vetor de menor risco: aproveita motor determinístico já testado (27 bats).
- Alinhado ao diferencial brownfield, não à premissa greenfield — a rec explicitamente rejeita o que duplica.

**Fraquezas:**
- **RISCO CENTRAL (idêntico ao de A):** os 6 passes são julgamento de LLM, não shell. Relatório vazio/alucinado passa o gate. Viola antifragile-gates + operating-discipline item 6 DENTRO da própria ferramenta de auditoria.
- Custo de manutenção oculto: cruza 4 artefatos cujos formatos evoluem independentemente (spec.md, PLAN.md do GSD vendorizado, tasks.md, código). Mudança no GSD redux (histórico de semver trap) pode quebrar o pass silenciosamente.
- Superfície de confusão de fronteira: `--analyze` pisa no território de gsd-code-review / gsd-audit-uat / @qa → risco de 3 ferramentas auditando o mesmo eixo com vereditos divergentes; delta-spec.md precisa de update cirúrgico.
- `--converge` precisa de 4 classes de gap bem definidas — taxonomia vaga gera ruído de gaps falsos (mesmo modo de falha do drift-warning ambíguo já registrado em memória).

**Stance B:** KEEP · Confiança MEDIUM

### STANCE RECONCILIADO — **ROBUSTO**
Os dois juízes **convergem totalmente** em três pontos: (1) o GAP é real e bem-escopado; (2) a forma (subcomando, não skill nova; reuso do parser) é correta; (3) o risco do gate-LLM é o ponto cego do REPORT.md original e **deve ser blindado antes de shipar**. A NASA endossa exatamente isso. **Decisão: KEEP, condicionado a um núcleo determinístico** (grep de IDs órfãos, contagem de requisitos sem cenário, cross-ref de paths spec↔código) que seja o **gate duro**, com os passes LLM rotulados explicitamente **ADVISORY** no header do relatório — nunca tratados como PASS/FAIL por step downstream. Adicionar fixture-regression que alimenta um drift spec-vs-código conhecido e exige que `--analyze` o detecte. `--converge` estritamente append-only.
**Confiança final:** HIGH na direção / MEDIUM na blindagem (depende de R11-01 resolver o gate-LLM).

---

## R2 — Escada de 6 degraus de simplicidade (operating-discipline item 4)

### Juiz A (Valor/ROI)
**Forças:** custo trivial (edição em rule de 98 linhas; propagado de graça por build-adapters). O degrau "feature nativa antes de dependência" é delta real e ausente — valor preventivo concreto contra dependency bloat.
**Fraquezas:** os outros 5 degraus são re-frase do que o item 4 já diz. Disciplina por texto adicional tem retorno decrescente — o agente já tem o princípio.
**Stance A:** KEEP · MEDIUM — "absorver SÓ o degrau novo".

### Juiz B (Risco/Manutenção)
**Forças:** o degrau "feature nativa antes de dependência" é delta GENUÍNO e casa com token-economy/mcp-hygiene. Custo trivial, zero código novo.
**Fraquezas:** colisão/duplicação confirmada — item 4 já tem 3 heurísticas; uma escada de 6 degraus vira heurística-sobre-heurística e o degrau novo se perde. **Dilui uma rule sempre-on** (carrega em TODA sessão via build-adapters). Transformar "imponha simplicidade" (postura) em checklist de 6 passos é ironicamente uma complicação.
**Stance B:** DOWNGRADE · MEDIUM.

### STANCE RECONCILIADO — **ROBUSTO na substância**
A divergência de rótulo (KEEP vs DOWNGRADE) é superficial: **ambos prescrevem a mesma ação** — absorver **apenas** o degrau "feature nativa antes de dependência" como **uma linha** no item 4, **rejeitar a escada inteira**. A NASA reforça: edição em rule existente, zero novo arquivo de rule. **Decisão: DOWNGRADE de escopo — uma linha, não seis.** Vai no PR de hardening, não em milestone.
**Confiança final:** MEDIUM.

---

## R3 — recursive-decomposition (orchestration.md)

### Juiz A (Valor/ROI)
**Forças:** orchestration.md tem só 29 linhas — espaço para disciplina de consumo de contexto hoje implícita; melhor retorno/esforço dos garimpos voltagent segundo o relatório. Pareia com wave-based existente.
**Fraquezas:** sobrepõe context-engineering + token-economy + Sequential Phases/Strategic Compact já existentes; delta líquido estreito. Sem gatilho operacional vira parágrafo aspiracional ignorado sob pressão.
**Stance A:** DOWNGRADE · MEDIUM.

### Juiz B (Risco/Manutenção)
**Forças:** tema legítimo; orchestration.md é a casa correta; custo baixo.
**Fraquezas:** sobreposição forte com "Sequential Phases with Output Files" que já É decomposição recursiva. Colide também com a skill /context-engineering (v8) → mesma ideia em 2 lugares com fraseado divergente. Conceito vago vira prosa motivacional sem gate.
**Stance B:** DOWNGRADE · MEDIUM.

### STANCE RECONCILIADO — **ROBUSTO**
Convergência total: **só vale com um critério OPERÁVEL novo** (ex.: limiar de profundidade de decomposição / gatilho de contexto), não mais prosa. Como disciplina-pura é eco do que já existe. **Decisão: DOWNGRADE — backlog até haver um gatilho acionável.**
**Confiança final:** MEDIUM.

---

## R4 — Precedência de instrução (CLAUDE.md-usuário > skill > default)

### Juiz A (Valor/ROI)
**Forças:** delta limpo de valor desproporcional ao custo — torna explícita uma precedência hoje ambígua, resolvendo classe real de conflito de instrução. Uma linha que previne retrabalho e desobediência silenciosa.
**Fraquezas:** precisa ser fiel à hierarquia real do harness (CLAUDE.md tem precedência declarada como OVERRIDE) — escada inventada que contradiga o mecanismo real seria pior que nada. Valor preventivo difícil de medir; pode virar letra-morta.
**Stance A:** KEEP · HIGH.

### Juiz B (Risco/Manutenção)
**Forças:** delta GENUÍNO confirmado — NÃO existe regra de precedência CLAUDE.md-usuário > skill > default em lugar nenhum do source/. Alto valor por baixo custo; edição pequena, propagação automática.
**Fraquezas:** risco de colisão de AUTORIDADE com agent-authority.md e a Constitution AIOX — "precedência de instrução" não pode contradizer "Agent Authority NON-NEGOTIABLE". operating-discipline talvez não seja a casa ideal (é sobre CONDUTAS, não hierarquia de fontes) — talvez caiba melhor numa rule própria curta de 5 linhas. Precedência em prosa não é enforçável (diretriz, não gate).
**Stance B:** KEEP · MEDIUM.

### STANCE RECONCILIADO — **ROBUSTO**
Ambos KEEP, ambos identificam o **mesmo risco**: o fraseado deve ser fiel à hierarquia real do harness E não colidir com agent-authority/Constitution. **Decisão: KEEP, com posicionamento cuidadoso.** Sinal de divergência menor sobre a **casa**: A aceita item no operating-discipline; B prefere rule própria de ~5 linhas para não fazer operating-discipline virar guarda-chuva heterogêneo. Recomendação: rule própria curta (alinhada à preocupação de B) que **referencie** o OVERRIDE já declarado no CLAUDE.md em vez de re-declarar uma escada concorrente.
**Confiança final:** HIGH no valor / MEDIUM na implementação.

---

## R5 — Rubric de 5 eixos para promoção de instinct (/evolve)

### Juiz A (Valor/ROI)
**Forças:** a intenção (subir a barra de promoção de instinct) é saudável — instinct ruim promovido a rule global polui todos os produtos.
**Fraquezas:** **DUPLICA capacidade existente** — /evolve já tem gate (confidence≥0.7 + promoted flag + decay + dedup). Substitui um gate que funciona por outro mais pesado sem evidência de falha. Aumenta complexidade de skill madura, contra Enforce Simplicity. Custo de oportunidade vs R1.
**Stance A:** DROP · MEDIUM.

### Juiz B (Risco/Manutenção)
**Forças:** GAP real — /evolve hoje tem só confidence≥0.7 + classificação binária; rubric de 5 eixos torna a decisão menos subjetiva. Mora em skill on-demand (não infla sessão); promoção é baixa-frequência e reversível.
**Fraquezas:** 5 eixos aplicados por LLM sem gate determinístico — risco de virar ritual de preenchimento. Over-engineering de decisão hoje funcional (relatório classifica LOW). Drift conceitual: a rubric do voltagent foi desenhada para outro pipeline; mapear aos campos reais do frontmatter (confidence/evidence_count/updated/scope) exige cuidado.
**Stance B:** KEEP · LOW.

### STANCE RECONCILIADO — **DIVERGÊNCIA MATERIAL → DECISÃO DO USUÁRIO**
Os juízes **discordam no rótulo** (A: DROP / B: KEEP-LOW) mas **concordam no diagnóstico**: o gate atual de /evolve funciona, e o ganho é incremental. A divergência real é apetite por refinamento: A vê custo de oportunidade (tempo não-gasto em R1) e duplicação; B vê refinamento legítimo de baixo risco SE os 5 eixos mapearem a campos reais. **Sinal honesto:** o peso converge para **DROP/adiar** — nenhum juiz tem confiança alta no KEEP, e a NASA não lista R5 entre os deltas que preservam integridade com prioridade. Recomendação prática: **não financiar até que o threshold de 0.7 demonstre falhar na prática**; se absorver, garantir mapeamento aos campos REAIS do instinct (não checklist decorativo).
**Confiança final:** LOW.

---

## R6 — Marcador `// debt:` + coletor no idea-doctor

### Juiz A (Valor/ROI)
**Forças:** marcador + grep é padrão barato e auditável (CLI, não MCP — alinhado a token-economy). idea-doctor.sh já existe e absorve um check WARN sem custo de infra. Torna dívida visível sem cerimônia.
**Fraquezas:** convenção só vale se adotada consistentemente; sem hook que force o registro, compete com // TODO/// FIXME e fragmenta a sinalização. WARN é facilmente ignorado — risco de ruído de relatório.
**Stance A:** KEEP · MEDIUM.

### Juiz B (Risco/Manutenção)
**Forças:** mecanicamente trivial e seguro — idea-doctor.sh é read-only e já tem helper warn(); zero ocorrências de 'debt:' hoje (sem colisão). WARN é a severidade certa.
**Fraquezas:** **RISCO DE RUÍDO E EROSÃO** — grep ingênuo varre node_modules, .aiox-core pristine, GSD vendorizado, ui-ux-pro-max vendorizado → falsos positivos em código de terceiros. Precisa de escopo cirúrgico (só source/+scripts/). **Observer-effect** (já em memória: secret-scanner) — pode contar o próprio exemplo na doc. Dívida-marcador sem prazo/owner só acumula → WARN que nunca zera **treina o usuário a ignorar o doctor inteiro**, degradando o sinal de TODOS os outros checks. Marcador `// debt:` é C-style — não casa com Python/bash/markdown do source/.
**Stance B:** DOWNGRADE · MEDIUM.

### STANCE RECONCILIADO — **ROBUSTO na substância**
B identifica riscos que A subestimou (erosão do sinal do doctor, observer-effect, comment-style). **Decisão: DOWNGRADE — só absorver com (1) escopo restrito a source/+scripts/, (2) marcador comment-agnóstico, (3) contagem que ignore o próprio exemplo.** Sem essas três condições, vira ruído permanente. Vai no PR de hardening, condicionado.
**Confiança final:** MEDIUM.

---

## R7 — Taxonomia de 9 eixos como CHECKLIST.md no /grelha

### Juiz A (Valor/ROI)
**Forças:** taxonomia de 9 eixos como CHECKLIST.md dá ao /grelha estrutura de cobertura reutilizável — modesto reforço de completude.
**Fraquezas:** /grelha já é skill madura (v9, mattpocock) com fluxo de árvore de decisão próprio; checklist importado de cultura greenfield (spec-kit) pode rigidificar um processo deliberadamente adaptativo. Marcado opcional (R11-03) pelo próprio relatório — baixa convicção.
**Stance A:** DOWNGRADE · MEDIUM.

### Juiz B (Risco/Manutenção)
**Forças:** aditivo e bem-localizado — /grelha já tem ADR-FORMAT.md e CONTEXT-FORMAT.md como resources, então CHECKLIST.md segue o padrão. Recurso on-demand; risco baixo.
**Fraquezas:** risco de RIGIDEZ contra a natureza colaborativa/fluida do /grelha (1 pergunta por vez, árvore adaptativa). Sobreposição com CONTEXT-FORMAT.md / 5 regras de ouro. **Menor prioridade do lote (R11-03 explicitamente OPCIONAL)** — absorver agrega manutenção de doc que pode nunca ser consultado.
**Stance B:** DOWNGRADE · LOW.

### STANCE RECONCILIADO — **ROBUSTO**
Convergência total: **backlog, não milestone.** Solução à procura de problema; só absorver se /grelha demonstrar lacuna de cobertura real. A NASA concorda que incluí-lo no enunciado do v11 dilui o foco e acopla duas skills não-relacionadas. **Decisão: DOWNGRADE → backlog; cortar de qualquer milestone de spec.**
**Confiança final:** LOW–MEDIUM.

---

## R8 — Conceito reflexion (triagem quick-vs-deep, fonte GPL-3.0)

### Juiz A (Valor/ROI)
**Forças:** disciplina de licença correta — reconhece GPL-3.0 e absorve só o conceito, protegendo a base MIT/limpa. Conceito reflexion (auto-avaliar antes de aprofundar) é genericamente útil e barato como nota.
**Fraquezas:** IdeiaOS já tem triagem quick-vs-deep espalhada (gsd-fast vs gsd-plan-phase, /doubt em-voo, reflexão de orchestration). Delta líquido ~nulo. Absorver "só o conceito" de algo já presente é trabalho cerimonial.
**Stance A:** DROP · MEDIUM.

### Juiz B (Risco/Manutenção)
**Forças:** disciplina de licença confirmada — zero menção a 'reflexion' nem código GPL em source/ ou docs/decisions/ hoje. Conceito quick-vs-deep é útil e não exige código.
**Fraquezas:** **RISCO DE LICENÇA real e severo se mal-executado** — "só o conceito" é linha tênue; qualquer cópia de estrutura de prompt/nomes de fases/pseudo-código GPL contamina. Valor entregável quase nulo (já implícito no /idea + gsd-fast). Não é entregável verificável — é nota mental; não merece rec_id próprio.
**Stance B:** DROP · MEDIUM.

### STANCE RECONCILIADO — **ROBUSTO**
Convergência total: **DROP.** Conceito já coberto por /idea+gsd-fast/orchestration; o downside (contaminação GPL) é assimetricamente maior que o upside (nulo). A NASA confirma higiene GPL limpa hoje e o classifica como SKIP correto. **Decisão: DROP → registrar apenas como nota de quarentena/não-absorção no ADR de licença** ("avaliamos, é GPL, absorvemos zero código, conceito já presente").
**Confiança final:** MEDIUM.

---

## v11 — Milestone "Auditoria da Camada de Spec" (R11-01/02 + R11-03 opcional)

### Juiz A (Valor/ROI)
**Forças:** escopo enxuto e honesto (2 deltas reais + 1 opcional), ancorado em GAP confirmado, com ADR registrando a tese ("minerar prompts, não importar premissa greenfield"). Reforça o único diferencial competitivo defensável (delta-spec brownfield).
**Fraquezas:** **custo de oportunidade alto AGORA** — v10 (Lovable MCP) em escopo PARCIAL com Fases C/D parqueadas-gated e contenção que JÁ regrediu (2/5→5/5 no mesmo dia). Abrir v11 antes de fechar v10 espalha foco e deixa risco de segurança em aberto. Herda o risco não-mitigado de R1 (gate-LLM). R11-03 já é opcional e o mais fraco — incluí-lo dilui o foco.
**Stance A:** DOWNGRADE · HIGH — "tese certa, timing e blindagem errados".

### Juiz B (Risco/Manutenção)
**Forças:** recorte sensato (subcomandos, não skills novas; reusa parser; prevê atualizar delta-spec.md + ADR). R11-02 (--converge append-only) é o mais alinhado ao brownfield e de menor risco. Tamanho honesto; relatório recomenda /grelha sobre o recorte antes de implementar.
**Fraquezas:** o nome "Auditoria" promete RIGOR mas o motor de R11-01 é LLM sem gate de conteúdo — título superdimensiona a garantia real. **Misturar R11-03 (taxonomia no /grelha) no mesmo milestone acopla duas skills não-relacionadas** — corte. Dependência de fronteira frágil com o GSD vendorizado (semver trap revertido 3×). Empacotar R2-R7 num "PR único de hardening" é arriscado: 4 edições de prosa em rules sempre-on de uma vez, sem medir ganho marginal de cada, é absorver dívida de diluição em lote.
**Stance B:** KEEP-com-cortes · MEDIUM.

### STANCE RECONCILIADO — **DIVERGÊNCIA MATERIAL → DECISÃO DO USUÁRIO**
A divergência é de **eixo diferente**, e por isso não se cancela:
- **Juiz A diverge no TIMING** (DOWNGRADE): feche o v10 de verdade primeiro — maior alavancagem de risco. Sequencie R1 sozinho como milestone enxuto OU dobrado no fechamento do v10.
- **Juiz B diverge na FORMA** (KEEP-com-cortes): a forma é boa, mas **corte R11-03** (acopla grelha a spec) e **resolva o gate-LLM antes de chamar de "auditoria"**.

**Onde AMBOS concordam (robusto):** (1) núcleo determinístico obrigatório antes dos passes LLM; (2) R11-03 fora do milestone; (3) `--analyze`/`--converge` como subcomandos, não skills novas; (4) os deltas-S (R2/R4/R6) **não** devem ser absorvidos em lote sem corte de escopo individual. A NASA endossa a forma e adiciona o guard-rail decisivo: **manter os passes LLM ADVISORY (não gated)** e o teto: zero novas skills/rules top-level — a única falha seria scope-creep durante a implementação.

**Recomendação de síntese para o usuário decidir:** financiar **R11-01/02 com núcleo determinístico + rótulo ADVISORY + R11-03 cortado**, e decidir o **timing** (milestone v11 enxuto agora **vs** dobrar no fechamento do v10) — esta é a escolha que as lentes deixam em aberto.
**Confiança final:** MEDIUM-HIGH (alta na forma/blindagem; o timing é genuinamente uma decisão de prioridade do usuário).

---

## Síntese de robustez

- **ROBUSTO (os dois juízes convergem na ação):** R1 (KEEP+blindar), R2 (só o degrau novo), R3 (backlog/critério operável), R4 (KEEP+posicionar), R6 (DOWNGRADE+escopo), R7 (backlog), R8 (DROP).
- **DIVERGÊNCIA → DECISÃO DO USUÁRIO:** R5 (DROP vs KEEP-LOW; peso para DROP/adiar), v11 (timing vs forma; convergem na blindagem, divergem em quando/como empacotar).
- **Padrão de risco transversal nomeado por ambos:** a fronteira shell-determinístico vs LLM. O arsenal /spec hoje é DURO (exit code binário); R1 introduz pela primeira vez julgamento LLM mascarado de gate. Blindar isso é a pré-condição de toda a camada de validação — caso contrário o IdeiaOS **degrada sua própria disciplina ao absorver**.
