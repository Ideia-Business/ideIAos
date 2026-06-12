# adapters/_scaffold/ — Template para novos harnesses

## O que é um adapter

Um **adapter** transforma os assets de `source/` (fonte única de verdade do IdeiaOS) para o formato esperado por um harness de IA específico.

Cada harness tem convenções próprias:
- **Claude:** hooks em `~/.claude/hooks/`, agents em `~/.claude/agents/`, rules injetadas no CLAUDE.md
- **Cursor:** rules em `.cursor/rules/*.mdc`, agents em `.cursor/agents/`
- **Codex (OpenAI):** rules em `AGENTS.md`, skills como system prompts
- **Gemini CLI:** rules em system prompt via flag `--system-prompt`
- **opencode:** configuração em `.opencode/`
- **Zed:** rules em `.zed/settings.json` → `assistant.default_context_files`

O adapter é quem faz a tradução — nunca edite artefatos gerados diretamente. Edite `source/` e recompile.

## Como criar um novo adapter

1. Copie `adapter.sh.tmpl` para `adapters/<harness-name>/adapter.sh`
2. Defina as 3 variáveis obrigatórias no topo:
   - `HARNESS_NAME` — nome do harness (ex: `codex`, `gemini`, `zed`)
   - `RULES_FORMAT` — formato de destino das rules (`mdc`, `md`, `json`, `txt`)
   - `DESTINATION` — diretório raiz de destino
3. Implemente as funções `install_rules()`, `install_hooks()`, `install_agents()` conforme o harness
4. Registre o novo harness em `manifests/modules.json` com `targets: ["<harness-name>"]` nos módulos relevantes
5. Adicione o adapter ao `build-adapters.sh` principal no bloco `case "$TARGET"` como nova opção

## Harnesses planejados (Fase 04+)

| Harness | Status | Notes |
|---------|--------|-------|
| `claude` | ATIVO | `build-adapters.sh --target claude` |
| `cursor` | ATIVO | `build-adapters.sh --target cursor` |
| `codex` | planejado | OpenAI Codex CLI — AGENTS.md como sistema |
| `gemini` | planejado | Gemini CLI — `--system-prompt` flag |
| `opencode` | planejado | `.opencode/` config dir |
| `zed` | planejado | `.zed/settings.json` context files |

## Rebuild

```bash
# Rebuild de todos os harnesses ativos
bash scripts/build-adapters.sh --target all

# Rebuild seletivo
bash scripts/build-adapters.sh --target claude
bash scripts/build-adapters.sh --target cursor --project-dir /caminho/do/projeto

# Dry-run (ver o que seria feito sem executar)
bash scripts/build-adapters.sh --target all --dry-run
```

## Princípio

```
source/
├── skills/    ─┐
├── agents/    ─┤─── build-adapters.sh ──→ adapters/claude/
├── hooks/     ─┤                      └─→ adapters/cursor/
├── templates/ ─┤                      └─→ adapters/codex/   (futuro)
└── rules/     ─┘                      └─→ adapters/gemini/  (futuro)
```

Nunca edite `adapters/<harness>/` diretamente. Sempre: edite `source/` → recompile.
