---
name: motion
description: "Animation & motion implementation for web UIs — turns animation intent into real, production-grade code. Covers library selection (Framer Motion / Motion for React as default, GSAP + ScrollTrigger for complex timelines & scroll, react-spring for physics niches), gestures (drag/hover/tap), enter/exit (AnimatePresence), layout animations, scroll-linked effects, spring physics, SVG, and bundle optimization (LazyMotion). Enforces motion principles: 150–300ms durations, meaningful motion, prefers-reduced-motion. Use when asked to 'animar', 'adicionar transição/animação', 'efeito de scroll', 'fazer aparecer/sair suave', 'micro-interação', 'page transition', 'parallax', 'hover animado', 'stagger', 'deixar com vida/fluido'. Complements ui-ux-pro-max (priority 7 = animation guidelines) and ui-styling (the components being animated)."
---

# Motion — Animação para UIs Web

A skill que **escreve animação de verdade**. O `ui-ux-pro-max` diz *quando* e *quão rápido* animar (prioridade 7); esta skill entrega o *como* — código Framer Motion / GSAP correto, performático e acessível.

**Idioma:** Português brasileiro.

---

## Quando usar

### Must use
- "anima isso", "transição suave", "micro-interação", "page transition"
- Efeito de scroll (reveal, parallax, scrollytelling, progress)
- Enter/exit de elementos condicionais (modal, toast, lista que muda)
- Hover/tap/drag com feedback animado
- Lista com entrada escalonada (stagger)

### Skip
- Animação trivial resolvida com `transition` do Tailwind/CSS puro (hover de cor, opacity simples) — não precisa de lib
- Backend/lógica

---

## Passo 1 — Seleção de biblioteca (decisão antes de codar)

| Necessidade | Biblioteca | Por quê |
|-------------|-----------|---------|
| **Padrão React** — gestures, enter/exit, layout, springs | **Motion for React** (ex-Framer Motion) | API declarativa, `AnimatePresence`, `layout`, tree-shakeable |
| **Timelines complexas, scroll cinematográfico, sequências** | **GSAP + ScrollTrigger** | controle frame-a-frame, scrub, pin, timelines encadeadas |
| **Física pura / interpolação data-driven** | **react-spring** | nicho; só quando spring do Motion não basta |
| **Microinteração CSS-only** | **Tailwind `transition`** | zero JS, zero bundle |
| **Anim. de marca/ilustração exportada** | **Lottie** | After Effects → JSON |

> Default: **Motion for React**. Só vá pra GSAP quando o efeito for de *timeline/scroll* complexo. Não misture as duas no mesmo componente sem razão.

Detalhes por lib:
- `references/framer-motion.md` — Motion for React (gestures, variants, AnimatePresence, layout, LazyMotion)
- `references/gsap.md` — GSAP + ScrollTrigger (timeline, scrub, pin, cleanup)
- `references/motion-principles.md` — durações, easing, reduced-motion, performance

## Passo 2 — Aplicar princípios (NÃO-NEGOCIÁVEL)

Antes de entregar qualquer animação, valide contra `references/motion-principles.md`:

1. **Duração 150–300ms** para microinterações (enter/exit/hover). Page transitions ≤ 500ms.
2. **Animar só `transform` e `opacity`** (compositadas na GPU). Nunca animar `width`/`height`/`top`/`left` → layout thrash.
3. **`prefers-reduced-motion`** sempre respeitado — reduzir/desligar quando o usuário pede.
4. **Movimento com significado** — comunica continuidade espacial/causa-efeito, não decoração gratuita.
5. **Bundle** — em Motion for React, usar `LazyMotion` + `m` para cortar de ~34KB → ~4.6KB quando o tamanho importa.

## Passo 3 — Verificar visualmente

Animação só "fica boa" rodando. Após implementar, encadeie com a skill **`frontend-visual-loop`** para renderizar e conferir (inclusive em `prefers-reduced-motion`).

---

## Anti-padrões

- ❌ Animar `width`/`height`/`margin`/`top` (use `transform: scale/translate`)
- ❌ Duração de 0ms (mudança instantânea) ou > 600ms (parece travado)
- ❌ Esquecer `prefers-reduced-motion` → barreira de acessibilidade
- ❌ Esquecer cleanup do GSAP/ScrollTrigger no unmount (`ctx.revert()`) → memory leak
- ❌ Importar Framer Motion inteiro num bundle sensível (use `LazyMotion`)
- ❌ Animar decorativamente sem propósito → ruído visual

---

## Integração no IdeiaOS

| Skill | Papel |
|-------|-------|
| `ui-ux-pro-max` | prioridade 7 = **regras** de animação (quando/velocidade) |
| `ui-styling` | os componentes shadcn/tailwind que serão animados |
| `frontend-visual-loop` | renderiza e confere a animação rodando |
| `design-system` | tokens de duração/easing reutilizáveis |
