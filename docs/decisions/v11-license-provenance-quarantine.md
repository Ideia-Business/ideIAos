# ADR v11 — Proveniência de licença e quarentena de GPL na absorção

**Status:** Aceito (2026-06-19)
**Contexto:** milestone v11 (análise multi-fonte `docs/research/2026-06-19-arsenal-analysis/`).
**Relacionado:** [[v9-mattpocock-skills-absorcao]] · rule `delta-spec.md` · guard `check-source-headers.sh` (W2).

## Contexto

O IdeiaOS cresce **absorvendo** padrões de repositórios de terceiros. Cada absorção
carrega a licença da fonte. Misturar código de licenças incompatíveis (sobretudo
**copyleft GPL**) num projeto contamina o licenciamento do todo. A análise v11
mapeou o cenário de licenças das fontes confrontadas e exige uma política explícita.

## Cenário de licenças das fontes (v11)

| Fonte | Licença | Postura de absorção |
|-------|---------|---------------------|
| OpenSpec (Fission-AI) | MIT | código OK (já vendorizado em `/spec`, header `# SOURCE`) |
| github/spec-kit | MIT | conceito/prompts OK com header `# SOURCE` (W4 minerou padrões, não premissa greenfield) |
| DietrichGebert/ponytail | MIT | conceito OK com header |
| mattpocock/skills | MIT | já absorvido (v9) — técnica, não ideologia |
| voltagent/awesome-agent-skills (lista) | itens variados | garimpo item-a-item, **checar licença de CADA item** |
| **reflexion (context-engineering-kit)** | **GPL-3.0** | ⚠️ **SÓ O CONCEITO — copiar ZERO código** |
| color-expert | CC-BY-4.0 | não absorvido |

## Decisão

1. **Quarentena de GPL — conceito-only, código-zero.** Padrões de fontes GPL (hoje:
   `reflexion`, triagem quick-vs-deep) podem ser absorvidos **apenas como ideia/algoritmo
   reescrito do zero**. É PROIBIDO copiar, colar ou adaptar trecho de código GPL para o
   IdeiaOS. A reescrita independente do conceito não é obra derivada; a cópia de código é.
   No v11 nenhuma linha de código de `reflexion` foi copiada (o conceito sequer foi
   implementado como skill — ficou como referência LOW).

2. **`# SOURCE:` obrigatório (W2).** Todo artefato absorvido declara sua origem + licença
   numa linha `# SOURCE: <upstream> <licença> | adapted: IdeiaOS vN`. O guard
   `scripts/check-source-headers.sh` (ADVISORY) vigia isso para skills; rules/libs seguem
   a mesma convenção no cabeçalho. Proveniência rastreável = pré-condição da absorção.

3. **Pipeline de quarentena.** Material de terceiros passa por `security/scan-absorbed.sh`
   (em `security/quarantine/`) ANTES de entrar em `source/`. A checagem de licença é parte
   da triagem manual: item sem licença clara ou com copyleft incompatível **não** é absorvido
   como código.

## Consequências

- **Positivo:** o IdeiaOS permanece com licenciamento limpo e auditável; cada absorção
  tem origem e licença rastreáveis; o risco de contaminação copyleft é contido por política
  explícita + guard.
- **Custo:** absorver um padrão GPL exige reescrita independente (mais trabalho que copiar) —
  é o preço de manter o licenciamento íntegro. Aceito.
- **Gatilho de revisão:** se algum dia um padrão GPL for valioso o bastante para implementar,
  reabrir este ADR para decidir entre reescrita-limpa vs. isolamento em módulo separado de
  licença compatível. Hoje (v11) nada de GPL foi implementado.
