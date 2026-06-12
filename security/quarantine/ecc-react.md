# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# React Rules — IdeiaOS / ECC Stack: react

## Component Patterns

- Prefer function components — never class components in new code
- One component per file; file name matches component name (PascalCase)
- Props interface defined in same file, named `<ComponentName>Props`
- Keep components small: if render exceeds 100 lines, extract sub-components
- No default exports for components — named exports only (better refactoring tooling)

## Hooks Rules

- Call hooks only at the top level — never inside conditions, loops, or nested functions
- `useEffect`: always specify dependency array; never omit it
  - Empty `[]`: runs once on mount — must be intentional and documented
  - No `[]`: almost always wrong — document why if used
- Custom hooks: prefix with `use`; extract logic from components when reused 2+ times
- `useMemo` / `useCallback`: only when profiler shows measurable perf issue — not preemptive
- `useRef` for DOM access and mutable values that should not trigger re-render

## State Management

- Colocate state as close to where it's used as possible
- Lift state only when 2+ sibling components need it
- Global state (Zustand/Context): only for truly global data (auth user, theme, locale)
- Avoid storing derived state — compute it in render or `useMemo`
- Server state (API data): use React Query / TanStack Query — not `useEffect` + `useState`

## Performance

- Keys in lists: use stable IDs, never array index (except static, never-reordered lists)
- Avoid anonymous functions in JSX when passed as props to memoized components
- `React.memo`: wrap leaf components with expensive render, not all components
- Code-split routes with `React.lazy` + `Suspense`

## Patterns to Avoid

- Prop drilling beyond 2 levels — use composition or context
- `useEffect` for data fetching — use React Query
- Mutating state directly — always return new objects/arrays
- Boolean prop names that are not self-documenting: prefer `isLoading` over `loading`

## IdeiaOS Projects

- ideiapartner, nfideia, lapidai: React + shadcn/ui + Tailwind (Lovable stack)
- cfoai-grupori: React (confirm stack before adding new patterns)
- Design system: use `/design-system` skill for token decisions before writing CSS
- Lovable projects: respect Lovable's component structure — see `source/rules/lovable/deployment-protocol.md`
