# Motion for React (ex-Framer Motion) — Padrões

Lib padrão para animação em React no IdeiaOS. Import: `import { motion, AnimatePresence } from "motion/react"` (pacote moderno) ou `"framer-motion"` em projetos legados.

## 1. Animação básica + variants

```tsx
import { motion } from "motion/react";

const fade = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.22, ease: "easeOut" } },
};

<motion.div variants={fade} initial="hidden" animate="visible">
  Conteúdo
</motion.div>
```

Variants > props inline quando há vários estados ou stagger.

## 2. Enter / Exit — AnimatePresence

Necessário para animar a **saída** de elementos condicionais (modal, toast, item removido).

```tsx
<AnimatePresence>
  {open && (
    <motion.div
      key="modal"
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.96 }}
      transition={{ duration: 0.18 }}
    />
  )}
</AnimatePresence>
```

Regras: cada filho precisa de `key` estável; o elemento condicional fica **dentro** do `AnimatePresence`, não fora.

## 3. Stagger (lista escalonada)

```tsx
const list = {
  visible: { transition: { staggerChildren: 0.05 } },
};
const item = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0 },
};

<motion.ul variants={list} initial="hidden" animate="visible">
  {items.map((i) => <motion.li key={i.id} variants={item}>{i.label}</motion.li>)}
</motion.ul>
```

## 4. Layout animations (reordenar/redimensionar sem jank)

```tsx
<motion.div layout transition={{ type: "spring", stiffness: 300, damping: 30 }} />
```
`layout` anima mudanças de posição/tamanho automaticamente (FLIP). Use `layoutId` para transições compartilhadas entre componentes (hero → detalhe).

## 5. Gestures

```tsx
<motion.button
  whileHover={{ scale: 1.03 }}
  whileTap={{ scale: 0.97 }}
  drag="x"
  dragConstraints={{ left: 0, right: 200 }}
/>
```

## 6. Scroll-linked

```tsx
import { motion, useScroll, useTransform } from "motion/react";

const { scrollYProgress } = useScroll();
const opacity = useTransform(scrollYProgress, [0, 1], [1, 0]);

<motion.div style={{ opacity }} />
// reveal ao entrar na viewport:
<motion.div whileInView={{ opacity: 1, y: 0 }} initial={{ opacity: 0, y: 20 }} viewport={{ once: true }} />
```

## 7. Bundle optimization — LazyMotion

Reduz de ~34KB para ~4.6KB. Use `m` no lugar de `motion` e carregue as features sob demanda.

```tsx
import { LazyMotion, domAnimation, m } from "motion/react";

<LazyMotion features={domAnimation}>
  <m.div animate={{ opacity: 1 }} />
</LazyMotion>
```
`domAnimation` (~15KB) cobre o comum; `domMax` adiciona drag/layout (~25KB). Use `useAnimate` (~2.3KB) para imperativo leve.

## 8. Reduced motion

```tsx
import { useReducedMotion } from "motion/react";
const reduce = useReducedMotion();
const variants = reduce
  ? { hidden: { opacity: 0 }, visible: { opacity: 1 } }   // sem movimento
  : { hidden: { opacity: 0, y: 12 }, visible: { opacity: 1, y: 0 } };
```

## Compatibilidade
Testado em React 19, Next.js 16, Vite 7, Tailwind v4. Em Next.js App Router, componentes com `motion` precisam de `"use client"`.
