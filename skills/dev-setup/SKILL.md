---
name: dev-setup
description: Ponto de entrada único para garantir que o projeto atual tem o setup completo do Ideia Business dev-setup (AIOX Core, camada Lovable, Fase A — loop de aprendizado, hooks Claude Code, rules Cursor, padrões de debugging em produção). Idempotente — pula tudo que já está instalado. Use no início de qualquer projeto novo (clone fresh, primeiro acesso, ou quando suspeitar que algo está faltando). Detecta automaticamente o projeto atual via cwd.
---

# Skill: dev-setup

Você é responsável por garantir que o projeto atual está com o setup completo do **Ideia Business dev-setup**: AIOX, camada Lovable, Fase A de aprendizado, hooks Claude Code, rules Cursor.

**Idioma:** Português brasileiro.

---

## Quando esta skill é invocada

- `/dev-setup` (explícito) — você invoca manualmente
- Sugestão automática via hook SessionStart quando projeto Lovable não tem setup Fase A
- Quando você diz "configura aqui" / "roda o setup" / "isso aqui está com tudo?"

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

## Passo 2 — Diagnóstico antes de aplicar

Antes de modificar nada, mostre ao usuário o que está e não está instalado:

```bash
# Auditoria do estado atual
PROJ="$PWD"
echo "🔍 Diagnóstico do projeto: $PROJ"
echo ""

# AGENTS.md
if [ -f "$PROJ/AGENTS.md" ]; then
  if grep -q "Loop de aprendizado contínuo" "$PROJ/AGENTS.md"; then
    echo "  ✅ AGENTS.md com Fase A"
  else
    echo "  ⚠️  AGENTS.md existe mas SEM Fase A (precisa refresh)"
  fi
else
  echo "  ❌ AGENTS.md ausente"
fi

# Cursor rule
if [ -f "$PROJ/.cursor/rules/agents-md-protocol.mdc" ]; then
  echo "  ✅ Cursor rule agents-md-protocol"
else
  echo "  ❌ Cursor rule ausente"
fi

# Learnings
if [ -d "$PROJ/docs/learnings" ]; then
  echo "  ✅ docs/learnings/"
else
  echo "  ❌ docs/learnings/ ausente"
fi

# Postmortems
if [ -d "$PROJ/docs/postmortems" ]; then
  echo "  ✅ docs/postmortems/"
else
  echo "  ❌ docs/postmortems/ ausente"
fi

# Lovable layer
if [ -f "$PROJ/docs/playbook-implantacao.md" ]; then
  echo "  ✅ Playbook Lovable"
else
  echo "  ❌ Playbook Lovable ausente"
fi

# Hook Claude global
if [ -f "$HOME/.claude/hooks/extract-learnings-reminder.sh" ]; then
  echo "  ✅ Hook extract-learnings-reminder (global)"
else
  echo "  ❌ Hook extract-learnings-reminder ausente"
fi

# Hook registrado em settings
if grep -q "extract-learnings-reminder.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  echo "  ✅ Hook registrado em ~/.claude/settings.json"
else
  echo "  ❌ Hook NÃO registrado em settings.json (ação manual)"
fi
```

Apresentar ao usuário em formato compacto. Se tudo ✅ → terminar com "Setup já completo. Nada a fazer."

---

## Passo 3 — Aplicar setup (se houver gaps)

Se houver pelo menos 1 ❌ ou ⚠️, perguntar **uma vez** antes de aplicar:

> "Detectei gaps no setup. Aplicar agora via `bash dev-setup/setup.sh --project-only --lovable $PWD`? (idempotente — pula o que já está instalado)"

Se sim, executar:

```bash
bash "$SETUP_DIR/setup.sh" --project-only --lovable "$PWD"
```

Output deve mostrar linha por linha o que foi instalado vs pulado.

---

## Passo 4 — Ações manuais pendentes (se houver)

Se o hook `extract-learnings-reminder.sh` foi instalado mas **não está registrado** em `~/.claude/settings.json`, mostrar snippet de como registrar:

```
Adicione esta entrada em hooks.PostToolUse de ~/.claude/settings.json:

{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash \"/Users/<você>/.claude/hooks/extract-learnings-reminder.sh\"",
      "timeout": 5
    }
  ]
}
```

Avisar que isso requer autorização do classifier (regra de segurança — IA não pode auto-modificar settings sem aval).

---

## Passo 5 — Confirmação final

Apresentar resumo:

```
✅ Setup do projeto verificado.

Estado pós-setup:
- AGENTS.md: ✅ (Fase A + camada Lovable)
- Cursor rules: ✅ (.cursor/rules/*.mdc)
- docs/learnings/: ✅
- docs/postmortems/: ✅
- docs/playbook-implantacao.md: ✅
- Hook Claude: ⚠️ instalado mas precisa registro manual em settings.json

Próximos passos sugeridos:
- (se aplicável) Registrar hook no settings.json
- Pode trabalhar normalmente — protocolos estão ativos
```

---

## Quando NÃO invocar esta skill

- Projeto já é claramente NÃO-Lovable (ex: dev-setup em si, biblioteca Node pública, etc.)
- Usuário pediu uma tarefa específica diferente; não interromper para sugerir setup
- Projeto Lovable mas usuário já confirmou que NÃO quer Fase A (raro, mas respeitar)

---

## Filosofia

Esta skill é o **único ponto de entrada** para o dev-setup. Tudo é idempotente:

- Rodar 1x ou 100x dá o mesmo resultado
- Setup parcial pré-existente é completado, não substituído
- Mudanças do usuário em arquivos locais são preservadas (refresh respeita marcadores BEGIN/END)

Você pode dizer ao usuário com confiança: "pode rodar quantas vezes quiser, não estraga nada".

---

## Memórias relacionadas

- `reference-lovable-projects.md` — projetos onde aplica
- `reference-learnings-protocol.md` — Fase A explicada
- `feedback-extract-learning-under-pressure.md` — tendência de pular passos (esta skill ajuda a recuperar)
