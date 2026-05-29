---
name: dev-setup
description: Ponto de entrada único para garantir que o projeto atual tem o setup completo do IdeiaOS — Sistema Operacional unificado de desenvolvimento da Ideia Business (AIOX Core, GSD, camada Lovable, Fase A — loop de aprendizado, hooks Claude Code, rules Cursor, padrões de debugging em produção, orquestrador /idea). Idempotente — pula tudo que já está instalado. Use no início de qualquer projeto novo (clone fresh, primeiro acesso, ou quando suspeitar que algo está faltando). Detecta automaticamente o projeto atual via cwd.
---

# Skill: dev-setup

Você é responsável por garantir que o projeto atual está com o setup completo do **IdeiaOS** — Sistema Operacional unificado da Ideia Business. Isso cobre 5 camadas: AIOX-Core, GSD, Lovable, Fase A (loop de aprendizado), Continuation cross-IDE.

**Idioma:** Português brasileiro.

---

## Quando esta skill é invocada

- `/dev-setup` (explícito) — você invoca manualmente
- Sugestão automática via hook SessionStart quando projeto sem IdeiaOS
- Quando você diz "configura aqui" / "roda o setup" / "isso aqui está com tudo?"
- Sugestão automática do `/idea` quando detecta `IDEIAOS.md` ausente

---

## Pré-condição — descobrir o cwd

```bash
pwd
```

Esse é o projeto-alvo. Não faça setup em outro diretório sem confirmação explícita do usuário.

---

## Passo 1 — Localizar o `dev-setup`

```bash
ls "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/dev-setup/setup.sh" 2>/dev/null \
  || ls "$HOME/Projects/dev-setup/setup.sh" 2>/dev/null \
  || ls "$HOME/dev-setup/setup.sh" 2>/dev/null
```

Se nenhum encontrar: instruir o usuário a clonar `git clone git@github.com:Ideia-Business/dev-setup.git` em local conveniente.

---

## Passo 2 — Diagnóstico antes de aplicar (5 camadas IdeiaOS)

Antes de modificar nada, mostre ao usuário o que está e não está instalado por camada:

```bash
PROJ="$PWD"
echo "🔍 Diagnóstico IdeiaOS — $(basename "$PROJ")"
echo ""

# ── Manifesto IdeiaOS ──
[ -f "$PROJ/IDEIAOS.md" ] && echo "  ✅ IDEIAOS.md (manifesto na raiz)" || echo "  ❌ IDEIAOS.md ausente — projeto não está sob IdeiaOS"
[ -d "$PROJ/docs/ideiaos" ] && echo "  ✅ docs/ideiaos/ (guias humanos + IA)" || echo "  ❌ docs/ideiaos/ ausente"

# ── [AIOX] identidade + governance ──
echo ""
echo "  [AIOX]"
if [ -f "$PROJ/AGENTS.md" ]; then
  if grep -q "Loop de aprendizado contínuo" "$PROJ/AGENTS.md"; then
    echo "  ✅ AGENTS.md com Fase A"
  else
    echo "  ⚠️  AGENTS.md existe mas SEM Fase A (precisa refresh)"
  fi
else
  echo "  ❌ AGENTS.md ausente"
fi
[ -f "$PROJ/CLAUDE.md" ] && echo "  ✅ CLAUDE.md" || echo "  ❌ CLAUDE.md ausente"
[ -f "$PROJ/.aiox-ai-config.yaml" ] && echo "  ✅ .aiox-ai-config.yaml" || echo "  ❌ .aiox-ai-config.yaml ausente"

# ── [GSD] orquestração goal-backward ──
echo ""
echo "  [GSD]"
if [ -d "$PROJ/.planning" ]; then
  echo "  ✅ .planning/ (GSD workspace)"
  [ -d "$PROJ/.planning/phases" ]   && echo "    ✅ .planning/phases/"   || echo "    ⚠️  .planning/phases/ ausente"
  [ -d "$PROJ/.planning/intel" ]    && echo "    ✅ .planning/intel/"    || echo "    ⚠️  .planning/intel/ ausente"
  [ -d "$PROJ/.planning/research" ] && echo "    ✅ .planning/research/" || echo "    ⚠️  .planning/research/ ausente"
else
  echo "  ❌ .planning/ ausente (GSD workspace não pronto)"
fi
if compgen -G "$HOME/.claude/skills/gsd-*" > /dev/null 2>&1; then
  GSD_COUNT="$(ls -d "$HOME/.claude/skills"/gsd-* 2>/dev/null | wc -l | tr -d ' ')"
  echo "  ✅ $GSD_COUNT skills /gsd-* disponíveis globalmente"
else
  echo "  ❌ Skills /gsd-* não detectadas em ~/.claude/skills/ — instale via plugins do Claude Code"
fi

# ── [Lovable] (se aplicável) ──
echo ""
echo "  [Lovable]"
[ -f "$PROJ/docs/playbook-implantacao.md" ] && echo "  ✅ Playbook Lovable" || echo "  ❌ Playbook Lovable ausente (ok se projeto não-Lovable)"
[ -d "$PROJ/docs/lovable" ] && echo "  ✅ docs/lovable/" || echo "  ❌ docs/lovable/ ausente (ok se projeto não-Lovable)"

# ── [Fase A] loop de aprendizado ──
echo ""
echo "  [Fase A — Learning]"
[ -d "$PROJ/docs/learnings" ]   && echo "  ✅ docs/learnings/"   || echo "  ❌ docs/learnings/ ausente"
[ -d "$PROJ/docs/postmortems" ] && echo "  ✅ docs/postmortems/" || echo "  ❌ docs/postmortems/ ausente"
[ -f "$HOME/.claude/hooks/extract-learnings-reminder.sh" ] && echo "  ✅ Hook extract-learnings-reminder (global)" || echo "  ❌ Hook ausente"
grep -q "extract-learnings-reminder.sh" "$HOME/.claude/settings.json" 2>/dev/null && echo "  ✅ Hook registrado em settings.json" || echo "  ❌ Hook NÃO registrado em settings.json (ação manual)"

# ── [Continuation] cross-IDE ──
echo ""
echo "  [Continuation]"
[ -f "$PROJ/STATE.md" ] && echo "  ✅ STATE.md" || echo "  ❌ STATE.md ausente"
[ -f "$PROJ/docs/CONTINUATION_HANDOFF.md" ] && echo "  ✅ docs/CONTINUATION_HANDOFF.md" || echo "  ❌ docs/CONTINUATION_HANDOFF.md ausente"
[ -f "$HOME/.claude/skills/cursor-continuation/SKILL.md" ] && echo "  ✅ /cursor-continuation (global)" || echo "  ❌ /cursor-continuation ausente"
[ -f "$HOME/.cursor/agents/claude-continuation.md" ] && echo "  ✅ @claude-continuation (global)" || echo "  ❌ @claude-continuation ausente"

# ── Cursor rules ──
echo ""
echo "  [Cursor rules]"
[ -f "$PROJ/.cursor/rules/agents-md-protocol.mdc" ]    && echo "  ✅ agents-md-protocol.mdc"    || echo "  ❌ agents-md-protocol.mdc ausente"
[ -f "$PROJ/.cursor/rules/session-continuation.mdc" ]  && echo "  ✅ session-continuation.mdc"  || echo "  ❌ session-continuation.mdc ausente"
[ -f "$PROJ/.cursor/rules/planning-branch.mdc" ]       && echo "  ✅ planning-branch.mdc"       || echo "  ❌ planning-branch.mdc ausente"

# ── Orquestrador /idea ──
echo ""
echo "  [Orquestrador IdeiaOS]"
[ -f "$HOME/.claude/skills/idea/SKILL.md" ] && echo "  ✅ /idea (global)" || echo "  ❌ /idea ausente — instale via setup.sh"
```

Apresentar ao usuário em formato compacto. Se tudo ✅ → terminar com "Setup IdeiaOS completo. Nada a fazer."

---

## Passo 3 — Aplicar setup (se houver gaps)

Se houver pelo menos 1 ❌ ou ⚠️, perguntar **uma vez** antes de aplicar:

> "Detectei gaps no setup IdeiaOS. Aplicar agora via `bash dev-setup/setup.sh --project-only --lovable $PWD`? (idempotente — pula o que já está instalado)"

Se sim, executar:

```bash
bash "$SETUP_DIR/setup.sh" --project-only --lovable "$PWD"
```

Output deve mostrar linha por linha o que foi instalado vs pulado.

---

## Passo 4 — Ações manuais pendentes (se houver)

Se hooks foram instalados mas **não estão registrados** em `~/.claude/settings.json`, mostrar snippet de como registrar:

```
Adicione estas entradas em ~/.claude/settings.json:

{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/extract-learnings-reminder.sh\"",
          "timeout": 5
        }]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/dev-setup-readme-reminder.sh\"",
          "timeout": 3
        }]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/dev-setup-detector.sh\"",
          "timeout": 3
        }]
      }
    ]
  }
}
```

Avisar que isso requer autorização do classifier (regra de segurança — IA não pode auto-modificar settings sem aval).

---

## Passo 5 — Confirmação final

Apresentar resumo:

```
✅ Setup IdeiaOS verificado.

Estado pós-setup:
- IDEIAOS.md (manifesto): ✅
- docs/ideiaos/ (guias humanos + IA + matrix): ✅
- AIOX (AGENTS.md + CLAUDE.md): ✅
- GSD (.planning/ + skills globais): ✅
- Lovable (playbook + docs/lovable/): ✅ ou N/A
- Fase A (learnings + postmortems + hooks): ✅
- Continuation (STATE.md + CONTINUATION_HANDOFF.md): ✅
- Cursor rules: ✅
- Orquestrador /idea (global): ✅

Próximos passos:
- (se aplicável) Registrar hooks no settings.json
- Comando de entrada recomendado: /idea <pedido em linguagem natural>
- Para conhecer o sistema: ler IDEIAOS.md, depois docs/ideiaos/GUIDE-HUMANS.md
```

---

## Quando NÃO invocar esta skill

- Projeto já é claramente NÃO-Lovable e usuário pediu setup ultra-mínimo
- Usuário pediu uma tarefa específica diferente; não interromper para sugerir setup
- Projeto Lovable mas usuário já confirmou que NÃO quer Fase A (raro, mas respeitar)

---

## Filosofia

Esta skill é o **único ponto de entrada para setup**. Tudo é idempotente:

- Rodar 1x ou 100x dá o mesmo resultado
- Setup parcial pré-existente é completado, não substituído
- Mudanças do usuário em arquivos locais são preservadas (refresh respeita marcadores BEGIN/END)

Você pode dizer ao usuário com confiança: "pode rodar quantas vezes quiser, não estraga nada".

**Após o setup, o comando recomendado de uso diário é `/idea <pedido>`** — orquestrador que roteia para a camada certa (AIOX, GSD, Lovable, Fase A, Continuation).

---

## Memórias relacionadas

- `reference_ideiaos.md` — manifesto do sistema
- `reference-lovable-projects.md` — projetos onde aplica
- `reference-learnings-protocol.md` — Fase A explicada
- `feedback-extract-learning-under-pressure.md` — tendência de pular passos (esta skill ajuda a recuperar)
