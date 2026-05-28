---
name: recall-learnings
description: Lê aprendizados anteriores (`docs/learnings/`, memória Claude, e Obsidian vault se conectado) antes de começar qualquer planejamento de resolução. Garante que a IA inicia a sessão sabendo o que já foi aprendido sobre o projeto, evitando re-explorar gotchas conhecidos.
---

# Skill: recall-learnings

Você é responsável por **carregar contexto de aprendizado** antes de propor qualquer plano de resolução em um projeto. Esta skill é invocada **automaticamente no início** de:

- Resolução de incidente (bug fix, INC-NN)
- Implementação de feature não-trivial
- Refactor que toca múltiplos arquivos
- Qualquer pedido que comece com "implementar", "corrigir", "investigar", "padronizar"

Não é invocada para perguntas conversacionais simples ("o que é X?", "como funciona Y?").

**Idioma:** Português brasileiro.

---

## Pipeline obrigatório

Executar na ordem. Cada passo é cumulativo (não substitui o anterior).

### Passo 1 — Identidade do projeto

```bash
pwd                              # diretório atual
cat AGENTS.md 2>/dev/null | head -50   # quem somos, regras invioláveis
cat STATE.md 2>/dev/null | head -30    # estado operacional
```

Se `AGENTS.md` declara `Deploy: Lovable Cloud` ou tem seção `lovable-deploy-section`,
ativar mentalmente as regras Lovable (não editar arquivos protegidos, etc.).

### Passo 2 — Últimos learnings do projeto

```bash
ls -lt docs/learnings/*.md 2>/dev/null | head -5
```

Ler os **5 mais recentes** integralmente (cada um é curto). Especialmente atenção a:
- Seção **Trigger** — bate com o pedido atual?
- Seção **Regra prática derivada** — aplica aqui?
- Seção **Falsos positivos** — evita pisar de novo

### Passo 3 — Busca por tags relevantes

Extrair 2-3 keywords do pedido do usuário (ex.: "bug RLS combobox cliente").
Para cada keyword, buscar no learnings:

```bash
grep -li "<keyword>" docs/learnings/*.md 2>/dev/null
```

Ler arquivos que matchem **e** estejam fora dos 5 mais recentes.

### Passo 4 — Memória Claude global

Ler `~/.claude/projects/<encoded>/memory/MEMORY.md` (índice). Seguir links `[[name]]` que pareçam
relevantes. Especial atenção a:
- `reference_*` — gotchas arquiteturais, APIs externas
- `feedback_*` — preferências do usuário
- `reference_lovable_projects.md` — se este projeto é Lovable

### Passo 5 — Obsidian Vault (se conectado — Fase B)

Se MCP Obsidian está disponível e este projeto tem `obsidian_vault_path` em `.aiox-ai-config.yaml`:

```
mcp__obsidian__search "<keywords do pedido>"
```

Ler resultados com peso de "referência curada" — vault tem síntese cross-projeto.

Se não conectado: pular silenciosamente.

### Passo 6 — Postmortems relacionados

```bash
ls docs/postmortems/ 2>/dev/null | head -10
# Se o pedido cita INC-NN: ler docs/postmortems/INC-NN-*.md inteiro
```

Postmortems contam **história**; learnings extraem **padrão**. Os dois se complementam.

---

## O que NÃO fazer

- ❌ Dump cru no chat de tudo que leu. Sintetize em 3-5 bullets.
- ❌ Reabrir decisões já fechadas em learnings/postmortems sem motivo novo.
- ❌ Ignorar `Falsos positivos` registrados — eles existem por experiência amarga.
- ❌ Citar memória para o usuário com "lembro que…" — usar como base do plano sem nome dropping.

---

## Saída esperada (compacta)

Antes do plano de resolução em si, entregar 1 bloco assim:

```
🧠 Contexto carregado:
- Identidade: <projeto>, stack <X>, deploy <Y>
- Últimos learnings relevantes: <2-3 títulos>
- Memória aplicável: <1-2 referências>
- Postmortem relevante: <se houver>
- ⚠️ Falsos positivos a evitar: <se houver>
```

Depois prosseguir com o plano normalmente.

---

## Quando esta skill é invocada

- Auto-invocação no início de qualquer pedido de implementação/correção/investigação não-trivial
- `/recall-learnings` (explícito) — força carregamento se o auto-trigger não disparou
- Após `/cursor-continuation` — complementa o handoff de continuidade com aprendizado de domínio

## Limitações

- Não decide pelo usuário; carrega contexto e propõe plano.
- Não modifica nenhum arquivo. Só lê.
- Se o vault Obsidian estiver indisponível, segue sem ele (sem falhar).

## Memórias relacionadas

- `reference_learnings_protocol.md` — protocolo completo de aprendizado
- `reference_lovable_projects.md` — quais projetos são Lovable
- Skill `extract-learnings` — par desta no fim da sessão
