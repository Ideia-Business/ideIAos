# R15-15 — Consolidar docs de instalação num runbook único · SUMMARY

**Status:** ✅ DONE 2026-06-26 · **Wave:** 2 · **Executor:** sessão principal
**Veredito:** pass — duplicação verbatim eliminada, índice criado, gate de cobertura estendido e
**anti-teatro provado** (rejeita input inválido em cada sub-gate).

## Interpretação (decisão do dono — rastreabilidade No-Invention)

O requisito literal diz "**consolidar os 5 docs num runbook único**". Surfacei a tensão antes de
executar (sessão anterior, AskUserQuestion): só **2** dos docs têm a duplicação/gotchas
(`INSTALL-WINDOWS.md` ⊂ `windows-wsl.md`, **54% verbatim** = 32/59 linhas); `onboarding-novo-dev.md`
e `env-setup-dev.md` são **heterogêneos** (zero gotchas, assuntos distintos). O dono decidiu
**"eliminar duplicação + índice"** — NÃO fundir 5 docs heterogêneos num monólito (que pioraria a
navegação). Esta é a interpretação executada; o "runbook único" do requisito = **single-source por
assunto** (cada gotcha tem um dono), não um arquivo só.

## O que foi feito (4 partes)

| # | Ação | Resultado (exit-code) |
|---|------|------------------------|
| 1 | `docs/guides/windows-wsl.md` = **runbook único** de Windows/Linux (single-source dos 3 gotchas) | já cobre `checkout work`=6× · `/mnt/c`=2× · `autocrlf`=2× — nada a mudar |
| 2 | `INSTALL-WINDOWS.md` (raiz) → **stub-ponteiro fino** p/ Caminho B | **163 → 22 linhas**; 0 gotchas / 0 âncoras de corpo residuais |
| 3 | `docs/guides/README.md` (novo) = **índice** de instalação por SO/assunto | mapeia cada doc; NÃO funde heterogêneos; todos os links resolvem |
| 4 | `scripts/check-readme-sync.sh` **estendido** (não-novo-script) com gate de cobertura | 6 checagens novas (3 gotchas no runbook + 3 âncoras ausentes no stub) |
| + | `README.md`: ponteiro fino ao novo índice (seção de onboarding existente) | sync 140/140, exit 0 |

## Verificação (exit-code, com input INVÁLIDO — anti-teatro)

| Gate | Resultado |
|------|-----------|
| 1 — `bash -n check-readme-sync.sh` | ✅ |
| 2 — rodar real: 6/6 do gate R15-15 ✅; README **140/140**, exit 0 | ✅ |
| 3a — **ANTI-TEATRO:** stub re-duplica corpo (âncora `nvm install --lts`) → **exit 1** | ✅ rejeita |
| 3b — **ANTI-TEATRO:** runbook sem gotcha `autocrlf` → **exit 1** | ✅ rejeita |
| 3c — controle: runbook completo + stub limpo → **exit 0** | ✅ aceita |
| 4 — links do stub + índice resolvem (6 alvos `test -f`) | ✅ |

O gate de cobertura é o **enforcement durável** do R15-15: se alguém re-duplicar o corpo no stub OU
remover um gotcha do runbook, o `idea-doctor`/CI (que chamam `check-readme-sync.sh`) **falham (exit 1)**.

## Decisões / fronteira

- **Estendi `check-readme-sync.sh`, não criei script** (requisito explícito). Degradação graciosa:
  se `windows-wsl.md` ausente (outro repo) → `skip`, nunca FAIL.
- **Âncoras de corpo** (`nvm install --lts`, `githubcli-archive-keyring.gpg`, `crontab -l`) são strings
  que SÓ existem no bloco de comandos do Caminho B → sinal binário de "stub re-duplicou o corpo".
- **Não fundi `onboarding`/`env-setup`** (disciplina de escopo + decisão do dono): são single-source
  dos seus próprios assuntos. O índice os referencia; não os absorve.
- **Hard-gate R15-05 ✅ satisfeito** (A-04 DONE) — consolidei só após o fix factual mergeado, senão
  propagaria o erro.

## Arquivos

- `INSTALL-WINDOWS.md` (raiz): runbook duplicado → stub-ponteiro (163→22 linhas).
- `docs/guides/README.md` (**novo**): índice de instalação por SO/assunto.
- `scripts/check-readme-sync.sh`: +seção "Cobertura de gotchas do runbook (R15-15)".
- `README.md`: +ponteiro ao índice (seção de onboarding).
- `docs/guides/windows-wsl.md`: **inalterado** (já era o runbook único; só confirmado por grep -c).
