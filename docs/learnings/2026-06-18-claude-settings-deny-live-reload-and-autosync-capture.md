---
date: 2026-06-18
session_type: infra
incident: n/a
commit: 2a87a5c
tags: [claude-code, permissions, settings-json, autosync, security-window]
applies_to_projects: [global]
promote_to_vault: true
---

# Janela temporária de permissão no `.claude/settings.json`: o deny é relido mid-session, e um auto-committer pode capturar a janela aberta

## Trigger (quando reler isso)

Quando você for **abrir e fechar uma janela temporária** de permissão num `.claude/settings.json` (mover tools de `deny`→`ask` para uma operação gateada e reaplicar `deny` depois), especialmente num repo sob **auto-commit/auto-sync** em background.

## O padrão (abstrato)

Dois fatos operacionais sobre janelas temporárias de controle de segurança num arquivo de config **versionado**:

1. **Reaplicação vale ao vivo.** A mudança de `permissions.deny`/`ask` no `settings.json` é **relida mid-session** pelo harness — não exige restart. (Suposição anterior de que "precisa reiniciar a sessão" estava errada.) Logo a janela abre e fecha dentro da mesma sessão, e o close re-bloqueia de verdade na hora.
2. **Um auto-committer captura o estado transitório.** Se um processo de autosave/autosync commita o repo em background, ele pode **fotografar a janela ABERTA** (contenção reduzida) e empurrá-la para o remoto. O estado seguro só volta quando o seu commit de fechamento vira o HEAD.

A armadilha decorrente: ao "limpar o diff" do `settings.json`, **nunca** faça `git checkout`/revert cego — o HEAD pode ser o estado-aberto (capturado pelo auto-committer), e reverter **reabre a janela**. Compare os **sets** (não a ordem) entre HEAD e working tree antes de decidir.

## Evidência (concreta — desta sessão)

- Janela `deny→ask` de 5 tools via `lovable-window.py open` (`.planning/milestones/v10-phases/B-sandbox/lovable-window.py`).
- **Fato 1:** `remix_project` só executou **depois** do `open` (com `deny=14`); o assert pós-`close` (`deny=19`) passou — deny relido e enforçado ao vivo, sem restart.
- **Fato 2:** o commit de autosync `ead28b5` (Mac mini) capturou o `settings.json` com `deny=14/ask=5` (janela aberta) e empurrou para `origin/work`. O `git diff` mostrou o HEAD com a janela aberta; o set-diff (HEAD=14 vs working tree=19) **abortou um `git checkout` que teria reaberto a janela** — o commit de fechamento (`2a87a5c`) restaurou `deny=19`.

## Regra prática derivada

1. Abra/feche a janela com um **script idempotente `open|close`** que persiste o estado num arquivo durável (`WINDOW-STATE.json`) e roda um **assert binário** no close (`deny==N E ask==0 E allow==0`).
2. **Não confie em restart** para o deny valer — ele é relido na sessão; mas garanta que o **commit de fechamento seja o HEAD** (não deixe um auto-committer com a última palavra).
3. Para "limpar" o `settings.json`, **compare os sets deny de HEAD × working tree** antes de qualquer revert; nunca `git checkout` cego num arquivo de permissão que esteve transitoriamente aberto.
4. Trate qualquer arquivo de controle de segurança versionado como **capturável pelo autosync** — a janela aberta deve ser a mais curta possível e nunca propagada à `main` (mantenha na branch de trabalho até fechar).

## Falsos positivos / armadilhas

- "O `disabledMcpServers` já contém o connector, então estou contido" — `disabledMcpServers` **não** bloqueia um connector OAuth account-level ao vivo (tools read-only funcionaram apesar dele); o que bloqueia de fato é `permissions.deny`.
- "Sem diff no `git status` = seguro" — pode haver diff por reordenação do `json.dump` mesmo com o set idêntico; e pode haver diff real porque o HEAD foi capturado aberto. Compare os sets, não confie no status cru.

## Cross-references

- `[[autosync-pushes-feature-branches]]` — o autosync do IdeiaOS pusha qualquer branch não-main (mesma família de risco)
- `[[learning-temp-privilege-window-teardown-grants]]` — a janela deve conceder as tools de teardown
- `.planning/milestones/v10-phases/B-sandbox/lovable-window.py` — script open|close|status de referência
- Memória global: `learning_claude-settings-deny-live-reload-autosync-capture.md`

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-18 — motivo: Claude Code é stack universal
- [x] Promovido para Obsidian vault em 2026-06-18 — motivo: síntese cross-projeto
- [ ] Aplicado retroativamente em outros learnings
