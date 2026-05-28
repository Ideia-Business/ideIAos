# AGENTS.md — dev-setup

## Continue / resume (padrão híbrido)

Quando o pedido for genérico ("continuar", "retomar", etc.), leia nesta ordem:

1. `docs/CONTINUATION_HANDOFF.md` (estado operacional no `main`)
2. `STATE.md` (snapshot curto)
3. `planning:.planning/STATE.md` e `planning:.planning/ROADMAP.md` (quando existir no projeto-alvo)

## Fechamento de sessão (obrigatório)

Antes de encerrar qualquer sessão:

1. Atualize `STATE.md` com estado real.
2. Atualize `docs/CONTINUATION_HANDOFF.md` com:
   - o que foi feito,
   - pendências,
   - próximo passo executável.
3. Se houve decisão estratégica, sincronize `.planning/*` no branch `planning` (quando aplicável).

## Fonte de verdade

- Curto prazo operacional: `STATE.md` + `docs/CONTINUATION_HANDOFF.md`.
- Médio/longo prazo: `.planning/*` no branch `planning` (nos projetos que usam esse fluxo).

## Git

Sempre sincronize (`git pull`) antes de editar, especialmente em projetos com Lovable/agents em paralelo.
