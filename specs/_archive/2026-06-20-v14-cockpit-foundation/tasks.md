# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Tasks: v14-cockpit-foundation

**Change:** v14-cockpit-foundation
**Capability(ies):** cockpit
**Gerado em:** 2026-06-20

Estas tasks derivam do delta e são consumíveis pelo GSD (`/gsd-plan-phase` → `/gsd-execute-phase`)
ou pelo `@dev` do AIOX. Escopo desta change = **fase v14.0 (Substrato + Espinha)** do roadmap.
Formato: `- [ ] N.M <descrição>` (N = grupo, M = subtask).

---

## 1. Preparação

- [ ] 1.1 Ler `specs/_changes/v14-cockpit-foundation/proposta.md` + blueprint (`docs/ideiaos-console/00-BLUEPRINT.md`, `02-PHASE-1-SPEC.md`) e confirmar escopo v14.0
- [ ] 1.2 Confirmar substrato no MacBook e tratar o Mac mini como read-only (assimetria entre máquinas — não assumir simetria)
- [ ] 1.3 Confirmar que nenhum verbo de mutação de produção/cross-máquina entra nesta fase (gating v14.4)

---

## 2. Substrato (espinha)

- [ ] 2.1 `idea-doctor.sh --json` — flag nova (14 seções → JSON estruturado) com fallback ANSI testado ANTES de qualquer consumidor depender do JSON
- [ ] 2.2 `infra/launchd/com.ideiaos.cockpit.plist` — 4º LaunchAgent, `StartInterval 900`, irmão de envsync/gitautosync/refresh-ai-security
- [ ] 2.3 `ideiaos-agentd` — coletor read-only que normaliza metadata e grava `snapshots/<machine_id>.json` no ref `cockpit` via `git commit-tree`/`update-ref` (NUNCA toca o working tree)
- [ ] 2.4 `console-ingest` — funde N snapshots do ref `cockpit` num read-model SQLite descartável (`~/.ideiaos/console/read-model.db`)
- [ ] 2.5 Garantir push do ref `cockpit` pelo autosync (padrão `push_planning_ref`), sem capturar working tree e sem tocar `main`

---

## 3. SPA (scaffold)

- [ ] 3.1 Scaffold Vite 7 + React 18 + TS + Tailwind + shadcn/ui (reuso de componentes do nfideia) com tema black-gold OKLCH (`--brand-hue:75`)
- [ ] 3.2 Servir em `http://127.0.0.1` em loopback, sem login (read-only quanto a produção)

---

## 4. Gates & testes

- [ ] 4.1 `scripts/check-cockpit.sh` + `idea-doctor §15` — dogfooding: agentd ativo? ref `cockpit` existe? snapshot local fresco?
- [ ] 4.2 Teste de invariante Zero-Leak (`npm run test:zeroleak`, exit-code binário, gate de release)
- [ ] 4.3 Harness de medição de Time-to-Truth: baseline via terminal (N≥5 por jornada J1/J4/J2) antes da v14.1
- [ ] 4.4 Rodar suíte e garantir verde (gates `antifragile` por exit-code, não Read tool)

---

## 5. Merge e Archive (do contrato)

- [ ] 5.1 Validar delta: `bash source/skills/spec/lib/spec-validate.sh specs/_changes/v14-cockpit-foundation`
- [ ] 5.2 Aplicar merge: `bash source/skills/spec/lib/spec-merge.sh . v14-cockpit-foundation --yes`
- [ ] 5.3 Confirmar archive em `specs/_archive/2026-06-20-v14-cockpit-foundation/`
- [ ] 5.4 Commit: `spec(cockpit): apply v14-cockpit-foundation delta`
