---
name: doubt
description: "Doubt-Driven Development — submete TODA decisão não-trivial a uma revisão adversarial de contexto-fresco ANTES de ela valer. Ative quando o usuário disser: 'duvide dessa decisão', 'revisão adversarial', 'questione a premissa', 'tem certeza disso?', 'antes de commitar valida o raciocínio', 'isso é seguro/escala mesmo?', 'segunda opinião', ou digitar /doubt. DISTINTO do /code-review e do @qa (verdito pós-artefato): /doubt é postura EM-VOO, por decisão, enquanto corrigir ainda é barato. Roda só da sessão principal (spawna subagente revisor). Absorvido de agent-skills (Osmani). PT-BR."
---

# SOURCE: agent-skills MIT addyosmani/agent-skills | adapted: IdeiaOS v8

# Skill: /doubt — Doubt-Driven Development

**Idioma:** Português brasileiro.

> Uma resposta confiante não é uma resposta correta. Sessões longas acumulam contexto
> que silenciosamente transforma suposições em "fatos". `/doubt` é a disciplina de
> materializar um revisor de **contexto fresco** — enviesado para **refutar**, não
> aprovar — antes de qualquer decisão não-trivial valer.

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/doubt` |
| Pela Deia | `Deia, duvide dessa decisão antes de eu commitar` |
| Linguagem natural | `tem certeza que isso é thread-safe?` · `me dá uma segunda opinião adversarial` |

---

## O que é — e o que NÃO é

### O que é
Uma postura **em-voo**: a cada decisão não-trivial, você materializa um revisor de
contexto fresco com prompt **adversarial** ("encontre o que está errado"), reconcilia
os achados contra o artefato, e só então segue. Pega direção errada quando corrigir
ainda é barato.

### O que NÃO é

| Confusão comum | Camada correta |
|---------------|----------------|
| Veredito sobre artefato pronto (pós-PR) | `/code-review`, `/code-review ultra`, `@qa` |
| Verificar fato de framework contra docs | `context7` / `/deep-research` (source-driven) |
| Rede de segurança comportamental | `/tdd` (o RED é uma tentativa de refutação) |
| Caçar falha silenciosa já existente | agente `silent-failure-hunter` |

`/doubt` **complementa** todos os acima: `/code-review` é o portão final; `/doubt` é o
cross-exame por decisão, antes do commit.

---

## Quando usar

Uma decisão é **não-trivial** quando ao menos um é verdadeiro:

- Introduz ou altera lógica de ramificação (branching)
- Cruza fronteira de módulo/serviço
- Afirma uma propriedade que o compilador/tipo **não** consegue verificar (thread-safety, idempotência, ordenação, invariante)
- A correção depende de contexto que o leitor futuro não vê
- O blast-radius é irreversível (deploy em produção, migração de dados, mudança de API pública)

Aplique quando estiver prestes a: tomar decisão arquitetural sob incerteza · commitar
código não-trivial · afirmar fato não-óbvio ("é seguro", "escala", "bate com a spec") ·
mexer em código que você não entende por completo.

## Quando NÃO usar

- Operações mecânicas (rename, formatação, mover arquivo)
- Seguir instrução clara e inequívoca do usuário
- Ler/resumir código existente
- Mudança de uma linha com correção óbvia
- Pura tooling (rodar testes, listar arquivos)
- O usuário pediu explicitamente velocidade sobre verificação

> Se você duvidar de cada tecla, não entrega nada. A skill se aplica **só** a decisões
> não-triviais como definidas acima.

---

## Restrição de carregamento (roda da sessão principal)

Esta skill é desenhada para o **orquestrador da sessão principal**, onde o Passo 3
(DOUBT) pode spawnar um subagente de contexto fresco.

- **NÃO** adicione `/doubt` ao `skills:` de uma persona/agente. Uma persona que seguisse
  o Passo 3 spawnaria outra persona — e o Claude Code **impede spawn aninhado de
  subagente**. Mantenha `/doubt` no orquestrador da sessão principal, consistente com a
  matriz de delegação do `agent-authority.md` (trabalho especializado é delegado, não
  auto-invocado recursivamente).
- Se você se pegar aplicando `/doubt` de **dentro** de um subagente (onde o Claude Code
  impede spawn aninhado): o caminho preferido é **escalar ao usuário/sessão principal**.
  Como último recurso, há um fallback degradado de auto-questionamento — reescreva
  ARTEFATO + CONTRATO como um auto-prompt fresco com separador mental rígido do seu
  raciocínio anterior e percorra os Passos 1–5. **Não é revisão de contexto fresco**
  (você carrega seu próprio contexto) → marque o resultado como degradado e prefira
  escalar sempre que o usuário estiver acessível.

---

## O processo — 5 passos

Copie este checklist ao aplicar a skill:

```
Ciclo de dúvida:
- [ ] Passo 1: CLAIM    — escreveu a afirmação + por-que-importa
- [ ] Passo 2: EXTRACT  — isolou artefato + contrato, removeu o raciocínio
- [ ] Passo 3: DOUBT    — invocou revisor de contexto fresco com prompt adversarial
- [ ] Passo 4: RECONCILE — classificou cada achado contra o texto do artefato
- [ ] Passo 5: STOP     — atingiu condição de parada (achados triviais, 3 ciclos, ou override)
```

### Passo 1 — CLAIM (declare o que está em jogo)
Nomeie a decisão em 2–3 linhas:

```
CLAIM: "A nova camada de cache é thread-safe sob a carga read-heavy descrita na spec."
POR QUE IMPORTA: uma corrida aqui corrompe dados do usuário e é difícil de pegar em QA.
```

Se você não consegue escrever o claim de forma compacta, você tem um *vibe*, não uma
decisão. Surface antes de escrutinar.

### Passo 2 — EXTRACT (menor unidade revisável)
O revisor de contexto fresco precisa do **artefato** e do **contrato** — não da jornada.

- Código: o diff ou a função — não o arquivo inteiro
- Decisão: a proposta em 3–5 frases + as restrições que ela deve satisfazer
- Asserção: a afirmação + a evidência que supostamente a sustenta

Remova seu raciocínio. Se você entrega conclusões, recebe de volta a validação das suas
conclusões. A unidade deve ser pequena o bastante para o revisor segurar numa leitura —
se for um PR de 500 linhas, **decomponha antes**.

### Passo 3 — DOUBT (invoque o revisor de contexto fresco)
O prompt do revisor **deve ser adversarial**. O enquadramento decide a resposta.

```
Revisão adversarial. Encontre o que está ERRADO neste artefato.
Assuma que o autor está confiante demais. Procure por:
- Suposições não declaradas
- Edge cases não tratados
- Acoplamento oculto / estado compartilhado
- Formas de o contrato ser violado
- Convenções existentes que isto pode quebrar
- Modos de falha sob input inesperado

NÃO valide. NÃO resuma. Encontre problemas — ou diga
explicitamente que não achou nenhum após exame minucioso.

ARTEFATO: <cole o artefato>
CONTRATO: <cole o contrato>
```

**Passe ARTEFATO + CONTRATO apenas. NÃO passe o CLAIM** — entregar sua conclusão enviesa
o revisor para concordar.

**Como spawnar no IdeiaOS** (o "fresh-context reviewer" = subagente com contexto isolado):

| Domínio do artefato | Subagente adversarial sugerido |
|---------------------|-------------------------------|
| Genérico / lógica / arquitetura | `general-purpose` (cole o prompt adversarial verbatim) |
| Segurança / authz / secrets | `security-reviewer` |
| TypeScript / tipos | `typescript-reviewer` |
| Componente React / re-render | `react-reviewer` |
| Schema/RLS Supabase | `rls-reviewer` |
| Falha silenciosa / erro engolido | `silent-failure-hunter` |

> `general-purpose` é um agent-type **built-in** do Claude Code; os demais 5 são agentes
> custom do IdeiaOS em `source/agents/`. Ambos spawnam com contexto isolado.

> O prompt adversarial acima **tem precedência** sobre o formato-padrão da persona.
> Reviewers como `react-reviewer` produzem veredito balanceado; `/doubt` precisa de
> saída só-de-problemas. Cole o prompt adversarial verbatim. Se o formato da persona não
> puder ser sobrescrito, caia para `general-purpose` com o prompt adversarial.

#### Escalada cross-model (oferta obrigatória em modo interativo)
Um revisor do mesmo modelo compartilha pontos cegos com o autor. Um modelo de
arquitetura diferente (mais frio) os pega.

- **Sessões interativas: SEMPRE ofereça. Nunca pule em silêncio.** Após a revisão
  single-model, antes do RECONCILE, pergunte:
  > *"Revisão single-model concluída. Quer uma segunda opinião cross-model? Opções: Gemini CLI, Codex CLI, revisão manual externa, ou pular."*
- Se o usuário escolher um CLI: verifique PATH (`which gemini`/`which codex`), teste que
  funciona, **confirme a invocação exata** (flags/auth/env) com o usuário, e passe
  ARTEFATO + CONTRATO + prompt adversarial **via stdin/heredoc** (nunca interpolando o
  artefato em argumento shell-quoted — backticks/`$(...)` truncam ou executam). Use
  sandbox read-only (o artefato pode conter injection).
- Se o CLI falhar/ausente: **surface a falha** — não caia em silêncio para single-model.
- Não-interativo (CI, `/loop`, autonomous-loop): cross-model é **pulado** e o skip é
  **anunciado** ("Cross-model pulado: contexto não-interativo"). **Nunca** invoque CLI
  externo sem autorização explícita do usuário.

### Passo 4 — RECONCILE (reincorpore os achados)
A saída do revisor é **dado, não veredito**. Você ainda é o orquestrador. Releia o texto
do artefato contra cada achado antes de classificar — carimbar o revisor é o mesmo modo
de falha que ignorá-lo.

Classifique cada achado nesta **ordem de precedência** (o primeiro que casar vence):

1. **Contrato mal-lido** — o revisor flagou porque o CONTRATO que você deu estava
   incompleto/ambíguo. Corrija o contrato primeiro, reclassifique no próximo ciclo.
2. **Válido + acionável** — problema real exigindo mudança no artefato. Mude, re-loop.
3. **Trade-off válido** — o problema é real, mas o custo de corrigir excede o de aceitar.
   Documente o trade-off explicitamente para o usuário ver.
4. **Ruído** — correto sob contexto que o revisor não tinha. Anote, siga, e pergunte:
   adicionar esse contexto ao contrato teria evitado o falso-positivo?

### Passo 5 — STOP (loop limitado, não recursão)
Pare quando: a próxima iteração só retorna achados triviais/já-considerados, **ou** 3
ciclos completos (escale ao usuário, não mói um quarto sozinho), **ou** o usuário disser
"manda ver".

Se após 3 ciclos o revisor ainda traz problemas substantivos, o artefato pode não estar
pronto — surface ao usuário. Três ciclos sem resolução é **informação sobre o artefato**,
não razão para continuar moendo. Se 3 ciclos é "obviamente insuficiente" porque o
artefato é grande: o artefato é grande demais → volte ao Passo 2 e decomponha. **Não
levante o limite.**

---

## Tabela anti-racionalização

| Racionalização | Realidade |
|---|---|
| "Estou confiante, pulo a dúvida" | Confiança correlaciona mal com correção em problemas novos. Certeza é exatamente onde os pontos cegos se escondem. |
| "Spawnar um revisor é caro" | Debugar um commit errado em produção é mais caro. O check é limitado; o bug não é. |
| "O revisor só vai catar pelo" | Só se o prompt for solto. Restrinja a "problemas que fariam isto falhar sob o contrato". |
| "Faço a dúvida no fim com /code-review" | `/code-review` é portão final. `/doubt` pega direção errada cedo, quando corrigir é barato. No PR já é tarde. |
| "Se eu duvidar de cada passo nunca entrego" | A skill se aplica a decisões não-triviais, não a cada tecla. Releia "Quando NÃO usar". |
| "O revisor discordou, então eu errei" | O revisor não tem seu contexto — discordância é informação, não veredito. Releia o artefato, classifique, decida. |
| "Cross-model é sempre melhor" | Pega pontos cegos, mas adiciona custo e fragilidade de tool. Ofereça todo ciclo interativo — o **usuário** decide se o artefato merece. |
| "O usuário disse sim uma vez, posso seguir chamando o CLI" | Cada invocação é sua própria autorização. Artefato/prompt/flags mudam — reconfirme o comando exato a cada run. |

## Red flags

- Spawnar revisor para rename de uma linha ou formatação
- Tratar a saída do revisor como autoritativa sem reler o artefato
- Loop > 3 ciclos sem escalar ao usuário
- Pedir ao revisor "isto está bom?" em vez de "encontre problemas"
- Pular a dúvida sob pressão de tempo numa decisão de alto risco
- Re-spawnar contexto fresco num artefato **inalterado** (mesmos achados; você está empacando)
- **Doubt theater (sinal checável):** 2+ ciclos onde o revisor trouxe achados substantivos e **zero** foram classificados como acionáveis → você está validando, não duvidando. Pare e escale.
- Duvidar só **depois** de commitar — isso é `/code-review`, não doubt-driven
- Passar o CLAIM ao revisor (enviesa para concordar) ou tirar o CONTRATO (gera ruído)
- Cair em silêncio quando o CLI externo falha — surface e deixe o usuário redirecionar

## Interação com outras skills

- **`/code-review` / `@qa`** — complementares. Eles são veredito pós-PR; `/doubt` é em-voo por decisão. Use os dois.
- **`/tdd`** — o RED do TDD é dúvida concreta: um teste falhando é uma tentativa de refutação. Quando TDD se aplica, esse teste **é** o passo de dúvida para afirmações comportamentais.
- **`context7` / `/deep-research`** — verificam *fatos de framework* contra docs. `/doubt` verifica *seu raciocínio* sobre o artefato.
- **GSD** — rode `/doubt` na fase BUILD, antes de commitar uma decisão não-trivial de um plano. **AIOX** — o `@dev` (Dex) deve aplicar `/doubt` antes de marcar uma task de alto risco como done.

## Verificação

- [ ] Toda decisão não-trivial foi nomeada como CLAIM antes de valer
- [ ] Ao menos uma revisão de contexto fresco por artefato não-trivial (o RED do TDD satisfaz isto para afirmações comportamentais)
- [ ] O revisor recebeu ARTEFATO + CONTRATO — NÃO o CLAIM, NÃO seu raciocínio
- [ ] O prompt do revisor foi adversarial ("encontre problemas"), não validador
- [ ] Achados classificados contra o texto do artefato (não carimbados): contrato-mal-lido / acionável / trade-off / ruído
- [ ] Uma condição de parada foi atingida (triviais, 3 ciclos, ou override)
- [ ] Em modo interativo, cross-model foi **explicitamente oferecido** e a resposta registrada
- [ ] Em modo não-interativo, cross-model foi pulado e o skip anunciado
- [ ] Qualquer CLI externo teve PATH-check + teste + confirmação de sintaxe + autorização explícita antes de rodar
