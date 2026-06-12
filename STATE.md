# Estado do projeto — ideIAos

**Atualizado:** 2026-06-12 · **Branch:** `work` → `main` · **Versão ideIAos:** v3 em andamento (v2.0 base)

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
| README sincronizado | ✅ Refletindo ideIAos (92/92) |
| **Fase 07 contexts-evals** | ✅ Completa (07-01 Wave 1a + 07-02 Wave 1b + 07-03 Wave 2) |
| **Fase 13 security-dx-manifest** | ✅ Completa (13-01 + 13-02 + 13-03) |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` |

## Mudanças recentes (2026-06-12) — Fase 13 security-dx-manifest completa

- **Fase 13 completa:** 3 planos, fechando gaps G-09/G-10/G-11/G-12/G-13/G-14/G-15
- `scripts/idea-doctor.sh`: Seção 7a (deny rules → warn, proxy statusline) + Seção 8 (contexts/aliases/statusline) — 0 FAIL
- `security/scan-absorbed.sh`: `\bnc\b` word boundary — elimina false positives TypeScript sem enfraquecer detecção de netcat real
- `source/skills/ideiaos-catalog/SKILL.md`: contagem dinâmica — remove hardcode "60 módulos"
- `source/skills/banner-design/SKILL.md`: deps claudekit-origin documentadas (frontend-design/ai-artist/ai-multimodal/chrome-devtools)
- `source/skills/frontend-visual-loop/SKILL.md`: gsd-ui-review marcado como módulo externo/planejado v3
- `scripts/apply-to-all-projects.sh`: novo wrapper multi-repo (dry-run DEFAULT, --apply, --only) — propaga setup.sh a todos ~/dev/*
- `manifests/modules.json`: 72 módulos (entry script-apply-to-all-projects adicionado)
- **Decisions:** warn vs fail para deny rules; dry-run default para apply-to-all; claudekit-origin como deps externas explícitas
- **Commits:** `85c0d06` (autosync 13-01), `6428bb8` (13-02), `6e31fcc` (13-03)

## Mudanças recentes (2026-06-12, noite) — Fix definitivo: reverts do pin GSD

- **6 barreiras ativas** contra reverts do `gsd=` no `versions.lock` (detalhes na seção "RESOLVIDO" do Roadmap abaixo): autosync exclui o lock do `add -A` · `scripts/check-versions-lock.sh` (novo) no pre-commit · `--bump` recusa valor pré-redux · mensagens de drift direcionais · comentário anti-armadilha no lock · propagação via `ideiaos-update.sh`
- Re-pin `gsd=1.1.0` — doctor sem drift (GSD = pin)
- **2 learnings globais extraídos** (`docs/learnings/2026-06-12-*`), promovidos a memória Claude e vault Obsidian; Changelog do vault atualizado
- `ideiaos-update.sh` ganhou também passo de **registro de hooks no settings.json** (fonte: hooks.json do plugin ideiaos-core) — agora 5 passos
- **Commits:** `7a4f54b` (implementação, via autosync) · `2d2ded2` (doc) · `3528919` (learnings)
- **Máquina:** sessão no MacBook-Air-2 (já protegido). **Pendente: Mac mini** rodar `git pull && bash scripts/ideiaos-update.sh`

## Mudanças recentes (2026-06-12) — Fase 07 Wave 2 (07-03) completa

- **Fase 07 completa:** contexts de modo + statusline agora instaláveis e catalogados
- `setup.sh` passos 5.22 e 5.23: deploy contexts → `~/.ideiaos/contexts/`; aliases snippet (offer-not-edit, T-01-10); deploy statusline → `~/.ideiaos/statusline/`; snippet settings.json (offer-not-edit)
- `manifests/modules.json`: 66 → 70 módulos (+4: context-dev/review/research, statusline-ideiaos, kinds "context"/"statusline", plugin null)
- `manifests/plugin-membership.md`: seção "Setup-only (não-plugin): contexts + statusline" com rationale e tabela
- `README.md`: 89/89 sincronizado — tree atualizada (contexts/ populado, statusline/ adicionado, evals/ top-level), "O que instala" +4 linhas, seção Terminal com aliases/statusline/evals
- Todos os gates passaram sem `--no-verify`: `bash -n setup.sh` + `check-readme-sync.sh` exit 0
- **Commits:** `4973609` (setup.sh), `3f2be17` (manifests + README)
- **Wave 1 (07-01 + 07-02):** source/contexts/, source/statusline/, evals/ (22 casos) — já completos

## Mudanças recentes (2026-06-12) — Fase 06 completa

- **IdeiaOS como plugin/marketplace** — instalável via `/plugin marketplace add Ideia-Business/IdeiaOS`
- `.claude-plugin/marketplace.json` — marketplace 'ideiaos' com 3 sub-plugins
- `plugins/` — 3 plugins gerados por `build-plugins.sh` (versionados para GitHub marketplace)
  - `ideiaos-core` — 15 agents + 11 hooks + 23 skills + hooks.json com `${CLAUDE_PLUGIN_ROOT}`
  - `ideiaos-design-suite` — 10 skills de design
  - `ideiaos-lovable` — skill /lovable-handoff + doutrina + templates
- `scripts/build-plugins.sh` — gerador idempotente `source/` → `plugins/`
- `manifests/modules.json` — 66 módulos + campo `plugin` de membership
- `manifests/plugin-membership.md` — mapeamento legível módulo → plugin
- **Dirs-fallback removidos** — `skills/`, `agents/`, `hooks/`, `templates/` removidos da raiz (`source/` é superset verificado, comm -23 vazio)
- **Scripts atualizados** — check-readme-sync, install-git-hooks, install-global-patches, update-design-suite, idea-doctor — todos apontam para `source/`
- **Pre-commit hook re-instalado** — protege `source/|scripts/|plugins/|manifests/`
- **README atualizado** — seção 'Instalação via Plugin', árvore pós-Fase 06, links corrigidos
- **Commit:** `5171cd9` (joint, sem `--no-verify`, hook passou)

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

- **✅ RESOLVIDO (2026-06-12) — `versions.lock` (pin GSD) revertido 3×: solução definitiva em 6 camadas.** O pin `gsd=` foi revertido 3× de `1.1.0` (redux, atual) para o legado pré-redux `1.36.0` (commits `c7fc184` autosync 08/06, e `3724ee9` **agente Cursor** 11/06).
  - **Diagnóstico final (corrige o anterior):** NÃO era só o autosync. Dois modos de falha: (a) autosync commitando working tree stale; (b) **agente de IA/`--bump` em máquina com instalação pré-redux** gravando o valor antigo — a armadilha é que o versionamento do redux RECOMEÇOU em 1.x, então `1.1.0` (redux) é MAIS NOVO que `1.36.0` (pré-redux), e parece o contrário.
  - **Barreiras instaladas:** (1) `git-autosync` exclui `versions.lock` do `add -A` (fonte: `setup-dev-machine.sh`; propagado às máquinas pelo passo 2/4 do `ideiaos-update.sh`); (2) pre-commit roda `scripts/check-versions-lock.sh` — bloqueia valor pré-redux (1.30–1.99) e edição manual que não corresponda ao instalado (bypass: `IDEIAOS_LOCK_OVERRIDE=1`); (3) `update-upstream.sh --bump` recusa gravar valor pré-redux; (4) mensagens de drift do `idea-doctor`/`update-upstream` agora são direcionais (dizem qual lado está errado); (5) comentário anti-armadilha no próprio `versions.lock`; (6) re-pin `gsd=1.1.0`.
  - **Obsolescência:** remover o padrão anti-legado (1.30–1.99) quando o redux se aproximar de 1.30 (anos) — documentado em `check-versions-lock.sh`.

## Nota

- Este repositório atua como base de setup para projetos novos.
- A partir da v1.0 do ideIAos, é também a referência canônica do Sistema Operacional unificado de desenvolvimento da Ideia Business.
