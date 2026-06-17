---
name: dogfood-review-tool-catches-own-defect
description: Rode a própria ferramenta de revisão/disciplina sobre o milestone que a entrega — ela pega defeitos em si mesma. Doubt-driven adversarial achou uma citação FABRICADA dentro da skill /doubt
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**Por quê:** No v8 (Camada de Disciplina), depois de autorar a skill `/doubt` (doubt-driven: revisor adversarial de contexto-fresco), rodei ela sobre o próprio diff do milestone via subagente adversarial issues-only. O achado nº1: a `/doubt` afirmava `agent-authority.md` ("personas não invocam outras personas") — uma **citação literal de uma frase que não existe em lugar nenhum do repo**. A skill cuja razão de existir é pegar "afirmação confiante não-verificada" tinha inventado uma autoridade para si mesma. Autoria confiante não pega isso; revisão adversarial de contexto-fresco pega. Outros achados do mesmo passe: contradição manifesto×membership e um agente built-in citado sem nota.

**How to apply:** Sempre que escrever/absorver uma ferramenta de **revisão, disciplina ou verificação** (review skill, gate, checklist, lint, rule de conduta), aplique-a ao próprio entregável que a introduz antes de fechar — dogfood imediato. Para conteúdo absorvido/autorado, trate toda **citação entre aspas** como claim verificável: faça grep da frase no alvo citado; se não existir literalmente, é invenção (remova ou substitua por referência real). Revisão adversarial de **contexto fresco** (subagente, prompt "encontre o que está errado", sem passar sua conclusão) acha o que autoria confiante mascara. Pareia com [[learning_declarative-manifest-vs-imperative-list-drift]] e [[learning_fixture-precreation-masks-bootstrap-bugs]] — todos são "valide no caminho que mais expõe o defeito".
