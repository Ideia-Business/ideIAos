---
name: ideiaos-catalog
description: "Lista os módulos do IdeiaOS (agents, skills, hooks, rules, templates) a partir de manifests/modules.json — instalados vs disponíveis, filtrável por kind e stack. Use quando o usuário pergunta 'o que tem disponível', 'quais agents/skills existem', ou quer instalar algo sob demanda."
---

# SOURCE: IdeiaOS v2
# Skill: /ideiaos-catalog — Catálogo de Módulos IdeiaOS

## Quando usar

- "O que tem disponível no IdeiaOS?"
- "Quais skills/agents existem?"
- "Tem algum agent para X?"
- "Instala Y sob demanda"
- "Quero ver o que está instalado vs o que posso instalar"

## Como funciona

O catálogo lê `manifests/modules.json` (fonte de verdade — contagem real em runtime via `len(d["modules"])`, atualmente 70+ módulos) e determina, para cada módulo, se está **instalado** ou apenas **disponível**.

### Lógica de status

- **Instalado (claude):** arquivo existe em `~/.claude/agents/` ou `~/.claude/skills/`
- **Instalado (cursor):** arquivo existe em `~/.cursor/agents/`
- **Disponível:** está no manifesto mas não instalado no target atual

### Filtros disponíveis

| Filtro | Valores | Efeito |
|--------|---------|--------|
| `--kind` | `agent`, `skill`, `hook`, `rule`, `template` | Mostrar só aquele kind |
| `--stack` | `react`, `supabase`, `lovable`, `node`, `typescript`, `nextjs`, `python` | Módulos para aquela stack |
| `--status` | `installed`, `available` | Apenas instalados ou apenas disponíveis |

## Processo

### Passo 1 — Ler o manifesto

```bash
python3 -c "
import json
d = json.load(open('manifests/modules.json'))
print(f'Total: {len(d[\"modules\"])} módulos')
for m in d['modules']:
    print(m['kind'], m['id'], m['installStrategy'])
"
```

### Passo 2 — Checar instalação no target

```bash
# Para target claude:
for skill_dir in ~/.claude/skills/*/; do basename "$skill_dir"; done
ls ~/.claude/agents/ 2>/dev/null || echo "sem agents instalados"
```

### Passo 3 — Apresentar tabela

Formato de saída:

```
Catálogo IdeiaOS — {len(d['modules'])} módulos

| ID | Kind | Strategy | Status |
|----|------|----------|--------|
| skill-idea | skill | always | ✅ instalado |
| skill-tdd | skill | always | ⬜ disponível |
| agent-security-reviewer | agent | always | ⬜ disponível |
| skill-two-instance-kickoff | skill | manual | ⬜ disponível |
...
```

### Passo 4 — Sugerir instalação

Para módulos `available`, orientar como instalar:

```bash
# Rebuild completo (instala todos os módulos always + os de stack detectada)
bash scripts/build-adapters.sh --target claude

# Setup completo (inclui hooks + templates + skills)
bash setup.sh --global-only

# Para módulos manual: copiar diretamente
cp source/skills/<nome>/SKILL.md ~/.claude/skills/<nome>/SKILL.md
```

## Referência rápida — bloco bash

```bash
python3 -c "
import json
d = json.load(open('manifests/modules.json'))
print(f'--- Catálogo IdeiaOS ({len(d[\"modules\"])} módulos) ---')
for m in d['modules']:
    print(m['kind'].ljust(10), m['id'].ljust(45), m['installStrategy'])
"
```

## Módulos com installStrategy: manual

Esses módulos não são instalados automaticamente — requerem cópia explícita:

- `skill-two-instance-kickoff` — kickoff com 2 instâncias em paralelo
- `skill-llms-txt` — geração de llms.txt
- `skill-mcp-to-cli` — conversão de MCP em CLI
- `skill-banner-design` — banners e design social
- `skill-brand` — identidade de marca
- `skill-design` — padrões de design
- `skill-slides` — apresentações

Para instalar qualquer um:
```bash
cp source/skills/<nome>/SKILL.md ~/.claude/skills/<nome>/SKILL.md
```

## Módulos por stack

| Stack | Módulos exclusivos |
|-------|-------------------|
| `stack:supabase` | `skill-database-migrations` |
| `stack:react` | `skill-accessibility`, `skill-design-system`, `skill-ui-styling`, `skill-ui-ux-pro-max`, `skill-motion`, `skill-frontend-visual-loop` |
| `stack:lovable` | `skill-lovable-handoff`, `template-lovable` |
| `stack:node` | `skill-web-quality` |

Use `bash setup.sh` em um projeto para detecção automática de stack e instalação seletiva.
