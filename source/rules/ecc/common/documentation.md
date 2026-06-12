# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# Documentation Rules — IdeiaOS / ECC Common

## Core Principle

Document WHY, not WHAT. The code already says what it does. Good documentation explains
decisions, constraints, and non-obvious intent that cannot be inferred from the code itself.

## When to Write Inline Comments

Write a comment ONLY when:
1. The WHY is not obvious from the code
2. A non-obvious algorithm or optimization is used
3. There is a deliberate workaround for an external constraint (API quirk, browser bug, etc.)
4. The code contradicts conventional patterns for a good reason

Do NOT write comments for:
- What a variable holds (name it well)
- What a function does (name it well + use types)
- Obvious control flow (`// increment counter` above `i++`)

## Function and Module Documentation

- Public APIs: one-line summary + params/return types (use JSDoc / docstrings)
- Internal helpers: only if the purpose is genuinely ambiguous
- Avoid restating the type signature in prose: `@param userId string — the user's ID` adds nothing

## Architecture Decision Records (ADRs)

- Significant architectural decisions belong in `docs/learnings/` or `.planning/research/`
- Format: context → decision → consequences (why this, what we gave up)
- Reference in code via comment: `// see docs/learnings/2026-05-28-idempotency.md`

## README and Project Docs

- README: installation, quickstart, key commands — optimize for first-10-minutes experience
- Keep docs in sync with code (pre-commit hook enforces in IdeiaOS)
- Delete outdated documentation — stale docs are worse than no docs

## IdeiaOS-Specific

- `AGENTS.md`: agent identity + constraints (human-readable, AI-executable)
- `STATE.md`: current snapshot — always current, never historical
- `docs/CONTINUATION_HANDOFF.md`: pending work + next step (updated at session close)
- Learnings (`docs/learnings/*.md`): must pass gate triplo before creating
