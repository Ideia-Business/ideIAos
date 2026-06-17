---
phase: D-gate-deia
plan: D-01
type: execute
wave: 2
depends_on: [B-grelha-glossario]
autonomous: false
requirements: [R9-04]
files_modified:
  - source/skills/idea/SKILL.md
must_haves:
  truths:
    - "A Deia ganha um Passo 1.5 (gate de alinhamento) entre a classificação (Passo 1) e a delegação à camada (Passo 2)"
    - "O gate é OPCIONAL e ESCAPÁVEL — oferece /grelha quando detecta risco/ambiguidade, mas 'manda ver'/pedido de velocidade pula direto"
    - "A heurística de disparo cobre: pedido vago; termo de domínio sobrecarregado/ausente; blast-radius alto (multi-tenancy/migration/RLS/API pública); feature nova grande"
    - "Pedido mecânico/claro (fix pequeno, rename) NUNCA dispara o gate (sem fricção)"
    - "Roteamento permanece transparente (mostra o comando antes de executar) — princípio #2 do IDEIAOS.md"
    - "Nota de fronteira /grelha × gsd-discuss-phase × /doubt adicionada (espelha a nota /spec × GSD existente)"
  artifacts:
    - path: "source/skills/idea/SKILL.md"
      provides: "Passo 1.5 (gate de alinhamento) + 2ª linha de matriz + nota de fronteira"
      contains: "Passo 1.5"
  key_links:
    - from: "source/skills/idea/SKILL.md"
      to: "/grelha"
      via: "Passo 1.5 oferece /grelha antes do roteamento"
      pattern: "/grelha"
---

<objective>
Integrar o `/grelha` à orquestração da Deia como **gate de alinhamento opcional** (Passo 1.5), disparado por risco/ambiguidade ANTES do roteamento para GSD/AIOX/Lovable. Fecha **R9-04** (GAP 2 — o grilling na hora certa, sem virar fricção).

Purpose: hoje a Deia classifica e roteia direto para execução. Falta o portão de alinhamento. O Passo 1.5 oferece o grilling quando o pedido é vago/arriscado — mas **respeita o princípio "comando direto é caminho válido"** (ADR v9-postura): oferece, não obriga; "manda ver" pula. Isso resolve a tensão anti-framework — o humano nunca perde o controle.

Output: edições cirúrgicas em `source/skills/idea/SKILL.md` (Passo 1.5 + 2ª linha de matriz + nota de fronteira + 1 exemplo canônico). Aditivo — nenhuma rota existente removida.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@docs/research/2026-06-16-mattpocock-skills-analise.md   # §5 "Como a Deia orquestraria"
@docs/decisions/v9-mattpocock-skills-absorcao.md
@.planning/milestones/v9-REQUIREMENTS.md
@source/skills/idea/SKILL.md
@source/skills/grelha/SKILL.md
@docs/IDEIAOS.md   # princípios: comando direto válido; roteamento transparente
</context>

<tasks>

<task type="auto">
  <name>Task 1: Adicionar o Passo 1.5 (gate de alinhamento) na lógica de roteamento</name>
  <files>source/skills/idea/SKILL.md</files>
  <action>
Inserir, ENTRE a seção "Passo 1 — Ler o pedido e classificar" e "Passo 2 — Verificar pré-condições", uma nova seção **"Passo 1.5 — Gate de alinhamento (opcional)"**:

```
### Passo 1.5 — Gate de alinhamento (opcional, antes de rotear)

Antes de delegar à camada de execução, avalie se vale **grelhar antes** (alinhar +
afiar o vocabulário). Dispare a OFERTA de `/grelha` quando ≥1 for verdadeiro:

- **Pedido vago** — "melhorar", "deixar melhor", "resolver o problema do X", sem critério claro.
- **Termo de domínio sobrecarregado/ausente** — o pedido usa um conceito que conflita com o
  `CONTEXT.md` (glossário) ou que não tem termo canônico ainda.
- **Blast-radius alto** — multi-tenancy, migration/DDL, RLS/policy, mudança de API pública,
  fluxo de pagamento, auth/authz.
- **Feature nova grande** — não é fix mecânico; tem árvore de decisão com dependências.

Se nenhum for verdadeiro (fix pequeno, rename, ajuste óbvio, pedido já claríssimo) → **pule**
direto para o Passo 2. NUNCA grelhe trabalho mecânico.

A oferta é **transparente e escapável**:

  🎯 Antes de planejar, recomendo uma sessão rápida de /grelha:
  Razão: <qual sinal disparou — ex. "toca RLS multi-tenant (blast-radius alto)">
  Quer alinhar primeiro? [Sim, grelhar] · [Manda ver — pula direto pro <comando>]

Se o usuário disser "manda ver" / pedir velocidade explícita → roteia direto (Passo 2).
Se aceitar → invoca `/grelha --docs`; ao concluir (CONTEXT.md/ADR atualizados), retoma o
roteamento original do Passo 2 já com o vocabulário alinhado.
```

Manter o estilo/voz da skill existente. Aditivo — não renumerar os passos seguintes além de inserir 1.5.
  </action>
  <verify>
    <automated>grep -q 'Passo 1.5' source/skills/idea/SKILL.md && grep -qi 'manda ver' source/skills/idea/SKILL.md && grep -qi 'blast-radius\|multi-tenancy\|RLS' source/skills/idea/SKILL.md && grep -q '/grelha' source/skills/idea/SKILL.md && echo OK</automated>
  </verify>
  <done>Passo 1.5 presente com heurística de disparo (4 gatilhos), regra de skip para mecânico, oferta escapável ("manda ver"), e retomada do roteamento.</done>
</task>

<task type="auto">
  <name>Task 2: 2ª linha de matriz (glossário) + nota de fronteira</name>
  <files>source/skills/idea/SKILL.md</files>
  <action>
1. Adicionar a 2ª linha de matriz (a 1ª foi na Fase B):
   `| "qual o vocabulário do domínio", "monta o glossário", "padroniza os termos", "linguagem ubíqua" | **Alinhamento** → /grelha --docs (foco em CONTEXT.md) |`
2. Adicionar, perto da nota de fronteira `/spec × GSD` já existente na skill, a **nota de fronteira `/grelha × gsd-discuss-phase × /doubt`** (resumo, 3-4 linhas):
   > Fronteira: `/grelha` alinha COM o humano ANTES de existir plano (à la carte, serve até não-código) e produz glossário durável. `gsd-discuss-phase` faz o mesmo DENTRO de uma fase GSD já aberta (decisões da fase). `/doubt` audita CONTRA decisões já tomadas. Em dúvida: `/grelha` primeiro, GSD depois, `/doubt` nas decisões críticas.
3. (Opcional) Adicionar 1 exemplo canônico curto na seção de exemplos: pedido vago de alto risco → Deia oferece `/grelha` → usuário aceita → roteia pra GSD com vocabulário alinhado.
  </action>
  <verify>
    <automated>grep -qi 'monta o glossário\|linguagem ubíqua' source/skills/idea/SKILL.md && grep -qi 'gsd-discuss-phase' source/skills/idea/SKILL.md && echo OK</automated>
  </verify>
  <done>2ª linha de matriz (glossário) + nota de fronteira tripla presentes; rotas existentes intactas.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
Gate de alinhamento opcional na Deia (Passo 1.5) + 2 linhas de matriz + nota de fronteira tripla. Oferece grilling por risco/ambiguidade, escapável, transparente.
  </what-built>
  <how-to-verify>
1. Ler o Passo 1.5: confirmar que é OFERTA (não imposição), que "manda ver" pula, e que fix mecânico nunca dispara.
2. **Teste de não-regressão do roteamento** (crítico): rodar a suíte de evals da Deia se houver (`evals/`), OU validar manualmente 4-5 pedidos canônicos do SKILL.md atual (ex. "implementa OAuth", "retoma do Cursor", "fix rápido") e confirmar que continuam roteando como antes — o Passo 1.5 só ADICIONA uma oferta, não muda rotas.
3. Validar 2 casos novos: (a) pedido vago de alto risco ("mexer no acesso multi-tenant") → Deia oferece /grelha; (b) "fix rápido no label do botão" → Deia NÃO oferece, roteia direto.
  </how-to-verify>
  <resume-signal>Digite "aprovado: D" ou ajustes na heurística de disparo.</resume-signal>
</task>

</tasks>

<verification>
R9-04: Passo 1.5 com heurística (vago/termo-sobrecarregado/blast-radius/feature-grande) — Task 1; opt-in/escapável ("manda ver") — Task 1; transparência preservada — Task 1; 2 linhas de matriz + nota de fronteira — Tasks 1/2.
</verification>

<success_criteria>
- Passo 1.5 presente, opcional e escapável; pedido mecânico/claro não dispara.
- Heurística cobre os 4 gatilhos de risco/ambiguidade.
- Roteamento permanece transparente; nenhuma rota existente removida (não-regressão validada).
- Nota de fronteira `/grelha × gsd-discuss-phase × /doubt` + 2ª linha de matriz (glossário).
</success_criteria>

<notes>
## Risco principal: regressão de roteamento
A Deia é o ponto de entrada de tudo. O Passo 1.5 deve ser **puramente aditivo** — uma oferta antes do roteamento, nunca uma mudança nas rotas existentes. A verificação de não-regressão (rodar evals/ ou casos canônicos) é o gate que protege isso.

## Paraleliza com Fase E
D e E dependem só de B (e C para a parte de ADR de E). Podem rodar em paralelo após B/C.

## Postura
O caráter opcional/escapável do gate É a materialização da decisão do ADR `v9-mattpocock-skills-absorcao.md` (absorver técnica sob orquestração, sem comprar a ideologia anti-framework).
</notes>

<output>
Criar `.planning/milestones/v9-phases/D-gate-deia/D-01-SUMMARY.md` ao concluir.
</output>
