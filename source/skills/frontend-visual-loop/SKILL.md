---
name: frontend-visual-loop
description: "Closed visual feedback loop for frontend work — render the running app, capture a screenshot + accessibility-tree snapshot, critique it against design rules, fix the code, and re-render until it passes. Runs entirely on the already-installed Chrome DevTools MCP (no Playwright install needed). Use AFTER writing or changing UI when you want to SEE the result and self-correct, not just trust the JSX. Triggers: 'veja o resultado', 'confere visualmente', 'tá feio/quebrado', 'itera no visual', 'render e corrige', 'screenshot e ajusta', 'visual review do que implementei', 'loop visual', 'antes de commitar a UI'. Complements ui-ux-pro-max (the rubric), web-quality (the audit), and gsd-ui-review (the retroactive audit)."
---

# SOURCE: IdeiaOS

# Frontend Visual Loop

A skill que **fecha o ciclo** entre escrever UI e ver a UI. O modelo escreve código frontend "às cegas" por padrão — esta skill obriga a renderizar, olhar, criticar e corrigir antes de declarar pronto.

**Idioma:** Português brasileiro.

> **Motor:** usa o **Chrome DevTools MCP** (já instalado no IdeiaOS) — `mcp__chrome-devtools__*`. NÃO requer Playwright. Snapshot por accessibility-tree (2–5KB) é mais barato e mais semântico que comparar pixels.

---

## Quando usar

### Must use
- Acabou de implementar/alterar uma página ou componente visível e quer **ver** antes de commitar
- Usuário diz "tá feio", "quebrou no mobile", "não ficou como eu queria"
- UAT visual de wizard, tabela, dialog, grid de botões (pior caso de renderização)
- Antes de `@devops *push` em qualquer mudança de UI relevante

### Skip
- Lógica de backend / API / banco
- Mudança não-visual (refactor interno, tipos)
- Quando não há app rodando e não vale subir um (use revisão estática + `ui-ux-pro-max`)

---

## Pré-condição — app rodando

```bash
# Descobrir a URL local (dev server). Exemplos comuns:
#   Vite/React → http://localhost:5173 ou :3000
#   Next.js    → http://localhost:3000
#   Lovable    → preview URL do projeto
```

Se não houver dev server de pé, suba-o (ou peça a URL de preview) antes de iniciar o loop. Sem app renderizando, esta skill não se aplica.

---

## O Loop (máx. 3 iterações)

```
1. RENDER    → navega até a URL no Chrome DevTools MCP
2. CAPTURE   → screenshot + snapshot (accessibility tree) + console + viewport mobile
3. CRITIQUE  → confronta com references/critique-rubric.md (ancorado em ui-ux-pro-max)
4. FIX       → edita o código para resolver os achados de maior severidade
5. RE-RENDER → repete 1–3; para quando PASS ou no limite de 3 iterações
```

**Limite de 3 iterações** evita loop infinito. Se ainda houver BLOCK na 3ª, pare e reporte os achados restantes ao usuário — não force.

### Passo 1–2 — Render & Capture (sequência de ferramentas MCP)

```
mcp__chrome-devtools__list_pages           # ver abas abertas
mcp__chrome-devtools__new_page  (ou navigate_page) → URL alvo
mcp__chrome-devtools__take_snapshot         # a11y tree (barato, semântico)
mcp__chrome-devtools__take_screenshot       # evidência visual (desktop)
mcp__chrome-devtools__resize_page → 390x844 # iPhone-ish
mcp__chrome-devtools__take_screenshot       # evidência visual (mobile)
mcp__chrome-devtools__list_console_messages # erros/warns de runtime
```

> Sempre capture **desktop E mobile**. A maioria dos defeitos visuais nossos (memória: `feedback_uat_visual_antes_de_commitar_ux`) aparece só em um dos dois — `max-w-md` com Dialog, 3+ botões em row, coluna nova em tabela.

### Passo 3 — Critique

Carregue `references/critique-rubric.md` e classifique cada achado:

| Severidade | Ação |
|-----------|------|
| **BLOCK** | overflow horizontal, texto cortado, contraste < 4.5:1, elemento sobreposto, erro no console, conteúdo invisível | corrige nesta iteração |
| **FLAG** | espaçamento inconsistente, hierarquia fraca, alvo de toque < 44px, falta estado de loading/empty | corrige se barato |
| **PASS** | nada bloqueante | encerra o loop |

Use `ui-ux-pro-max --domain ux` / `--domain style` para fundamentar o critério em vez de "achismo".

### Passo 4 — Fix

Edite o código-fonte (não o DOM no browser — o DOM é descartável). Aplique a menor mudança que resolve o BLOCK. Re-renderize.

---

## Saída ao usuário

Ao encerrar, reporte com evidência honesta:

```
🔁 Visual Loop — <componente/página>

Iterações: <n>/3
Veredito: PASS | FLAG restante | BLOCK não resolvido

Desktop: <1 linha do que foi observado>
Mobile:  <1 linha do que foi observado>
Console: <limpo | N erros>

Corrigido nesta sessão:
- <fix 1>
- <fix 2>

Restante (não bloqueante):
- <flag, se houver>
```

Nunca diga "ficou bom" sem ter renderizado. Se não rodou o loop, diga que não rodou.

---

## Anti-padrões

- ❌ Declarar UI pronta sem renderizar
- ❌ Editar o DOM via `evaluate_script` para "consertar" (some no reload) — sempre editar o código-fonte
- ❌ Ignorar mobile
- ❌ Passar de 3 iterações empurrando o mesmo BLOCK — escale ao usuário
- ❌ Instalar Playwright "pra ficar melhor" — o Chrome DevTools MCP já cobre; instalar MCP é exclusivo de @devops

---

## Integração no IdeiaOS

| Skill | Papel |
|-------|-------|
| `ui-ux-pro-max` | fornece o **rubric** (regras de a11y, estilo, layout) |
| `web-quality` | auditoria programática CWV/WCAG/SEO (mais profunda que o loop) |
| `gsd-ui-review` | audit visual 6-pilares **retroativo** (pós-fase) — **módulo externo / planejado v3, não incluído no manifesto IdeiaOS**; esta skill é **durante** o trabalho |
| `lovable-handoff` | rode o loop **antes** do handoff de deploy |

## Upgrade opcional (futuro)
Playwright MCP adiciona Core Web Vitals em tempo real e bridge de sessão logada. Só vale se precisar testar fluxos atrás de login. Instalação é operação de **@devops** (`claude mcp add playwright -s user -- npx @playwright/mcp@latest`).

> **Nota sobre `gsd-ui-review`:** referenciado na tabela acima como módulo complementar mas não
> faz parte do `manifests/modules.json` do IdeiaOS. É um skill planejado para v3 ou
> disponível via GSD plugin. Esta skill funciona completamente sem ele.
