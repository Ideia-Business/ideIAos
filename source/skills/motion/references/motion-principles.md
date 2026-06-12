# Princípios de Animação (NÃO-NEGOCIÁVEL)

Validar TODA animação contra esta lista antes de entregar. Ancorado no `ui-ux-pro-max` prioridade 7.

## 1. Duração

| Tipo | Faixa |
|------|-------|
| Microinteração (hover, tap, toggle) | 100–200ms |
| Enter/exit (modal, toast, dropdown) | 150–300ms |
| Page / view transition | 300–500ms |
| Scroll scrub | amarrado ao scroll (sem duração fixa) |

Fora disso: < 100ms parece bug; > 600ms parece travado.

## 2. Easing

- **Entrada (aparecer):** `ease-out` (`power2.out`, `easeOut`) — rápido no início, desacelera
- **Saída (sumir):** `ease-in` — acelera saindo
- **Movimento natural / física:** `spring` (Motion: `type: "spring", stiffness: 300, damping: 30`)
- Evite `linear` para movimento de UI (parece mecânico); ok para loaders/progress

## 3. Performance — só compositar

✅ Animar: `transform` (translate/scale/rotate) e `opacity` → rodam na GPU, não disparam layout/paint.

❌ Nunca animar: `width`, `height`, `top`, `left`, `margin`, `padding` → layout thrash, jank. Use `transform: scale()` / `translate()` no lugar.

Para listas grandes/scroll: `will-change: transform` com parcimônia; remova após a animação.

## 4. Acessibilidade — prefers-reduced-motion

Sempre. O usuário que pede menos movimento recebe ou nenhum movimento ou só fade.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```
Em JS: `useReducedMotion()` (Motion) / `gsap.matchMedia()` (GSAP) — ver refs específicas.

## 5. Significado, não decoração

Animação boa comunica:
- **Continuidade espacial** — de onde veio, pra onde vai (shared layout / `layoutId`)
- **Causa e efeito** — clicou → algo respondeu
- **Hierarquia / atenção** — stagger guia o olho
- **Estado** — loading, sucesso, erro têm movimento distinto

Se a animação não comunica nada → corte. Movimento gratuito é ruído e custa bateria/CPU.

## Checklist final
- [ ] Duração na faixa correta
- [ ] Easing apropriado pra direção (in/out/spring)
- [ ] Só `transform`/`opacity`
- [ ] `prefers-reduced-motion` tratado
- [ ] Cleanup no unmount (GSAP/listeners)
- [ ] Conferido rodando via `frontend-visual-loop`
