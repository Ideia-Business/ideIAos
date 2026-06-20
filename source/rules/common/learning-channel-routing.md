<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->
# Learning Channel Routing — memória nativa vs camada de instincts

O IdeiaOS tem DOIS canais de aprendizado persistente. Eles resolvem problemas
diferentes e **não devem espelhar o mesmo fato na mesma altitude**.

## Os dois canais

| Canal | Onde vive | Natureza | Influencia o agente AO VIVO? |
|-------|-----------|----------|------------------------------|
| **Memória nativa da IDE** | Claude Code: `~/.claude/projects/<proj>/memory/*.md` + `MEMORY.md` (sincronizada cross-IDE/máquina via `/memory-sync`, branch `planning`) | fato curado, 1 por arquivo, com **Why** + **How to apply** | **SIM** — auto-injetada todo SessionStart + recall por relevância |
| **Camada de instincts** | `~/.ideiaos/instincts/<scope>/*.md` | `trigger→action` atômico, confidence-tracked, quase todo auto-minerado por `/instinct-analyze` | **NÃO** — write-only; só vira conduta via `/instinct-status`/`/evolve` ou após promoção a `source/rules/` |

## A regra de roteamento

1. **Gotcha de domínio / incidente / processo de um produto** → **memória nativa**.
   É o único canal auto-injetado; um gotcha gravado só como instinct fica invisível na prática.
2. **Reflexo de engenharia stack-agnóstico** (trigger→action genérico) → **camada de instincts**:
   deixe o `/instinct-analyze` minerar; `/learn` manual só quando o auto-miner perderia o
   padrão **E** não for fato de domínio. Maduro (confidence ≥0.7 e prescritivo) → `/evolve`
   promove a `source/rules/`.
3. **Nunca o mesmo fato verbatim nos dois canais.** Uma descoberta com as duas facetas pode
   viver nos dois SOMENTE em altitudes diferentes (memória = incidente + contexto; instinct =
   reflexo abstrato).
4. `/evolve` deduplica/decai DENTRO da camada instinct (chave = slug do trigger). A dedup
   CROSS-canal (instinct ↔ memória) é decisão manual do agente, por esta regra.

## Por quê

Verificado empiricamente: **nenhum hook injeta `~/.ideiaos/instincts/` no contexto da IDE** —
só a memória nativa molda o comportamento ao vivo. Logo a camada de instincts funciona como
**telemetria comportamental** (sinal bruto), não como fonte de conduta imediata. O aprendizado
durável de alto sinal pertence à memória nativa (e ao vault Obsidian via `/evolve` → Learnings).
Escrever o mesmo fato nos dois é manutenção dobrada e drift entre as cópias.

## Anti-padrões

- Gravar gotcha de domínio **só** como instinct (fica invisível ao agente ao vivo).
- Espelhar verbatim memória ↔ instinct.
- Promover instinct de **telemetria de frequência** ("usa grep/python/bash N vezes") a
  `source/rules/` — viola `token-economy` (curadoria, não dump).

Cross-link: skills `/learn`, `/instinct-analyze`, `/instinct-status`, `/evolve`, `/memory-sync`;
rules `operating-discipline`, `token-economy`.
