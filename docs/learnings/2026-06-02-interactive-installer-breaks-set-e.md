---
date: 2026-06-02
session_type: infra
incident: n/a
commit: 3018a67
tags: [setup, automation, set-e, tty, idempotency, replication]
applies_to_projects: [global]
promote_to_vault: false
---

# Instalador de terceiro interativo aborta o setup inteiro sob `set -e` (sem TTY)

## Trigger (quando reler isso)

Em 1 frase: você roda um script de setup/provisionamento em modo **não-interativo** (cron, launchd, `| pipe`, CI, máquina nova automatizada) e ele para no meio **silenciosamente** — passos posteriores (MCPs, skills) parecem "não ter rodado" mesmo o comando "tendo terminado".

## O padrão (abstrato)

Instaladores de terceiros que usam prompts interativos (inquirer, readline, `read`) **crasham quando stdin não é um terminal** (`ERR_USE_AFTER_CLOSE` no Node). Se esse comando roda dentro de um script com `set -euo pipefail`, o exit não-zero **aborta o script inteiro** — tudo que vinha depois nunca executa. O sintoma é enganoso: o log mostra só o começo do passo e "pula" para o próximo bloco, sem erro óbvio.

## Evidência (concreta — desta sessão)

- Feature: tornar o IdeiaOS 100% replicável (vendor da suíte + `--global-only` + `sync-all`).
- Commit do fix: `3018a67`
- Arquivos-chave:
  - `setup.sh:467` (antes) — `npx aiox-core@latest install` → instalador interativo (`Installer v5.2.9`, pergunta "🌐 Language" via inquirer) crashava sem TTY e, sob `set -euo pipefail`, abortava o `setup.sh --global-only` **antes** de instalar o MCP context7 e antes de refrescar as skills.
  - `setup.sh:464-483` (depois) — passo AIOX reescrito: skip-if-installed → guard `[ -t 0 ]` → `|| warn` (não-fatal).
- Como apareceu: `sync-all.sh` reportava "Ambiente saudável" mas o `idea-doctor` seguia acusando os MESMOS 3 WARN (context7 ausente + 2 skills stale) depois de "sincronizar". A pista foi a Etapa 3 do sync mostrar só os pré-requisitos e pular direto pra Etapa 4.
- Causa raiz provada rodando `bash setup.sh --global-only > log 2>&1; echo $?` → `EXIT=1` + `Error [ERR_USE_AFTER_CLOSE]: readline was closed` no tail.

## Regra prática derivada

Ao invocar QUALQUER instalador de terceiro dentro de um script de setup:
1. **Skip-if-installed** — cheque `command -v <cli>` antes; idempotência evita re-disparar o interativo.
2. **Guard de TTY** — só rode o passo interativo com `[ -t 0 ]`; sem TTY, emita um `warn` + o comando manual.
3. **Nunca fatal** — encerre o passo com `|| warn` (ou suspenda `set -e` no trecho). Provisionamento deve seguir para o resto mesmo se o opcional falhar.
4. **Teste em não-TTY** — valide com `bash setup.sh 2>&1 | cat` (o pipe remove o TTY). Rodar direto no terminal ESCONDE o bug.

## Falsos positivos / armadilhas

- Nem todo exit não-zero de instalador é "interativo sem TTY" — confirme o erro real no log (`ERR_USE_AFTER_CLOSE` / `readline` / prompt no output) antes de aplicar o guard.
- `[ -t 0 ]` testa stdin; alguns instaladores checam stdout/stderr — se o guard não bastar, force modo não-interativo via flag/env do próprio instalador quando existir.
- Não confunda com drift de cópia (global ≠ fonte): aquele resolve com re-cópia; este é o setup nem chegar lá.

## Cross-references

- Memória global: `learning_interactive_installer_breaks_setrace.md` (mesma lição, recall em qualquer projeto)
- `reference_ideiaos_overlay.md` — setup.sh, sync-all, idea-doctor, versions.lock
- `learning_idempotency_for_config_managers.md` — idempotência em scripts de config (testar rodando 2x)
- `learning_bash_c_locale_quebra_utf8_regex.md` — outra armadilha de ambiente não-interativo

## Promoção (preenchido depois)

- [x] Promovido para memória global em 2026-06-02 — motivo: padrão `[global]`, replicável em qualquer script de setup
- [ ] Promovido para Obsidian vault — Fase B
