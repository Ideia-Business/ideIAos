# OKLCH Tokens — Paleta derivada de `--brand-hue`

Abordagem moderna para tokens de cor. Em vez de definir ~50 hex à mão, define-se **um único hue de marca** e a paleta inteira (primária, secundária, fundos, mutados, estados) é derivada por matemática OKLCH. Trocar a marca = trocar uma linha.

## Por que OKLCH > HSL/hex

| Critério | hex/HSL | OKLCH |
|----------|---------|-------|
| Uniformidade perceptual | ❌ (HSL: amarelo "claro" ≠ azul "claro" no mesmo L) | ✅ L = luminância perceptual real |
| Contraste previsível | difícil | mesmo L ≈ mesmo contraste percebido |
| Gamut amplo (P3) | ❌ sRGB | ✅ suporta displays modernos |
| Derivar paleta por math | frágil | natural (gira H, ajusta L/C) |
| Suporte browser | total | total (Chrome/Safari/FF atuais) |

Sintaxe: `oklch(L C H)` → **L** 0–1 (luminância), **C** 0–0.4 (croma/saturação), **H** 0–360 (matiz).

## Modelo de um hue só

```css
:root {
  /* única variável de marca a editar */
  --brand-hue: 265;          /* roxo. fintech≈230 azul, saúde≈160 verde, energia≈25 laranja */
  --brand-chroma: 0.15;      /* intensidade da cor */

  /* primária derivada — escala por luminância */
  --primary-50:  oklch(0.97 0.02 var(--brand-hue));
  --primary-100: oklch(0.93 0.05 var(--brand-hue));
  --primary-300: oklch(0.80 0.10 var(--brand-hue));
  --primary-500: oklch(0.62 var(--brand-chroma) var(--brand-hue));
  --primary-600: oklch(0.55 var(--brand-chroma) var(--brand-hue));
  --primary-700: oklch(0.48 0.14 var(--brand-hue));
  --primary-900: oklch(0.30 0.10 var(--brand-hue));

  /* secundária = hue + 180 (complementar) ou +120 (triádica) */
  --secondary-500: oklch(0.62 0.12 calc(var(--brand-hue) + 180));

  /* neutros levemente tingidos pela marca (croma baixíssimo) */
  --bg:        oklch(0.99 0.004 var(--brand-hue));
  --surface:   oklch(0.97 0.006 var(--brand-hue));
  --muted:     oklch(0.55 0.01  var(--brand-hue));
  --border:    oklch(0.90 0.008 var(--brand-hue));
  --fg:        oklch(0.20 0.02  var(--brand-hue));

  /* estados (hues fixos semânticos, mesma luminância p/ consistência) */
  --success: oklch(0.62 0.15 150);
  --warning: oklch(0.75 0.15 80);
  --danger:  oklch(0.58 0.18 25);
  --info:    oklch(0.62 0.12 230);
}
```

## Dark mode = inverter a escala de L

```css
.dark {
  --bg:      oklch(0.18 0.01 var(--brand-hue));
  --surface: oklch(0.22 0.012 var(--brand-hue));
  --fg:      oklch(0.95 0.01 var(--brand-hue));
  --border:  oklch(0.30 0.012 var(--brand-hue));
  /* primária: subir L e geralmente baixar C um pouco pra não vibrar no escuro */
  --primary-500: oklch(0.70 0.13 var(--brand-hue));
}
```

## Integração com Tailwind v4 (`@theme`)

```css
@theme {
  --color-primary: oklch(0.62 0.15 265);
  --color-primary-fg: oklch(0.99 0.01 265);
  --color-bg: oklch(0.99 0.004 265);
}
```
Tailwind v4 já gera utilitários (`bg-primary`, `text-fg`) a partir do `@theme`. Em v3, mapear no `theme.extend.colors` apontando para as CSS vars.

## Regras de contraste (alinha com web-quality / WCAG)

- Diferença de **L ≥ 0.4** entre texto e fundo ≈ passa AA para texto normal (validar sempre com medida real)
- Não confiar só no número — rodar `web-quality` (contraste 4.5:1) na UI final
- Estados (success/danger/etc.) mantêm L parecido entre si → consistência visual

## Three-layer (mantém a arquitetura existente)

```
Primitive:  --primary-500: oklch(...)        ← derivado de --brand-hue
Semantic:   --color-action: var(--primary-600)
Component:  --button-bg: var(--color-action)
```
OKLCH entra na camada **primitive**; semantic e component seguem iguais.

## Migração de paleta hex existente
1. Converter a cor de marca atual para OKLCH (devtools / oklch.com) → vira `--brand-hue` + chroma
2. Gerar a escala por L conforme acima
3. Substituir primitives hex pelas oklch
4. Manter semantic/component intactos (só apontam pra primitive)
5. Rodar `web-quality` para validar contraste pós-migração
