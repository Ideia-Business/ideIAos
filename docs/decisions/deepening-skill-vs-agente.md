# SOURCE: IdeiaOS v9

# Ritual de deepening: skill nova `/improve-architecture` vs enriquecer agente de limpeza

**Data:** 2026-06-17
**Status:** Aceito
**Escopo:** Fase E do milestone v9 (R9-05 / GAP 3) — absorção de `improve-codebase-architecture` de `mattpocock/skills` (MIT)

---

## Contexto

O IdeiaOS já tem **limpeza pontual** de código via dois agentes single-shot: `refactor-cleaner`
(remove código morto, imports não usados, duplicação, TODOs resolvidos no fim de uma feature) e
`code-simplifier` (simplifica um trecho complexo preservando comportamento). O que **falta** é um
**ritual recorrente de saúde de design** que avalie a *arquitetura* — módulos rasos vs profundos no
sentido de profundidade-como-leverage — contra o vocabulário do domínio (`CONTEXT.md`) e as decisões
já registradas (`docs/decisions/`). O relatório de análise (§3 verdito ADAPTAR; §8 SHOULD #4)
recomenda absorver `improve-codebase-architecture` como capacidade nova.

A pergunta de design: criar uma **skill nova** ou **enriquecer** um dos agentes de limpeza existentes?

## Decisão

Criar uma **skill nova**: `/improve-architecture` (alias `/aprofundar`). Não enriquecer
`refactor-cleaner` nem `code-simplifier`.

## Por quê

- **Fluxo próprio recorrente, não single-shot.** O deepening é um ritual de 3 fases (explorar →
  relatório HTML → grilling loop) recomendado **a cada poucos dias**. Os dois agentes são single-shot
  de limpeza pontual: `refactor-cleaner` *remove o que sobrou*; `code-simplifier` *simplifica um trecho*.
  Nenhum tem fase de exploração com relatório visual nem loop conversacional.
- **Precisa de aparato de skill orquestradora.** Carrega um **glossário de arquitetura próprio**
  (`LANGUAGE.md`: Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality), um **scaffold
  de relatório HTML** (`HTML-REPORT.md`) e **integração com `CONTEXT.md`/ADR** no grilling loop —
  comportamento de skill, não de agente de edição single-shot.
- **Reuso de disciplina existente.** O grilling loop reusa a disciplina do `/grelha` (R9-02:
  atualizar `CONTEXT.md` inline ao nomear módulo; R9-03: oferecer ADR sob o gate dos 3 critérios de
  `ADR-FORMAT.md`). Espremer isso dentro de um agente de limpeza perderia a recorrência e o relatório.

## Opções consideradas

- **Enriquecer `refactor-cleaner` / `code-simplifier` (rejeitada).** Ficaria espremida: um agente de
  limpeza pontual teria que ganhar fase de exploração, geração de HTML, glossário próprio e loop
  conversacional — descaracterizando o agente e perdendo a recorrência e a fronteira limpa entre
  "remover morto / simplificar trecho" (pontual) e "avaliar arquitetura" (ritual).
- **Skill nova (aceita).** Fluxo próprio, recorrência explícita, fronteira clara vs os agentes.

## Gate dos 3 critérios (ADR-FORMAT.md)

1. **Difícil de reverter?** Médio — criar/migrar uma skill com resources e fronteiras estabelecidas é
   trabalho real de desfazer.
2. **Surpreendente sem contexto?** Sim — um leitor futuro veria uma skill cobrindo terreno adjacente
   a dois agentes de limpeza e perguntaria por que não foi um agente.
3. **Trade-off real?** Sim — havia a alternativa genuína de enriquecer os agentes; foi rejeitada por
   razões específicas (recorrência, relatório, glossário, fronteira).

Os três passam → ADR registrado.

## Consequências

- A skill mora em `source/skills/improve-architecture/` com `SKILL.md` + `LANGUAGE.md` + `HTML-REPORT.md`.
- `refactor-cleaner` e `code-simplifier` permanecem **inalterados** — fronteira documentada na própria skill.
- O grilling loop **não cria pipeline novo**: reusa `CONTEXT.md` (`/grelha`) e `docs/decisions/`
  (ADR-FORMAT). O espelhamento ADR→Obsidian segue a cargo do `/extract-learnings` (Passo 4c).
