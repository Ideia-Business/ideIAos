---
name: tool-output-compressor
description: Comprime saídas de ferramenta volumosas (logs, JSON tabular, resultados de busca) ANTES de entrarem no contexto do agente — local, determinístico, reversível (CCR) e CLI-First, sem rede e sem dependência externa. NUNCA toca mensagem do usuário. Ative quando uma saída de ferramenta for grande e repetitiva (log de build/CI, dump JSON, search results) e você quiser reduzir tokens sem perder a informação (recuperável sob demanda). Contrato vivo em specs/tool-output-compressor/. Padrão minerado de chopratejas/headroom (Apache-2.0); a dependência NÃO foi adotada.
---

# SOURCE: IdeiaOS v2 | padrão minerado de chopratejas/headroom (Apache-2.0); dependência NÃO adotada

# Skill: tool-output-compressor

**Idioma:** Português brasileiro.

## O que é

Um compressor **local, determinístico e reversível** de **saídas de ferramenta** —
o oposto arquitetural de um proxy: nada de rede, nada de `ANTHROPIC_BASE_URL`, nada de
telemetria, nada de dependência externa (Python stdlib + bash). Reduz tokens roteando por
tipo de conteúdo e mantém o original recuperável sob demanda (padrão CCR).

Derivado da avaliação do `headroom` (memória `headroom-eval-2026-06`): a **ideia** de
comprimir tool-output é de altíssimo ROI (log → template ~99%; JSON tabular → schema+CSV
~40–60%), mas a **dependência** não cabe no IdeiaOS (proxy colide com `mcp-hygiene`, ~$0 em
subscription, inaplicável a Lovable/Deno). Esta skill nativiza só o padrão.

## Princípios inegociáveis (do contrato `specs/tool-output-compressor/`)

1. **Nunca comprime mensagem do usuário** — `--role user` é sempre passthrough byte-idêntico.
2. **Reversível por CCR** — original cacheado em store local keyed por sha256; recuperável por hash; miss é erro explícito (exit 3), nunca silêncio.
3. **Verificação por exit-code** — 0=ok, não-zero=falha; nunca emite artefato parcial (`antifragile-gates`).
4. **Economia medida honestamente** — tokens antes/depois via tokenizer real (tiktoken se houver) ou heurística marcada como estimativa (`measured:false`).
5. **Local, CLI-First, fail-open** — sem rede; se `python3` faltar, o wrapper repassa o original e o agente segue.
6. **Determinístico e idempotente** — mesma entrada → mesma saída; recomprimir um output já comprimido é no-op.

## Uso

```bash
LIB=source/skills/tool-output-compressor/lib

# comprimir uma saída de ferramenta (stdin -> stdout comprimido)
some_command_with_huge_output | bash $LIB/toc.sh compress --role tool

# ver métricas (JSON com tokens_before/after, reduction_pct, transform, sha256)
cat build.log | bash $LIB/toc.sh compress --role tool --json

# recuperar o original a partir do hash da sentinela
bash $LIB/toc.sh retrieve --hash <sha256>

# gate de verificação (exit 0 = contrato satisfeito)
bash $LIB/toc.sh self-test
```

Variável de ambiente: `TOC_STORE` (default `~/.ideiaos/toc-store`) — onde os originais
reversíveis ficam. TTL/limpeza são responsabilidade do operador (sem rede, sem auto-egress).

## Tipos de conteúdo suportados

| Tipo | Tratamento | Reversível |
|------|-----------|-----------|
| log | template-ização (`Nx <template>` + exemplo) | sim (store) |
| json_tabular (array de dicts uniformes) | `[N]{schema}` + linhas CSV | sim (store) |
| text / search / diff / desconhecido | passthrough (0%) — futuro: compressores dedicados | n/a |
| mensagem de usuário | passthrough protegido (nunca comprime) | n/a |

## Fronteira (o que NÃO é)

- **Não é proxy** nem MCP — não intercepta tráfego do modelo, não seta base_url.
- **Não substitui** `/context-engineering` (disciplina) nem `/cost-tracking` (roteamento/medição) — é o **compressor determinístico de artefato** que faltava; complementa ambos.
- **Não comprime a conversa** — só saída de ferramenta. Preservar a intenção do usuário é lei.

## Referências

- Contrato vivo: `specs/tool-output-compressor/spec.md`
- Libs: `lib/toc_compress.py` (núcleo stdlib), `lib/toc.sh` (wrapper fail-open)
- Rules: `antifragile-gates` (exit-code), `token-economy` (medição/sem-dep), `context-packet-handoffs` (padrão budget/hash, primo do CCR)
