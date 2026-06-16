# Roadmap — v8: Camada de Disciplina (Discipline Layer)

**Milestone:** v8
**Status:** ✅ SHIPPED 2026-06-16 (auditoria PASSED, tag v8.0)

## Tese

Absorver de `addyosmani/agent-skills` (MIT) **só o que é novo/melhor** que o ECC já nos deu: a camada de disciplina comportamental + ciclo de vida. Não substitui GSD (motor de execução) nem AIOX-Core (org story-driven) — senta **em cima** deles, injetando auto-dúvida e condutas no build/verify. Nativizado em PT-BR, plugado na Deia, e shippado seguindo as próprias práticas absorvidas (quarentena antes de instalar, doubt sobre o próprio entregável, verificação por exit code).

---

## Fases (4 waves)

### Wave A — Quarentena & Atribuição ✅ DONE
6 fontes upstream baixadas em `security/quarantine/agent-skills/`; `scan-absorbed.sh` → **exit 0** (PASS=3, WARN=1 AgentShield-offline, FAIL=0). Conteúdo lido verbatim (revisão de injection inline). Cobre R8-06.

### Wave B — Autoria paralela (multi-agente) ✅ DONE
- `/doubt` (`source/skills/doubt/SKILL.md`) — autorado pela sessão principal (maior ROI). Cobre R8-01.
- `/context-engineering` — autorado pela sessão principal. Cobre R8-03.
- `operating-discipline` rule (×2: `source/rules/common/` + `.claude/rules/`, byte-idênticos) — subagente `general-purpose`. Cobre R8-02.
- Convenção de autoria + template `skill/SKILL.md.tmpl` — subagente `general-purpose`. Cobre R8-04.

### Wave C — Opt-in catálogo ✅ DONE
`/observability` + `/deprecation-migration` (`plugin: null`, `installStrategy: manual`). Cobre R8-05.

### Wave D — Wiring, gates & dogfood ✅ DONE
Wiring: Deia matrix (+2 linhas), `CORE_SKILLS` (+doubt, +context-engineering), `modules.json` (+5 entradas), `plugin-membership.md` (26→28), `README.md`. Gates binários: membership **71/0 deriva**, readme **111/111**, build-plugins + build-adapters OK, idea-doctor **0 FAIL**, bats **27/27**. Cobre R8-08.

**Dogfood (R8-07):** `/doubt` rodado sobre o próprio diff via subagente adversarial. 8 achados; **3 acionáveis corrigidos** — incl. o nº1 irônico: a skill `/doubt` **inventou uma citação** (`agent-authority.md` "personas não invocam outras personas" — frase inexistente) → exatamente a afirmação não-verificada que ela existe para pegar. Corrigida. #2/#4 documentados como carry-forward herdado/ortogonal.

---

## Progresso

| Wave | Status |
|------|--------|
| A — Quarentena | ✅ DONE |
| B — Autoria (4 itens, multi-agente) | ✅ DONE |
| C — Opt-in catálogo | ✅ DONE |
| D — Wiring + gates + dogfood | ✅ DONE |

## R8-09 — FECHADO (2026-06-16, follow-up)
`build-adapters.sh` ganhou `build_claude_project_rules()`: deploy de `source/rules/common/*.md` → `<projeto>/.claude/rules/ideiaos-common-*.md` (paridade com o Cursor `.mdc`; Claude Code auto-carrega `.claude/rules/*.md`). Só `common/` (disciplina universal); stack/domínio (marketing, supabase) ficam Cursor-side para não inflar o always-on. **Verificado em sandbox `/tmp` limpo** (7 rules, conteúdo idêntico à fonte, stack rules não vazam) e **dogfoodado no próprio repo** (manual `operating-discipline.md` removido → substituído pelo gerado).
