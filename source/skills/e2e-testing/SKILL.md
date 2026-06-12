---
name: e2e-testing
description: "Testes end-to-end de fluxos críticos (Playwright/Cypress). Use proativamente para fluxos de usuário que NÃO podem quebrar (login, checkout, deploy)."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: e2e-testing

**Idioma:** Português brasileiro.

---

## Quando usar

- Fluxo crítico multi-tela que envolve múltiplos sistemas (auth + DB + UI).
- Regressão de produção: um fluxo quebrou em prod e precisa de cobertura permanente.
- Smoke test de deploy: validar que o happy path funciona após subir nova versão.

## Quando NÃO usar

- Lógica isolada (funções, transformações, regras de domínio) — use `tdd`/unit tests (mais rápidos e estáveis).
- Validação de estilo visual — use snapshot ou revisão manual.
- Tudo — e2e é lento e frágil; reserve para o que realmente não pode quebrar.

---

## Processo

### 1. Identificar o caminho feliz crítico

Listar os fluxos que, se quebrarem, param o negócio (ex.: login → acesso ao painel, criação de pedido, pagamento).
Priorizar 1–3 fluxos, não cobrir tudo.

### 2. Escrever o teste do fluxo real

- Usar Playwright ou Cypress contra o ambiente real (staging/preview), não mocks.
- Estrutura: `page.goto(url)` → ações do usuário → `expect(page).toHaveURL/toContainText`.
- Evitar selectors frágeis (classes CSS geradas); preferir `data-testid`, `aria-label`, texto visível.

### 3. Rodar headless em CI

- Configurar no pipeline (GitHub Actions / Supabase Edge / Vercel): `npx playwright test --reporter=list`.
- Garantir que o ambiente de teste seja estável (fixtures, seeds, reset de estado).

### 4. Estabilizar flakiness

- Usar `waitForSelector` / `waitForURL` explícitos em vez de `sleep` fixo.
- Isolar testes: cada spec deve ser independente (não depender de estado de outro teste).
- Retry automático (Playwright: `retries: 1` em CI) para instabilidade de rede.

---

## Output

- Arquivo de spec e2e (ex.: `tests/e2e/login.spec.ts`).
- Comando de execução documentado no README do módulo.
- Testes passando em CI sem flakiness recorrente.

---

## Anti-patterns

- Cobrir tudo com e2e (suite lenta → desenvolvedores ignoram).
- `sleep(3000)` fixo — frágil e lento; usar waits baseados em evento.
- Mocking de rede em e2e — derrota o propósito de testar a integração real.
- Specs que dependem de ordem de execução.

---

## Relações

- Complementar a `tdd`: TDD cobre lógica unitária, e2e cobre fluxos integrados.
- Pareia com `benchmark-optimization-loop` para medir duração da suite antes de expandir.
