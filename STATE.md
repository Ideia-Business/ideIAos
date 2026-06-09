# Estado do projeto — ideIAos

**Atualizado:** 2026-06-08 · **Branch:** `main` · **Versão ideIAos:** 1.0

## Snapshot

| Área | Status |
|------|--------|
| **ideIAos v1.0** | ✅ Lançado (2026-05-29) |
| Especificação canônica | ✅ `docs/IDEIAOS.md` |
| Orquestrador `/idea` | ✅ `skills/idea/SKILL.md` |
| Templates ideIAos | ✅ `templates/ideiaos/` (4 arquivos: IDEIAOS, GUIDE-HUMANS, GUIDE-AI, DECISION-MATRIX) |
| Skill `/ideiaos-setup` | ✅ Atualizada para verificar ideIAos (5 camadas) |
| Agent `@ideiaos-checker` | ✅ Atualizado para verificar ideIAos (5 camadas) |
| Templates híbridos | ✅ AGENTS, CLAUDE, CONTRIBUTING referenciam ideIAos |
| Setup de continuidade híbrida | ✅ Instalado |
| Arquivos operacionais | ✅ `STATE.md` + `docs/CONTINUATION_HANDOFF.md` |
| Regras para Cursor/Claude | ✅ `AGENTS.md` + `CLAUDE.md` + regra Cursor |
| README sincronizado | ✅ Refletindo ideIAos |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` |

## Mudanças recentes (2026-06-08)

- **Obsidian Second Brain conectado** — Fase B completa (acesso filesystem direto, sem MCP/plugin)
- `setup-dev-machine.sh` passo 8: injeta vault Obsidian em `~/.claude/settings.json` automaticamente (multi-máquina)
- Skills `recall-learnings` e `extract-learnings` atualizadas: Passo 5 e Passo 4b usam `grep -rIl` no vault
- **Vault completamente populado:**
  - `Projects/`: IdeiaOS, Ideiapartner, NFideia, CFO AI - Grupo RI, Lapidai
  - `References/`: Supabase, Lovable Cloud, Asaas, Stripe
  - `Stack Gotchas/`: RLS silencioso, Lovable deploy drift, Sync pesado esgota pool
  - `Changelog/`: NFideia, Ideiapartner, CFO AI - Grupo RI, Lapidai — histórico de entregas por milestone
- **Todos os CLAUDE.md atualizados** — seção "Segundo Cérebro" adicionada em todos os projetos + template
- **Protocolo de fechamento atualizado** — passo de Changelog no vault agora obrigatório em todos os projetos
- **Pendência registrada nos handoffs:** feature "Novidades" (changelog voltado ao usuário) em NFideia e Ideiapartner

## Mudanças recentes (2026-05-29)

- **ideIAos v1.0 lançado** — unifica 5 camadas (AIOX-Core + GSD + Lovable + Fase A + Continuation) sob orquestrador único `/idea`
- Skill `/idea` criada em `skills/idea/SKILL.md` — comando único de entrada com matriz de roteamento
- 4 templates ideIAos criados em `templates/ideiaos/`
- `setup.sh` ganhou etapa 5.10 (instalação `/idea`), 5.11 (GSD readiness check), 8 (camada ideIAos no projeto)
- Skill `/ideiaos-setup` reescrita para auditar as 5 camadas ideIAos
- Agent `@ideiaos-checker` (Cursor) reescrito para espelhar a skill
- README.md reescrito com ideIAos na frente, mantendo backward compatibility

## Roadmap / Ideias futuras

- **Memória compartilhada entre IDEs (Claude Code ↔ Cursor)** — hoje cada IDE tem sua própria memória (Claude Code: `~/.claude/projects/<proj>/memory/`; Cursor: separada). Quando o trabalho migra de IDE/máquina, as memórias divergem (caso real: nfideia 2026-06-08 — a memória do Claude Code ficou na sessão 35 enquanto o repo avançou para a 39 no Cursor/MacBook).
  - **Mitigação atual (suficiente p/ hoje):** o `STATE.md`/handoff/`.planning` no repo é a fonte de verdade compartilhada entre IDEs + o hook `git-sync-check.sh` (SessionStart) já força a releitura na retomada quando puxa commits (aviso de DRIFT DE ESTADO com commits + topo do STATE.md).
  - **Evolução a avaliar (próximo momento):** sincronizar as próprias memórias entre IDEs. Opções: (a) memória versionada no repo (`.planning/memory/` ou `docs/memory/`), lida por ambos; (b) passo no fechamento que exporta memórias relevantes para o repo; (c) sync/symlink das pastas de memória. Origem: drift de retomada multi-máquina; ref. memória `feedback_retomada_drift_multimaquina` (nfideia).

- **⚠️ Atenção — `versions.lock` (pin GSD) revertido pelo autosync multi-máquina.** O pin `gsd=` já foi revertido **2×** pelo autosync do Mac-mini (sessão 36 do nfideia e 2026-06-08), trocando `1.1.0` (redux, instalado em **ambas** as máquinas — `~/.claude/get-shit-done/VERSION`) pelo obsoleto pré-redux `1.36.0`. O `idea-doctor` então acusa drift (instalado ≠ pin).
  - **Causa:** o autosync (LaunchAgent, 15 min) commita o working tree **stale** do Mac-mini e desfaz o fix feito noutra máquina. **Nenhum script regenera `1.36.0`** — o `scripts/update-upstream.sh --bump` só re-pina a partir do `VERSION` instalado (`1.1.0`). Logo, é puramente o merge do autosync favorecendo a cópia antiga.
  - **Fix recorrente (aplicado):** re-pin `gsd=1.1.0` no `versions.lock` (commit `915f345`, 2026-06-08; antes `1229803` na sessão 36).
  - **Avaliar (para parar o churn):** (a) regra de merge `merge=ours` para `versions.lock` no `.gitattributes`; (b) o autosync ignorar/`assume-unchanged` esse arquivo; ou (c) o `idea-doctor`/`update-upstream` auto-corrigir o pin a partir do `VERSION` instalado quando detecta esse drift específico. Origem: drift de retomada multi-máquina (mesma família do item de memória acima).

## Nota

- Este repositório atua como base de setup para projetos novos.
- A partir da v1.0 do ideIAos, é também a referência canônica do Sistema Operacional unificado de desenvolvimento da Ideia Business.
