# GSAP + ScrollTrigger — Padrões

Use GSAP quando o efeito for **timeline complexa** ou **scroll cinematográfico** (scrub, pin, sequências encadeadas) — casos onde a API declarativa do Motion for React fica forçada.

Import: `import gsap from "gsap"; import { ScrollTrigger } from "gsap/ScrollTrigger"; gsap.registerPlugin(ScrollTrigger);`

## 1. Timeline básica

```ts
const tl = gsap.timeline({ defaults: { duration: 0.3, ease: "power2.out" } });
tl.from(".title", { y: 30, opacity: 0 })
  .from(".subtitle", { y: 20, opacity: 0 }, "-=0.15")  // overlap
  .from(".cta", { scale: 0.9, opacity: 0 });
```

## 2. ScrollTrigger — reveal ao rolar

```ts
gsap.from(".card", {
  scrollTrigger: { trigger: ".card", start: "top 80%", toggleActions: "play none none reverse" },
  y: 40, opacity: 0, duration: 0.4, stagger: 0.1,
});
```

## 3. Scrub (animação amarrada ao scroll) + pin

```ts
gsap.to(".panel", {
  scrollTrigger: {
    trigger: ".section",
    start: "top top",
    end: "+=1500",
    scrub: true,     // progride com o scroll
    pin: true,       // fixa a seção enquanto anima
  },
  xPercent: -100,
});
```

## 4. Cleanup obrigatório em React (evita memory leak)

Use `gsap.context()` e `revert()` no unmount. Em React 18+ StrictMode o efeito roda 2x — o `ctx.revert()` neutraliza.

```tsx
import { useRef, useLayoutEffect } from "react";

const root = useRef<HTMLDivElement>(null);
useLayoutEffect(() => {
  const ctx = gsap.context(() => {
    gsap.from(".item", { y: 20, opacity: 0, stagger: 0.1 });
  }, root);
  return () => ctx.revert();   // limpa animações + ScrollTriggers
}, []);

return <div ref={root}> ... </div>;
```

## 5. Reduced motion

```ts
gsap.matchMedia().add("(prefers-reduced-motion: no-preference)", () => {
  // só registra as animações de movimento aqui
});
```
Quem prefere reduzir movimento simplesmente não recebe as animações registradas dentro do bloco.

## Anti-padrões GSAP
- ❌ Esquecer `ctx.revert()` → ScrollTriggers acumulam, leak
- ❌ Registrar plugin fora do módulo / múltiplas vezes
- ❌ Animar layout properties pesadas com scrub (use transform)
- ❌ Misturar GSAP e Motion for React no mesmo elemento
