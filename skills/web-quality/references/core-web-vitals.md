# Core Web Vitals — Diagnóstico e Fixes

## As métricas

| Métrica | O que é | Meta |
|---------|---------|------|
| **LCP** (Largest Contentful Paint) | tempo até o maior elemento visível pintar | ≤ 2.5s |
| **CLS** (Cumulative Layout Shift) | quanto o layout "pula" durante o load | ≤ 0.1 |
| **INP** (Interaction to Next Paint) | latência da resposta a interações | ≤ 200ms |
| FCP | primeiro conteúdo pintado | ≤ 1.8s |
| TBT | tempo de bloqueio da main thread | ≤ 200ms |

## Como medir (Chrome DevTools MCP)

```
mcp__chrome-devtools__performance_start_trace   # com reload
mcp__chrome-devtools__navigate_page → URL
mcp__chrome-devtools__performance_stop_trace
mcp__chrome-devtools__performance_analyze_insight  # aponta o culprit do LCP/CLS
mcp__chrome-devtools__lighthouse_audit             # score consolidado
```

## LCP alto — causas e fixes

| Causa | Fix |
|-------|-----|
| Imagem hero grande/sem otimizar | WebP/AVIF, `srcset`, dimensões explícitas, `fetchpriority="high"` |
| Fonte bloqueante | `font-display: swap`, preload da fonte crítica, subset |
| Render-blocking CSS/JS | code-split, defer, CSS crítico inline |
| Servidor lento (TTFB) | cache/CDN, SSR/edge, reduzir waterfall |
| Lazy-load no elemento LCP | NUNCA lazy-load o hero/above-the-fold |

## CLS alto — causas e fixes

| Causa | Fix |
|-------|-----|
| Imagem/vídeo sem width/height | sempre reservar espaço (aspect-ratio ou dims) |
| Fonte que troca (FOIT/FOUT) | `size-adjust`, preload, fallback métrico próximo |
| Conteúdo injetado acima (banner/ad) | reservar slot com altura fixa |
| Animação de layout property | animar `transform`, não `top/height` (ver skill `motion`) |

## INP alto — causas e fixes

| Causa | Fix |
|-------|-----|
| JS pesado na main thread | quebrar tarefas longas, `isInputPending`, web workers |
| Handlers caros no clique | debounce, mover trabalho pra depois do paint |
| Re-render React excessivo | memoização, virtualização de listas, `useDeferredValue` |
| Hidratação pesada (SSR) | islands/partial hydration, streaming |

## Peso / bundle

- Imagens: formato moderno, responsivas, lazy abaixo da dobra
- JS: tree-shaking, dynamic import por rota, analisar com bundle analyzer
- Fontes: subset, ≤ 2 famílias (alinha com ui-ux-pro-max)
