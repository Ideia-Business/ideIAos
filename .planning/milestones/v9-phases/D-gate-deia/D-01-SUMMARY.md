# D-01-SUMMARY — Fase D: gate de alinhamento opcional na Deia (Passo 1.5)

**Milestone:** v9 · **Fase:** D · **Status:** ✅ DONE · **Cobre:** R9-04 · **Data:** 2026-06-17
**Modo:** workflow (paralelo com Fase C — arquivos disjuntos) + revisor goal + revisor de não-regressão

## Entregue

Edições **puramente aditivas** em `source/skills/idea/SKILL.md` (52 inserções / 0 deleções):
1. **Passo 1.5 — Gate de alinhamento (opcional, antes de rotear)** entre Passo 1 e Passo 2: heurística de 4 gatilhos (pedido vago; termo de domínio sobrecarregado/ausente; blast-radius alto = multi-tenancy/migration/DDL/RLS/API pública/pagamento/auth; feature nova grande); regra de SKIP para mecânico ("NUNCA grelhe trabalho mecânico"); oferta transparente e escapável (`[Sim, grelhar] · [Manda ver — pula direto pro <comando>]`); retomada do Passo 2 via `/grelha --docs` ao aceitar.
2. 2ª linha de matriz (foco vocabulário/glossário → `/grelha --docs`).
3. Nota de fronteira `/grelha × gsd-discuss-phase × /doubt` (ao lado da nota `/spec × GSD`).
4. Exemplo 6 canônico (pedido vago de alto risco multi-tenant → oferece `/grelha` → roteia GSD com vocabulário alinhado).

## Verificação

- **Revisor goal-backward: PASS** — R9-04 atendido (Passo 1.5 posicionado, 4 gatilhos, skip mecânico, opt-in/escapável, transparência preservada, 2ª linha + fronteira tripla).
- **Revisor de NÃO-REGRESSÃO: PASS** — diff **puramente aditivo** (52/0); 5 pedidos canônicos (OAuth→/gsd-do, Cursor→/cursor-continuation, fix→/gsd-quick, carrossel→/marketing, Lovable→/lovable-handoff) roteiam IDÊNTICO; gate dispara certo (mecânico=não, vago+alto-risco=sim). Nenhuma rota removida/alterada.
- **Pós-revisão:** deduplicada a sobreposição de gatilhos entre a linha de matriz nova (D) e a de B (a 2ª linha agora foca termos de vocabulário distintos) — LOW do revisor de não-regressão, corrigido.

## Carry-forward
- Fase F: a não-regressão de roteamento será reconfirmada no gate final (idea-doctor + casos canônicos).
