---
name: deep-research
description: "Pesquisa profunda multi-fonte com retrieval iterativo: orquestrador avalia retorno, faz follow-up, máx 3 ciclos. Use proativamente para decisões técnicas com trade-offs ou domínio desconhecido."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: deep-research

**Idioma:** Português brasileiro.

---

## Quando usar

- Escolher entre opções técnicas com trade-offs não óbvios (ex.: qual lib de auth, qual estratégia de cache).
- Entrar em domínio desconhecido (nova tecnologia, API de terceiro, regulação).
- Decisão arquitetural com implicações de longo prazo.
- Resposta que requer síntese de múltiplas fontes (documentação + issues + benchmarks).

## Quando NÃO usar

- Resposta já conhecida e segura — não gaste ciclos de retrieval.
- Perguntas factuais simples com resposta única e estável.
- Quando o prazo não permite iteração (use best-effort com 1 ciclo e documente incerteza).

---

## Processo: Iterative Retrieval (máx 3 ciclos)

### Ciclo estrutural

```
Definir objetivo + query inicial
  → Buscar (Context7 / web / docs)
  → Avaliar: a lacuna de conhecimento foi fechada?
    → SIM: sintetizar
    → NÃO (e ciclos < 3): refinar query → repetir
  → Após 3 ciclos: sintetizar com o que se tem, documentar incertezas
```

### Passo 1 — Definir objetivo e query

- Escrever em 1 frase o que precisa ser decidido.
- Listar 2–3 hipóteses ou opções a comparar.
- Formular query inicial específica (não genérica).

### Passo 2 — Buscar

- Priorizar: documentação oficial → issues/changelogs → benchmarks → posts técnicos.
- Usar Context7 MCP para libs com docs versionadas.
- Anotar fonte e data de cada achado relevante.

### Passo 3 — Avaliar lacuna

- O que a busca respondeu?
- O que ainda está em aberto?
- Se lacuna existe e ciclos restam: refinar query e repetir.

### Passo 4 — Sintetizar

- Produzir documento com: objetivo, opções comparadas, fontes, recomendação fundamentada.
- Registrar incertezas residuais explicitamente.

---

## Output

Documento de research (ex.: `docs/research/<topico>.md`) com:
- **Objetivo** — decisão a ser tomada.
- **Opções** — tabela comparativa (critérios × opções).
- **Fontes** — URLs + datas.
- **Recomendação** — escolha + justificativa.
- **Incertezas** — o que não foi possível confirmar.

---

## Anti-patterns

- 1 busca rasa tratada como research completo.
- Ciclos infinitos sem convergir — capturar após 3 e documentar incerteza.
- Misturar research e implementação no mesmo passo (pesquisar até decidir, só então implementar).
- Não registrar fontes (impossibilita auditoria da decisão).

---

## Relações

- Deve preceder `api-design` e decisões arquiteturais relevantes.
- Resultado alimenta `codebase-onboarding` quando o domínio pesquisado é um novo projeto.
- Regra de orchestration.md: iterative retrieval com orquestrador avaliando retorno.
