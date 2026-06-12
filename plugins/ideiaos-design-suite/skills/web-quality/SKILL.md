---
name: web-quality
description: "Automated web-quality audit — Core Web Vitals (LCP/CLS/INP), WCAG 2.1 accessibility, and SEO/best-practices, run programmatically via the already-installed Chrome DevTools MCP (lighthouse_audit + performance traces). Produces a scored, prioritized report with concrete fixes. Use when asked to 'auditar performance/acessibilidade/SEO', 'rodar lighthouse', 'medir Core Web Vitals', 'tá lento/pesado', 'site acessível?', 'melhorar SEO', 'WCAG', 'antes de publicar quero medir', or as the programmatic depth behind gsd-ui-review. Complements frontend-visual-loop (subjective visual check) and ui-ux-pro-max (the rules)."
---

# Web Quality — Auditoria Programática

Mede o que o olho não mede: **Core Web Vitals**, **acessibilidade WCAG 2.1** e **SEO/best-practices** — com números, não impressões. Roda sobre o **Chrome DevTools MCP** já instalado (`mcp__chrome-devtools__lighthouse_audit` + `performance_*`). Zero install novo.

**Idioma:** Português brasileiro.

---

## Quando usar

### Must use
- "audita performance / acessibilidade / SEO"
- "tá lento", "página pesada", "demora pra carregar"
- "esse site é acessível?", "WCAG", "contraste / leitor de tela"
- Antes de publicar (Lovable Publish / deploy de produção) — baseline de qualidade
- Como **profundidade programática** chamada pelo `gsd-ui-review` (audit retroativo)

### Skip
- Mudança não-visual / backend puro
- Quando não há URL renderizável

---

## Os 3 eixos

| Eixo | O que mede | Referência |
|------|-----------|-----------|
| **Performance (CWV)** | LCP, CLS, INP, TBT, FCP, peso de bundle/imagens | `references/core-web-vitals.md` |
| **Acessibilidade (WCAG 2.1 AA)** | contraste, alt, labels, foco, teclado, headings, ARIA | `references/wcag-checklist.md` |
| **SEO + Best Practices** | meta tags, semântica, structured data, https, links | `references/seo.md` |

## Fluxo de execução

```
1. Confirmar URL alvo (dev server ou preview/produção)
2. mcp__chrome-devtools__lighthouse_audit  → scores Perf / A11y / SEO / BP
3. Para performance fina:
   mcp__chrome-devtools__performance_start_trace → reload → stop_trace
   mcp__chrome-devtools__performance_analyze_insight  → LCP/CLS culprits
4. Para a11y: cruzar achados do lighthouse com references/wcag-checklist.md
   (lighthouse pega ~30% do WCAG automaticamente; o resto é checagem manual guiada)
5. Classificar achados por severidade × esforço
6. Produzir relatório + (se pedido) aplicar fixes de maior ROI
```

> **Honestidade obrigatória:** Lighthouse automatiza só parte do WCAG. NÃO declare "acessível/WCAG AA" só porque o score de a11y deu 100. Diga "Lighthouse a11y: 100; checks manuais pendentes: <lista>".

## Mapa de metas (thresholds)

| Métrica | Bom | Precisa melhorar | Ruim |
|---------|-----|------------------|------|
| LCP | ≤ 2.5s | 2.5–4.0s | > 4.0s |
| CLS | ≤ 0.1 | 0.1–0.25 | > 0.25 |
| INP | ≤ 200ms | 200–500ms | > 500ms |
| Lighthouse Perf | ≥ 90 | 50–89 | < 50 |
| Lighthouse A11y | 100* | < 100 | — |

\* 100 no Lighthouse ≠ WCAG AA completo. Ver ressalva acima.

## Saída ao usuário

```
📊 Web Quality — <URL>

Performance: <score>  | LCP <x>s · CLS <y> · INP <z>ms
Acessibilidade: <score> (Lighthouse) + <n> checks manuais pendentes
SEO: <score> | Best Practices: <score>

🔴 BLOCK (corrigir já):
- <achado> → <fix concreto> (esforço: baixo/médio/alto)

🟡 Melhorias (ROI):
- <achado> → <fix>

✅ OK: <o que passou>
```

---

## Anti-padrões

- ❌ Declarar "acessível" com base só no score automatizado
- ❌ Auditar em dev sem avisar que números de prod diferem (HMR, sourcemaps inflam)
- ❌ Otimizar métrica sem impacto no usuário (vaidade de score)
- ❌ Instalar Playwright/Lighthouse-CLI separado — o Chrome DevTools MCP já entrega

---

## Integração no IdeiaOS

| Skill | Papel |
|-------|-------|
| `gsd-ui-review` | audit visual 6-pilares **retroativo**; chama esta skill para os números de CWV/WCAG |
| `frontend-visual-loop` | check visual subjetivo *durante* o trabalho; esta skill mede objetivo |
| `ui-ux-pro-max` | prioridades 1 (a11y) e 3 (performance) = as **regras** que aqui viram medida |
| `lovable-handoff` | rode antes do Publish para baseline de qualidade |
