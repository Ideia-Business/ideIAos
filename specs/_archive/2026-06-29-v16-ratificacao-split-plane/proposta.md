# Proposta: v16-ratificacao-split-plane

**Capability:** cockpit · **Data:** 2026-06-29 · **Milestone:** v16 (Plataforma de Time)

## Por que

O v16 (Plataforma de Time, split-plane) está em DRAFT, gated por blockers. Dois dos quatro pendentes
para ativá-lo já destravaram: o v15 (DX & Frota) **shippou** (precondição own-fleet, R15-17) e surgiu
um **2º dev real não-admin** (Lucas). O `@security-reviewer` marcou `NEEDS_REVISION` exigindo que o
contrato de comportamento (R-WP12, RLS-por-campo, Admissão) deixe de viver **só no ADR** e vire
**cláusulas SHALL verificáveis** no contrato vivo (must-fix #2 e #3 do ADR).

Esta proposta faz **apenas a ratificação pure-design** — materializa o CONTRATO. Não constrói F1
(read-fan-out), nem a implementação RLS, nem claims (R16-04) ou fila-de-Publish (R16-05), que
permanecem gated por necessidade comprovada (anti-super-construção, conforme o próprio ADR).

## O que muda

4 requisitos **ADICIONADOS** ao contrato `specs/cockpit/spec.md`, todos rastreáveis a fonte:

1. **Plano de View read-only — divergência vira alerta** (R-WP12 pt.1) — fluxo unidirecional; uma
   divergência view↔disco é ALERTA, nunca atualização do estado autoritativo. _(doc 80 §3.4 + ADR must-fix #3)_
2. **Plano de View estruturalmente incapaz de autoridade** (R-WP12 pt.2) — sem coluna `value`, não
   assina, não pina (exit 9 ALERT), não abre verbo, P3 ≠ P4. _(doc 80 §3.1-3.3/§5/§8 + ADR must-fix #3)_
3. **RLS deny-all com mascaramento por-campo por papel** (R16-02) — admin vê tudo, dev só o seu
   escopo; `risk_tier=critical`/cadência mascarados; teste NEGATIVO. _(doc 80 §5 + doc 81 §10.1 + ADR must-fix #2/BLOCKER #3)_
4. **Admissão de estação por pin O2 com escopo default-deny** (R16-02) — enrollment TOFU → PENDENTE →
   admin aprova = re-pin autoritativo-local; P3 só espelha. _(doc 81 §3 Alavancas 1-2 + doc 80 §3.5)_

## Capabilities afetadas

- `cockpit` (única) — +4 requisitos. Sem MODIFICADO/REMOVIDO/RENOMEADO (nenhum requisito existente é
  tocado: o RBAC linha 157, a auth-de-origem linha 129, o read-only de coleta linhas 29/53/106 e o
  gate Q1–Q3 linha 338 já cobrem seus eixos e **não são duplicados**).

## Impacto

- **Contrato:** 21 → 25 requisitos na capability `cockpit`. Habilita o gate de planejamento de F1 (a
  construção pode então rastrear a SHALL enumerados, Article IV).
- **Implementação:** ZERO nesta mudança (pure-design). A RLS e a admissão materializam-se em código só
  quando o motor multi-usuário (Supabase `xdikjgpkiqzgebcjgqmu`) for escolhido — gated.
- **Parqueado (NÃO entra no contrato):** R16-06 Audit-Log API (inviável: org free/Team → 404, só
  Enterprise); R16-03 (BLOCKER de transporte GitHub, decisão do dono); R16-04/R16-05 (F3/F4 gated por
  2º-dev-real + colisão medida); step-up-loopback (rebaixado a defesa-em-profundidade, já coberto).
