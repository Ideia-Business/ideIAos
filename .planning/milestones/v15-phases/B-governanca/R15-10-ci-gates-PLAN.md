# R15-10 — Governança no CI (4 gates repo-puros em PR) · PLAN

**Milestone:** v15 · **Fase:** B · **Wave:** 1 · **Req:** R15-10 · **Origem:** GER-04 / CKF-08(2)

## Objetivo (goal-backward)

Os 4 gates **repo-puros** de governança rodam no CI (GitHub Actions, repo PÚBLICO → sem billing),
barrando deriva antes/no merge — SEM rodar no CI os gates que varrem `$HOME` (falhariam no runner).

## Contexto verificado (No-Invention)

- **`evals.yml` (job `structural`) JÁ cobre 2 dos 4 gates:** `check-plugin-membership` (linha 143) e
  `check-source-headers --strict` (linha 147, advisory). Roda em push [work,main] + pull_request.
- **`evals.yml` NÃO roda idea-doctor nem check-env-not-tracked** (comentário linhas 136-138 explica:
  idea-doctor audita a install global de uma máquina-dev e falharia num runner fresco). → o "REMOVER
  idea-doctor/check-env do CI" do requisito **já está satisfeito** (nada a remover).
- **Faltam 2 gates no CI:** `check-readme-sync` e `check-memory-not-on-main`. Ambos repo-puros
  (rodam exit 0 a partir do repo; zero ref a `$HOME`).
- **`check-memory-not-on-main` usa `git symbolic-ref --short HEAD`** p/ saber o destino — em detached
  HEAD (default do `actions/checkout`) veria "" e pularia. Precisa de checkout com branch nomeado.

## Decisão de design

Criar `.github/workflows/governance.yml` com **só os 2 gates faltantes** (não re-rodar o que o
evals.yml cobre — requisito explícito). Checkout com `ref: ${{ github.head_ref || github.ref_name }}`
(branch nomeado) p/ o gate de memória inspecionar de verdade num push p/ main. Triggers:
`push: [main]` + `pull_request` — **não** em push de `work` (evita ruído a cada tick do autosync).

## Tasks

1. `governance.yml`: job `repo-gates` com checkout nomeado + validação YAML + `check-readme-sync` +
   `check-memory-not-on-main`. Header documenta por que os outros 2 estão no evals e idea-doctor fora.
2. Validar: YAML válido; comandos existem; gates rodam.

## Gates (exit-code, com input INVÁLIDO)

| Gate | Verificação | Resultado |
|------|-------------|-----------|
| 1 | YAML válido (ruby local; python3+PyYAML no runner, igual evals.yml) | ✅ |
| 2 | comandos referenciados existem (`check-readme-sync`, `check-memory-not-on-main`) | ✅ |
| 3 | `check-readme-sync` verde com o novo arquivo | ✅ |
| 4 | **anti-teatro:** sandbox `.planning/` trackado + memória nova → `check-memory-not-on-main` exit 1; sem memória → exit 0 | ✅ |

## Pendente de prova no Actions

"CI verde em PR" (DoD) só se confirma após push (Actions roda no runner). Code-complete localmente;
o run real dispara no próximo push p/ main (observável via `gh run list`).
