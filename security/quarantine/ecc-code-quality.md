# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# Code Quality Rules — IdeiaOS / ECC Common

## Naming

- Use descriptive, intention-revealing names: `getUserById` not `getU`
- Boolean variables and functions: `isActive`, `hasPermission`, `canEdit`
- Functions do ONE thing: if the name needs "and", split it
- No abbreviations except universally accepted (`url`, `id`, `ctx`, `err`)

## Clean Code

- Functions: max 20 lines; if longer, extract to named helpers
- Nesting: max 3 levels deep; use early returns to flatten
- No premature abstraction: duplicate once before abstracting
- Delete dead code — version control remembers; don't leave it commented out
- No magic numbers: extract to named constants with units (`TIMEOUT_MS = 5000`)

## Error Handling

- Never swallow errors: `catch(e) {}` is forbidden
- Propagate errors to the caller — don't log and continue silently
- Distinguish recoverable (return error object) from fatal (throw)
- Error messages must include context: what failed, expected, actual

## Dependencies

- Prefer standard library over external package for trivial tasks
- Every new dependency is a maintenance commitment — justify it
- Pin versions in lock files; never `*` or `latest` in production

## Comments

- Comment WHY, not WHAT (the code already says what)
- If you need a comment to explain what the code does, rewrite the code
- TODOs must have an owner and issue link: `// TODO(gustavo): #123 — refactor after auth migration`
- Delete commented-out code before committing

## Code Review Checklist

- [ ] Does the PR do exactly one thing?
- [ ] Are all new code paths tested?
- [ ] Is error handling explicit?
- [ ] Are there no magic numbers or unexplained constants?
- [ ] Can a new team member understand this in 2 minutes?
