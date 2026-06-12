# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# TypeScript Rules — IdeiaOS / ECC Stack: typescript

## Compiler Settings

- Always use `strict: true` in tsconfig — no exceptions
- Enable `noUncheckedIndexedAccess` for array/object safety
- Enable `exactOptionalPropertyTypes` to distinguish `undefined` from absent
- `skipLibCheck: false` only for upstream type bugs you cannot fix — document why

## Type System

- Prefer type inference over explicit annotation when type is obvious from assignment
- Never use `any` — use `unknown` and narrow with type guards
- Avoid `as` type assertions except at system boundaries (API responses, DOM)
  - If you must assert, wrap in a validated parser function
- Use `satisfies` operator to validate shape without widening: `const config = {...} satisfies Config`
- Discriminated unions over optional fields: `{ kind: 'error'; message: string } | { kind: 'ok'; data: T }`

## Functions and Generics

- Return types: explicit on public API functions; inferred on private/internal
- Generics: name with full words for complex types (`TEntity`, `TResult`) not single letters
- Avoid overloading — use union types in parameters instead
- Async functions always return `Promise<T>` (explicit), never `Promise<any>`

## Nullability

- Prefer `undefined` over `null` for optional values (consistent with TypeScript idioms)
- Always handle the null/undefined case explicitly — no `!` non-null assertions in business logic
- Use optional chaining `?.` and nullish coalescing `??` over explicit null checks where readable

## Imports and Modules

- Use path aliases (`@/` for `src/`) — no `../../..` relative imports beyond 2 levels
- Import types with `import type` to avoid runtime overhead
- Barrel files (`index.ts`) only for public API of a module — not for everything

## IdeiaOS Projects

- All 4 product projects (ideiapartner, nfideia, cfoai-grupori, lapidai) use TypeScript strict
- Supabase generated types: import from `@/integrations/supabase/types` — never edit manually
- React components: prefer `FC<Props>` with explicit Props interface in same file or co-located
