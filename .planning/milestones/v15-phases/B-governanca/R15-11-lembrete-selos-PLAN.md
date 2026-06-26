# R15-11 — Lembrete dos gates de fechamento (LaunchAgent que notifica, nunca carimba) · PLAN

**Milestone:** v15 · **Fase:** B · **Wave:** 1 · **Req:** R15-11 · **Origem:** GER-03 + GER-08(ff-merge)
**depends_on:** R15-06 (✅ A-08).

## Objetivo (goal-backward)

Parar de esquecer os 3 gates de fechamento — incluindo o ff-merge `work→main`, que o crítico do v15
identificou como a rotina mais frequente e frágil (mesma classe de risco dos selos). Um LaunchAgent
NOTIFICA quando algo está velho — e JAMAIS carimba (não automatiza `--record`/`--gate`).

## Contexto verificado (No-Invention)

- LaunchAgents existentes: `com.ideiaos.{cockpit,refresh-ai-security}.plist` (template a espelhar:
  `/bin/bash` + path absoluto, `StartCalendarInterval`, `StandardOutPath`).
- `check-soak.sh <milestone>` exige milestone posicional; `--status`/`--record`. Ledger
  `.planning/soak/<ms>.log` formato `epoch|iso|machine|idea_doctor=PASS|regression=PASS|commit`.
- `check-security-freshness.sh --tier` → token `ok|warn|egregious|unbootstrapped` (machine-readable).
- 5 ledgers SOAK (v11-v14), todos de milestones JÁ tagueados → o lembrete deve filtrar por tag.

## Tasks

1. `scripts/remind-closeout-gates.sh` (read-only, exit 0 sempre):
   - **ff-merge:** idade do commit mais antigo em `origin/main..work` > `REMIND_FF_H` (24h).
   - **SOAK:** itera `.planning/soak/*.log`; pula milestone com tag `vX.*` (fechado); lembra se último
     heartbeat > `REMIND_SOAK_H` (48h).
   - **frescor:** `check-security-freshness --tier` ∈ {warn, egregious} → lembra.
   - Notifica via `osascript` nativo + stdout. **NUNCA** executa `--record`/`--gate`.
2. `infra/launchd/com.ideiaos.closeout-reminder.plist` — 1×/dia 19h, path absoluto, `/usr/bin/git`.

## Gates (exit-code, com input INVÁLIDO)

| Gate | Verificação | Resultado |
|------|-------------|-----------|
| 1 | `bash -n` sintaxe | ✅ |
| 2 | roda exit 0 (read-only) | ✅ |
| 3 | **anti-carimbo:** zero invocação de `--record`/`--gate` no código (só menção em comentário; `--tier` só) | ✅ |
| 4 | plist XML válido (`plutil -lint`) | ✅ |
| 5 | gatilho determinístico (`date +%s` + `/3600`); não usa heurística de "sessão" | ✅ |
| 6 | **anti-teatro positivo:** `REMIND_FF_H=0` com 1 commit não-merjado → lembrete DISPARA | ✅ |

## Invariantes

- learning `automate-the-reminder-not-the-integrity-stamp`: automatizar o carimbo faria a automação
  virar ator sintético e fraudaria o gate. Por isso só LÊ + notifica.
- launchd não herda PATH → `/usr/bin/git` absoluto. Plist instalado por passo MANUAL (consentimento).
