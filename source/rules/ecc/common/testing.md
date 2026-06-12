# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# Testing Rules — IdeiaOS / ECC Common

## Philosophy

- Write tests before or alongside implementation — not after as an afterthought
- Tests are first-class code: same naming, style, and review standards apply
- A passing test suite you don't trust is worse than no tests — keep it green

## Test Pyramid

- **Integration tests first**: test real behavior through the public API
- **Unit tests for algorithms**: pure functions with complex logic
- **E2E tests sparingly**: cover critical user paths only (login, checkout, core flow)
- Avoid testing implementation details — test observable behavior

## What to Test

- Happy path + at least 2 edge cases per function
- Error paths explicitly: what happens when the input is invalid?
- Boundary conditions: empty array, null, zero, max int, empty string
- Side effects: verify the database row was written, not just the return value

## What NOT to Test

- Framework internals (React render lifecycle, ORM internals)
- Private methods — test through the public interface
- Trivial getters/setters with no logic

## Test Quality

- One assertion per test concept (can have multiple `.expect` calls if they test the same thing)
- Test names describe behavior: `"returns empty array when user has no orders"` not `"test getUserOrders"`
- No `sleep()` in tests — use mocks, stubs, or proper async awaiting
- Deterministic: tests must pass 100% of the time, not 95%

## Coverage

- Aim for 80%+ line coverage on business logic
- 100% coverage on security-critical paths (auth, permissions, payments)
- Coverage % is a lagging indicator — low coverage is bad, high coverage is not sufficient

## Test Infrastructure

- Tests must run in under 2 minutes total (parallelize if needed)
- Isolate external dependencies: mock HTTP calls, use in-memory DB for unit tests
- Clean up test data after each test — don't rely on test order

## IdeiaOS Projects

- Supabase: use `supabase test db` for RLS policy tests
- React components: test user interactions, not component internals (React Testing Library)
- API routes: integration test with real DB (use test schema/tenant)
