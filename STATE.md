# Estado do projeto — dev-setup

**Atualizado:** 2026-05-29 · **Branch:** `main` · **Versão IdeiaOS:** 1.0

## Snapshot

| Área | Status |
|------|--------|
| **IdeiaOS v1.0** | ✅ Lançado (2026-05-29) |
| Especificação canônica | ✅ `docs/IDEIAOS.md` |
| Orquestrador `/idea` | ✅ `skills/idea/SKILL.md` |
| Templates IdeiaOS | ✅ `templates/ideiaos/` (4 arquivos: IDEIAOS, GUIDE-HUMANS, GUIDE-AI, DECISION-MATRIX) |
| Skill `/dev-setup` | ✅ Atualizada para verificar IdeiaOS (5 camadas) |
| Agent `@setup-checker` | ✅ Atualizado para verificar IdeiaOS (5 camadas) |
| Templates híbridos | ✅ AGENTS, CLAUDE, CONTRIBUTING referenciam IdeiaOS |
| Setup de continuidade híbrida | ✅ Instalado |
| Arquivos operacionais | ✅ `STATE.md` + `docs/CONTINUATION_HANDOFF.md` |
| Regras para Cursor/Claude | ✅ `AGENTS.md` + `CLAUDE.md` + regra Cursor |
| README sincronizado | ✅ Refletindo IdeiaOS |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` |

## Mudanças recentes (2026-05-29)

- **IdeiaOS v1.0 lançado** — unifica 5 camadas (AIOX-Core + GSD + Lovable + Fase A + Continuation) sob orquestrador único `/idea`
- Skill `/idea` criada em `skills/idea/SKILL.md` — comando único de entrada com matriz de roteamento
- 4 templates IdeiaOS criados em `templates/ideiaos/`
- `setup.sh` ganhou etapa 5.10 (instalação `/idea`), 5.11 (GSD readiness check), 8 (camada IdeiaOS no projeto)
- Skill `/dev-setup` reescrita para auditar as 5 camadas IdeiaOS
- Agent `@setup-checker` (Cursor) reescrito para espelhar a skill
- README.md reescrito com IdeiaOS na frente, mantendo backward compatibility

## Nota

- Este repositório atua como base de setup para projetos novos.
- A partir da v1.0 do IdeiaOS, é também a referência canônica do Sistema Operacional unificado de desenvolvimento da Ideia Business.
