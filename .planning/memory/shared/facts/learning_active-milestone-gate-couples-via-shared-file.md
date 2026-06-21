---
name: learning-active-milestone-gate-couples-via-shared-file
description: "Uma fase nova logicamente independente fica TEMPORALMENTE acoplada a um milestone em SOAK quando edita um arquivo que o gate desse milestone RE-EXECUTA no fechamento — editar agora pode corromper a tag ativa, mesmo sem compartilhar escopo."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

Ao planejar v14.0 (Cockpit) com o v13 (Security Freshness) ainda em SOAK, o gate do v14.0
parecia ortogonal ao v13. Não era: o **plano `14.0-01` modifica `scripts/idea-doctor.sh`**, e o
heartbeat pendente do v13 grava `idea_doctor=PASS|regression=PASS` **RODANDO o `idea-doctor` ao
vivo** no momento da re-gravação (`check-soak --record`). Logo, mexer no `idea-doctor.sh` antes do
v13 tagar faz a próxima re-gravação do v13 executar o script modificado — qualquer aresta corrompe
o selo do v13 no exato instante em que ele tenta fechar o span e tagar.

**Why:** "não entrelaçar milestones ativos" costuma soar como higiene de processo (foco cognitivo).
A mordida real é **acoplamento de runtime por artefato compartilhado**: um gate que **re-executa
uma ferramenta** no fechamento (SOAK roda `idea-doctor` + a suíte de regressão) cria dependência
temporal invisível com qualquer fase que **edite essa ferramenta**. Independência lógica de escopo
≠ independência temporal quando há um gate aberto que roda o arquivo tocado.

**How to apply:** antes de executar uma fase nova com outro milestone em SOAK, **cruze o
`files_modified` da fase contra os arquivos que o gate aberto executa** (aqui: `idea-doctor.sh` + a
suíte de regressão que o `check-soak --record` invoca). Houve sobreposição → **adie a fase (ou ao
menos o plano ofensor) até o milestone ativo tagar**. Se precisar prosseguir mesmo assim, rode só os
planos NÃO-sobrepostos (ex.: Wave 1 do v14.0 **menos o `14.0-01`** — os outros 3 planos não tocam o
`idea-doctor.sh`). O critério é binário: `git diff` da fase ∩ ferramentas-do-gate = ∅ ?

**Bônus (mesma sessão, revisão adversarial multi-lente do PLAN):** o painel de 3 verificadores
(plan-checker + security-reviewer + auditor antifragile) pegou 6 defeitos reais no plano antes de
qualquer execução — o mais insidioso foi **gate-theater**: um acceptance `[ "$B" = "$(cat … ||
echo $B)" ]` cujo fallback ecoa o próprio valor comparado → **sempre passa** (antifrágil aparente,
verificação vazia). Lição: rode a verificação adversarial sobre o PLANO, não só sobre o código;
e desconfie de gate cujo lado-direito pode degradar para o lado-esquerdo.

Cross-link: [[learning-soak-span-is-record-delta-not-wallclock]] (o span é delta de gravações, não
wall-clock — por isso o v13 ainda não tagou), [[project-milestone-v13-security-freshness]],
[[project-milestone-v14-cockpit]]. Eixo determinístico em `antifragile-gates` (exit-code é lei).
