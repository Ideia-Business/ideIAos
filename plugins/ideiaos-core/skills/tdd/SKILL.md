---
name: tdd
description: "Test-Driven Development: RED→GREEN→REFACTOR. Use proativamente para lógica de negócio com I/O definido (validação, transformação, regra, endpoint). Escreve teste que falha ANTES da implementação."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: tdd

**Idioma:** Português brasileiro.

---

## Quando usar

- Você consegue escrever `expect(fn(input)).toBe(output)` antes de `fn` existir.
- Lógica de negócio com entradas e saídas claras: validações, transformações, regras de domínio, endpoints.
- Refactors que precisam de rede de segurança (testes existentes ou novos).

## Quando NÃO usar

- UI/estilos visuais — o "certo" não é verificável via assertion.
- Glue code trivial (wrappers sem lógica).
- Configuração pura (env vars, arquivos de config).

---

## Processo: RED → GREEN → REFACTOR

### Fase 1 — RED (teste falha)

1. Ler o requisito e definir o contrato: `(input) → output`.
2. Criar o arquivo de teste **antes** do arquivo de implementação.
3. Escrever o teste mínimo que expressa o comportamento esperado.
4. Rodar — o teste **deve** falhar. Se passar, o comportamento já existe ou o teste está errado.
5. Commit: `test(<escopo>): adiciona teste falhando para <feature>`.

### Fase 2 — GREEN (mínimo para passar)

1. Escrever a implementação **mínima** para o teste passar — sem over-engineering.
2. Rodar — o teste **deve** passar.
3. Se não passar: depurar implementação, não o teste.
4. Commit: `feat(<escopo>): implementa <feature>`.

### Fase 3 — REFACTOR (limpar sem quebrar)

1. Limpar: remover duplicação, melhorar nomes, extrair funções.
2. Rodar — os testes **devem** continuar passando.
3. Commit: `refactor(<escopo>): refatora <feature>` (somente se houve mudanças relevantes).

---

## Output

- Arquivo de teste com assertions claras.
- Implementação mínima que passa.
- 2–3 commits atômicos (RED / GREEN / REFACTOR).

---

## Anti-patterns

- Escrever a implementação antes do teste (faz "fake TDD").
- Testar o mock em vez do comportamento real.
- Fazer RED e GREEN no mesmo commit (perde o sinal de falha).
- Testes que testam detalhes de implementação (não o comportamento).

---

## Relações

- Pareia com `api-design` (define o contrato antes de TDD).
- Pareia com `e2e-testing` (TDD cobre lógica isolada; e2e cobre fluxos integrados).
- Fase TDD gate do executor GSD usa esta skill como referência.
