# A-03 — setup-dev-machine.sh resiliente a repo sem acesso (R15-04) — SUMMARY

**Fase:** v15-A · **Plano:** A-03 · **Wave:** 1 · **Status:** DONE
**Data:** 2026-06-25 · **Executor:** @dev (Dex)
**Arquivo modificado:** `setup-dev-machine.sh` (+50/-1, único arquivo)

## Objetivo (R15-04)

Tornar o passo 3 (clone) resiliente a repositório que o dev NÃO consegue acessar.
Antes: qualquer falha de clone virava `warn "clone falhou — pulando"; continue` —
indistintamente para repo particular legítimo (cfoai-grupori, 1º do array, só Gustavo
tem acesso) e para repo obrigatório (IdeiaOS, do qual os passos 4-7 dependem com `die`
tardio na linha 144). Resultado: ruído enganoso + IdeiaOS inacessível estourava tarde.

## O que foi feito

### Task 1 — helper `probe_repo_access` (passo 2.6, antes do loop)
Inserido helper que sonda `gh api repos/<slug>` por EXIT-CODE, envolto em `timeout 20`
(shim do passo 2.5), e ecoa um token determinístico:
- **OK** — exit 0 (acessível)
- **NOACCESS** — exit≠0 + stderr contém `HTTP 404` (`grep -qi`, determinístico)
- **INCONCLUSIVE** — exit≠0 SEM `HTTP 404` (timeout/SSO/403/rede)

O slug é DERIVADO da URL do array REPOS via `sed` (`s#^https?://github\.com/##; s#\.git$##`) —
nunca hardcoded. Todas as vars novas são `local`. Retorna 0 sempre (decisão é do chamador).

### Task 2 — probe plugado no loop com 3 estados + IdeiaOS fatal
No ramo `else` do loop (repo ainda não clonado), ANTES do `git clone`:
- **NOACCESS** → se `[ "$name" = "IdeiaOS" ]` → `die` (FATAL); senão `warn` DIRECIONAL
  ("remova a linha do array REPOS se não trabalha nele") + `continue` (pula, setup segue).
- **INCONCLUSIVE** → `warn` DISTINTO ("rede/SSO/timeout — NÃO confirma falta de acesso,
  vou tentar clonar mesmo assim") + tenta o clone (anti falso-negativo de rede).
- **OK** → segue o fluxo normal.
- Clone-falho do IdeiaOS também vira `die` (antes só estourava no passo 4).

Comportamento legado preservado: repo já clonado (`.git` existe) segue pelo ramo `fetch`
sem probe; clone normal + `warn "clone falhou — pulando"` (fallback não-IdeiaOS) intactos.

### Task 3 — verificação por exit-code contra o GitHub real
Provas executadas (não fixtures). Autosync NÃO foi tocado por instrução direta do usuário
(ver decisão abaixo).

## Invariantes respeitadas
1. Slug derivado da URL (sem repo literal no probe) — ✓ provado por grep negativo.
2. Escopo MÍNIMO: obrigatoriedade = `[ "$name" = "IdeiaOS" ]`, sem tier/flag/array paralelo — ✓.
3. cfoai PERMANECE no array (degrada gracioso, não removido) — ✓.
4. Classificação por exit-code + `grep -qi 'HTTP 404'`, nunca NL — ✓.
5. Probe envolto em `timeout 20` — ✓.
6. Build-script: `die` (exit 1) no caminho fatal; opcional sem-acesso não derruba — ✓.
7. Idempotência: probe só no ramo de clone novo, não no ramo fetch — ✓.
8. Avisos direcionais distintos (sem-acesso diz o que fazer; inconclusivo diz que NÃO é falta de acesso) — ✓.
9. Autosync: NÃO tocado — ver decisão.
10. Nada empurrado (push/PR é @devops) — ✓.

## Gates (exit-codes)

| Gate | Comando | rc |
|------|---------|----|
| (1) Sintaxe | `bash -n setup-dev-machine.sh` | **0** |
| (2) Probe roteia 404→NOACCESS vs rede→INCONCLUSIVE | extração do helper real + 3 estados contra GitHub real | **0** (assert-OK, assert-NOACCESS, assert-INCONCLUSIVE, assert-distintos todos 0) |
| (3) IdeiaOS obrigatório sem acesso = FATAL | sandbox de decisão por exit-code | IdeiaOS NOACCESS→**rc=1 (DIE)**; IdeiaOS clone-falho→**rc=1 (DIE)** |
| (4) Anti-teatro (caso de FALHA) | matriz NAME×TOKEN×CLONE | cfoai NOACCESS→rc=0 (pula); cfoai clone-falho→rc=0; INCONCLUSIVE→rc=0 (clona). Distinção só por nome. |

### Prova dos 3 estados contra o GitHub REAL
- `ideIAos` → token **OK** (exit 0)
- `repo-inexistente-xyz123` → token **NOACCESS** (exit≠0 + `gh: Not Found (HTTP 404)`)
- host morto (`--hostname nonexistent.invalid.localhost`) → **INCONCLUSIVE** (exit≠0 +
  `connection refused`, SEM `HTTP 404`) — provado que rede morta NUNCA vira NOACCESS.

### Prova da matriz de decisão (sandbox por exit-code)
| name | token | clone | rc | resultado |
|------|-------|-------|----|-----------|
| IdeiaOS | NOACCESS | — | 1 | DIE (fatal) |
| IdeiaOS | OK | falha | 1 | DIE (clone-falho fatal) |
| cfoai-grupori | NOACCESS | — | 0 | WARN direcional + pula |
| cfoai-grupori | OK | falha | 0 | WARN legado + pula |
| cfoai-grupori | INCONCLUSIVE | ok | 0 | clona (anti falso-negativo) |
| IdeiaOS | INCONCLUSIVE | ok | 0 | clona normal |

## Decisão autônoma registrada
`[AUTO-DECISION]` Task 1(a)/3(c) pausar+religar autosync via `launchctl` → **PULADO**.
Razão: instrução direta do usuário nesta sessão ("NÃO mexa no autosync (já pausado)")
tem precedência sobre o passo do plano (operating-discipline §precedência: instrução
direta do usuário > skill/comando ativo). O pré-requisito da invariante 9 (autosync não
atropela a cirurgia) já está satisfeito pela ação do usuário; o religamento cabe a ele.
O classificador de auto-mode bloqueou o `launchctl bootout`, confirmando a fronteira.

## Disciplina de escopo
Só `setup-dev-machine.sh` foi tocado. Outros arquivos em `git status`
(README.md, scripts/install-alias.sh, source/agents/ideiaos-checker.md,
source/skills/ideiaos-setup/SKILL.md, scripts/idea-smoke.sh) são PRÉ-EXISTENTES,
fora do escopo A-03 — não modificados por esta execução.

## Confirmações finais
- NÃO commitei (working-tree modificado, último commit inalterado: `a323e39`).
- NÃO empurrei (push/PR é exclusivo @devops).
- NÃO mexi no autosync (instrução do usuário respeitada).
