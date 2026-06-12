---
phase: 16
plan: "01"
subsystem: marketplace
tags: [marketplace, plugins, versioning, r4-08, r4-09]
dependency_graph:
  requires: []
  provides: [marketplace-validated, plugins-v3.0.0, readme-installation-revised]
  affects: [versions.lock, plugins/, .claude-plugin/marketplace.json, README.md]
tech_stack:
  added: []
  patterns: [claude-plugin-marketplace, local-path-install]
key_files:
  created: []
  modified:
    - scripts/build-plugins.sh
    - plugins/ideiaos-core/.claude-plugin/plugin.json
    - plugins/ideiaos-design-suite/.claude-plugin/plugin.json
    - plugins/ideiaos-lovable/.claude-plugin/plugin.json
    - .claude-plugin/marketplace.json
    - versions.lock
    - README.md
decisions:
  - "Visibilidade pública do repo: decisão explicitamente documentada como PENDENTE DO USUÁRIO (documentado no README)"
  - "Adicionado description ao marketplace.json para corrigir warning do claude plugin validate"
  - "README atualizado para usar 'claude plugin' (CLI real) em vez de '/plugin' (slash command)"
metrics:
  duration: "4m"
  completed: "2026-06-12"
  tasks: 2
  files_modified: 7
---

# Phase 16 Plan 01: Marketplace-Ready Summary

**One-liner:** Fluxo de instalação via marketplace validado end-to-end com clone limpo + versões alinhadas para 3.0.0 em 3 plugins + README revisado com nota de visibilidade pendente.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 | R4-08 — Validação de fora (clone limpo) | 6a93a39 | Done |
| 2 | R4-09 — Versões 3.0.0 + README | 6a93a39 | Done |

## R4-08 — Validação de Fora: Evidências

**Clone limpo:**
```
git clone --depth 1 file:///Users/gustavolopespaiva/dev/IdeiaOS /tmp/ideiaos-market-test
```

**Validações estruturais (todas passaram):**
- marketplace.json parse: OK (name=ideiaos, 3 plugins)
- 3 sources resolvem: OK (`./plugins/ideiaos-core`, `./plugins/ideiaos-design-suite`, `./plugins/ideiaos-lovable`)
- 3 plugin.json válidos: OK (versão 2.0.0 no momento, bumped para 3.0.0 em seguida)
- hooks.json do core: OK (11 `${CLAUDE_PLUGIN_ROOT}` literais; 11 .sh referenciados e presentes)
- skills frontmatter: OK (23 skills, todas com `---` no topo)
- agents frontmatter: OK (15 agents, todos com `---`)

**Fluxo CLI real (claude suporta plugin marketplace headless):**
```
claude plugin validate /tmp/ideiaos-market-test
→ Validation passed with warnings
  (warning: no marketplace description — corrigido adicionando "description" ao marketplace.json)

claude plugin marketplace add /tmp/ideiaos-market-test --scope local
→ Successfully added marketplace: ideiaos (declared in local settings)

claude plugin install ideiaos-core@ideiaos
→ Successfully installed plugin: ideiaos-core@ideiaos (scope: user)

claude plugin uninstall ideiaos-core
→ Successfully uninstalled plugin: ideiaos-core (scope: user)
```

**Resultado R4-08:** APROVADO — fluxo real end-to-end confirmado.

## R4-09 — Versões 3.0.0 + README

**Mudanças:**
- `scripts/build-plugins.sh`: `version: '2.0.0'` → `version: '3.0.0'` (fonte única; plugins/ regenerados)
- `plugins/ideiaos-core/.claude-plugin/plugin.json`: 2.0.0 → 3.0.0
- `plugins/ideiaos-design-suite/.claude-plugin/plugin.json`: 2.0.0 → 3.0.0
- `plugins/ideiaos-lovable/.claude-plugin/plugin.json`: 2.0.0 → 3.0.0
- `versions.lock`: `ideiaos-plugin=2.0.0` → `ideiaos-plugin=3.0.0`
- `.claude-plugin/marketplace.json`: adicionado campo `description` (corrige warning de validação)
- `README.md`: seção "Instalação via Plugin" revisada (ver abaixo)

**README — mudanças principais:**
1. Comandos corrigidos de `/plugin` para `claude plugin` (CLI real vs. slash command)
2. Opção A (GitHub público) e Opção B (path local / repo privado) documentadas
3. Nota explícita: "Decisão de tornar o repo público: pendente do usuário."
4. Tabela atualizada com coluna Versão (3.0.0 para os 3 plugins)
5. `/plugin update` → `claude plugin update`

**Gates:**
- `bash scripts/build-plugins.sh`: OK (todos 3 plugins regenerados)
- `node` parse dos 4 JSONs: OK
- `bash scripts/check-readme-sync.sh`: 92/92 ✅
- `bash scripts/check-versions-lock.sh`: ✅ pin gsd=1.1.0 válido
- commit sem --no-verify: hook passou limpo

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Adicionado campo `description` ao marketplace.json**
- **Found during:** Task 1 (R4-08) — `claude plugin validate` retornou warning
- **Issue:** marketplace.json sem campo `description` — warning do validador oficial
- **Fix:** Adicionado `"description"` ao marketplace.json
- **Files modified:** `.claude-plugin/marketplace.json`
- **Commit:** 6a93a39

**2. [Rule 1 - Bug] README usava `/plugin` (slash command) em vez de `claude plugin` (CLI)**
- **Found during:** Task 2 (R4-09) — ao revisar a seção de instalação
- **Issue:** Comandos prefixados com `/plugin` são slash commands do Claude Code interativo; a instalação real usa o CLI `claude plugin ...`
- **Fix:** Corrigidos todos os comandos na seção de instalação
- **Files modified:** `README.md`
- **Commit:** 6a93a39

## Known Stubs

None — todas as referências de versão, paths e comandos são concretos e verificados.

## Threat Flags

None — sem novos endpoints, auth paths, file access patterns ou schema changes.

## Self-Check: PASSED

- [x] `.planning/phases/16-marketplace-ready/16-01-SUMMARY.md` — this file
- [x] `scripts/build-plugins.sh` — version 3.0.0 confirmed
- [x] `plugins/ideiaos-core/.claude-plugin/plugin.json` — version 3.0.0
- [x] `plugins/ideiaos-design-suite/.claude-plugin/plugin.json` — version 3.0.0
- [x] `plugins/ideiaos-lovable/.claude-plugin/plugin.json` — version 3.0.0
- [x] `versions.lock` — ideiaos-plugin=3.0.0
- [x] `.claude-plugin/marketplace.json` — description added
- [x] Commit 6a93a39 exists
