---
name: code-tour
description: "Gera um tour guiado de uma feature/fluxo específico — sequência comentada arquivo:linha → arquivo:linha. Use proativamente para explicar 'como X funciona' a um humano ou IA."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: code-tour

**Idioma:** Português brasileiro.

---

## Quando usar

- Explicar o funcionamento de um fluxo específico (não o projeto inteiro).
- Onboarding de novo dev em uma feature existente.
- Documentar código complexo para revisão ou auditoria.
- Preparar contexto para um agente de IA que vai modificar aquele fluxo.

---

## Processo

### 1. Localizar o entrypoint do fluxo

Identificar onde o fluxo começa: endpoint de API, evento de UI, job agendado, CLI command.

### 2. Seguir as chamadas

Rastrear a execução passo a passo:
- Qual função é chamada?
- Qual arquivo ela está?
- O que ela faz (em 1 linha)?
- Para onde passa o controle?

### 3. Anotar cada salto

Para cada passo, registrar:
- **Arquivo e linha** onde acontece.
- **O que acontece aqui** — 1 frase descritiva.
- **Por que** (opcional, quando não óbvio).

### 4. Montar o tour numerado

Formato padrão:

```
Passo 1 — src/api/auth/login.ts:42
  Recebe o payload { email, password }; valida schema com Zod.

Passo 2 — src/services/auth.service.ts:18
  Consulta usuário no Supabase por email; retorna null se não encontrado.

Passo 3 — src/services/auth.service.ts:31
  Compara hash da senha com bcrypt.compare(); lança AuthError se falhar.

Passo 4 — src/api/auth/login.ts:55
  Gera JWT de acesso + refresh token; retorna { access_token, refresh_token }.
```

---

## Output

Tour numerado com:
- Número do passo.
- `arquivo:linha`.
- Explicação em 1 linha.
- (Opcional) nota de "por que" para lógica não óbvia.

---

## Anti-patterns

- Tour de 50+ passos (ninguém lê; dividir em sub-fluxos).
- Explicar o que o código faz sem dizer por que (valor está no "porquê").
- Confundir com `codebase-onboarding` (ver diferença abaixo).

---

## Diferença de `codebase-onboarding`

- `code-tour`: **um fluxo específico** em detalhe (arquivo:linha por arquivo:linha).
- `codebase-onboarding`: **visão geral do projeto** (stack, estrutura, como rodar, gotchas).

Use `codebase-onboarding` para entender o projeto; use `code-tour` para mergulhar em um fluxo.
