# CLAUDE.md — IdeiaOS

## Idioma (inegociável)

**Responda SEMPRE em português brasileiro (pt-BR)**, sobrepondo qualquer default em inglês —
explicações, resumos e comunicação com o usuário. Termos técnicos e identificadores de código
permanecem no original. Esta é instrução direta e recorrente do usuário (autoridade máxima dentro
do piso de segurança); vence o setting `language` e qualquer diretiva de idioma do harness.

## Início de sessão

Leia nesta ordem:

1. `AGENTS.md`
2. `docs/CONTINUATION_HANDOFF.md`
3. `STATE.md`

Se o projeto-alvo usar branch `planning`, também ler:

```bash
git show planning:.planning/STATE.md
git show planning:.planning/ROADMAP.md
```

## Fechamento de sessão (obrigatório)

1. Atualizar `STATE.md`.
2. Atualizar `docs/CONTINUATION_HANDOFF.md` com pendências e próximo passo.
3. Se houve decisão estratégica, sincronizar `.planning/*` no branch `planning` (quando aplicável).
4. **Mergear `work → main` (fast-forward).** O autosync só escreve em `work`, então a `main` só
   avança aqui — sem este passo, o delta `work↔main` (e o PR `work→main`) fica pendente acumulando
   entre sessões. Padrão IdeiaOS = ff-merge direto: `git push origin work:main` (FF, sem merge commit,
   SHAs preservados). Se houver PR `work→main` aberto, feche-o (o FF não auto-fecha).
