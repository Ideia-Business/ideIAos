# Avaliação: mgrep + LSP plugins — Fase 04

**Data:** 2026-06-12
**Deliverable:** documentation-only — nenhum módulo instalado nesta fase.
**Reavaliar em:** Fase 08 (ideiaos-v3-review — token economy review).

---

## mgrep

### O que é

`mgrep` é uma ferramenta de busca de código alegadamente otimizada para contexto LLM. A principal alegação é redução de ~50% nos tokens consumidos em comparação com `grep` tradicional, ao truncar output verbose e formatar resultados para consumo direto por modelos de linguagem.

### Avaliação

**Caso de uso primário:** agents de busca como `code-explorer` (haiku), que fazem buscas repetitivas em codebase para responder "onde está X / como Y funciona / quem chama Z".

**Potencial real:** Se a alegação de -50% tokens for verificada, `code-explorer` (que usa exclusivamente Read, Grep, Glob) seria o principal beneficiário. Haiku já é o modelo mais barato — a economia marginal de tokens por busca pode não justificar a dependência adicional.

**Decisão:** Recomendar como otimização avaliada, mas NÃO tornar dependência obrigatória nesta fase.

- `code-explorer` usa `Grep` nativo por ora — funcional e sem dependência externa.
- mgrep entra como candidato de otimização na **Fase 08** (token economy review).
- Motivo do adiamento: nenhum benchmark medido no contexto IdeiaOS; alegação baseada em marketing da ferramenta.

**Como testar se quiser:**

```bash
# Instalar mgrep (verificar disponibilidade)
npm install -g mgrep   # ou via brew, conforme disponibilidade

# Comparar tokens consumidos em busca típica
# Antes: grep -r "useEffect" src/ | wc -c
# Depois: mgrep "useEffect" src/ | wc -c
# Medir diferença de tamanho do output
```

---

## LSP plugins (typescript-lsp, pyright-lsp)

### O que são

Plugins LSP (Language Server Protocol) para Claude Code que adicionam navegação semântica ao toolkit de agents:

- **typescript-lsp:** go-to-definition, find-references, hover types, rename symbol
- **pyright-lsp:** equivalente para Python — type inference, import resolution, find-refs

### Avaliação

**Benefício real:** Reduzem leitura de arquivo para navegação semântica. Em vez de ler 10 arquivos para rastrear onde uma função é chamada, um `find-references` semântico retorna só os call sites. Em projetos TypeScript grandes (>50k LOC), a economia de tokens por tarefa de refactor pode ser significativa.

**Candidatos ideais para uso:**

| Agente | Benefício de LSP |
|--------|-----------------|
| `code-explorer` | find-references semântico substitui grep + read múltiplos |
| `typescript-reviewer` | hover types sem ler arquivos de definição |
| `refactor-cleaner` | rename-symbol seguro em vez de sed/grep |
| `silent-failure-hunter` | rastrear retornos ignorados semanticamente |

**Decisão:** Recomendados para projetos TypeScript/Python grandes, mas NÃO instalados por default.

- Evitar inchar o setup global com dependências que só beneficiam projetos TS/Python grandes.
- Instalação sob demanda é o padrão IdeiaOS para ferramentas de stack específica.
- Listar como candidatos para `/ideiaos-catalog` futuro (installStrategy: `stack:typescript` / `stack:python`).

**Dependência de LSP por projeto:** Os LSP plugins requerem configuração por projeto (tsconfig.json path, virtual env Python). Não são "instala uma vez e esquece" — aumentam complexidade de onboarding.

---

## Candidatos para Fase 08

| Ferramenta | Candidatura | Condição para adoção |
|------------|-------------|---------------------|
| mgrep | Otimização de token economy para agents de busca | Benchmark medido: >30% redução confirmada no contexto IdeiaOS |
| typescript-lsp | Navegação semântica TS | Projetos com >50k LOC TS; installStrategy: stack:typescript |
| pyright-lsp | Navegação semântica Python | Projetos Python significativos; installStrategy: stack:python |

---

## Conclusão

Deliverable documentation-only — nenhum módulo instalado nesta fase.

A não-instalação é deliberada: mgrep carece de benchmark no contexto IdeiaOS; LSP plugins aumentam complexidade de setup sem benefício universal. Reavaliar na Fase 08 com dados reais de uso dos agents `code-explorer`, `typescript-reviewer` e `refactor-cleaner`.
