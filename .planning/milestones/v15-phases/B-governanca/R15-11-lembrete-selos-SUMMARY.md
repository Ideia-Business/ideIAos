# R15-11 — Lembrete dos gates de fechamento · SUMMARY

**Status:** ✅ DONE 2026-06-26 · **Wave:** 1 · **depends_on:** R15-06 (✅) · **Executor:** sessão principal

## O que foi feito

- **`scripts/remind-closeout-gates.sh`** — lembrete read-only (exit 0 sempre) dos 3 gates de
  fechamento, com gatilho temporal **determinístico** por epoch:
  1. **ff-merge `work→main` pendente** (commit mais antigo não-merjado > 24h) — o crítico do v15
     apontou que é a rotina mais frequente/frágil, mesma classe dos selos.
  2. **selo SOAK velho de milestone ATIVO** (sem tag `vX.*`) — itera `.planning/soak/*.log`, pula os
     tagueados (fechados), lembra se heartbeat > 48h.
  3. **frescor de segurança** defasado (`check-security-freshness --tier` ∈ {warn, egregious}).
  Notifica via `osascript` nativo + stdout. **NUNCA** executa `--record`/`--gate` — o humano carimba.
- **`infra/launchd/com.ideiaos.closeout-reminder.plist`** — LaunchAgent 1×/dia 19h (fim de
  expediente), path absoluto, instruções de bootstrap/bootout no comentário. Instalação = passo
  MANUAL (consentimento explícito; espelha os outros plists).

## Princípio (learning aplicado)

`automate-the-reminder-not-the-integrity-stamp`: automatizar a CONCLUSÃO de um gate que exige atores
reais (selo SOAK em ≥2 máquinas, revisão @security-reviewer) faria a automação virar um ator
sintético e fraudaria a distinção que o gate protege. Por isso o script só LÊ e NOTIFICA.

## Verificação (exit-code)

| Gate | Resultado |
|------|-----------|
| `bash -n` sintaxe | ✅ |
| roda exit 0 (read-only) — "nenhum gate pendente" no estado limpo | ✅ |
| **anti-carimbo:** zero invocação de `--record`/`--gate` (grep filtrando comentário/MSGS; `--tier` só) | ✅ |
| plist XML válido (`plutil -lint`) | ✅ |
| gatilho determinístico (`date +%s` + `/3600`); "sessão" só no comentário anti-padrão (linha 18) | ✅ |
| **anti-teatro positivo:** `REMIND_FF_H=0` + 1 commit não-merjado → lembrete DISPAROU | ✅ |

## Decisões

- Filtro de milestone ativo por **tag** (`prefix vX` → existe tag `vX.*`? → fechado, pula). Hoje os 5
  ledgers (v11-v14) estão tagueados → nenhum lembrete SOAK falso; v15 não tem ledger ainda.
- Mensagens de lembrete **não** contêm a string `--record`/`--gate` literal (reformuladas) para o
  gate anti-carimbo ser inequívoco (a única menção fica no comentário-doutrina).
- Limiares override por env: `REMIND_FF_H` (24), `REMIND_SOAK_H` (48).

## Arquivos

- `scripts/remind-closeout-gates.sh` (novo), `infra/launchd/com.ideiaos.closeout-reminder.plist` (novo).
- `README.md` (tabela de scripts + árvore). PLAN/SUMMARY.
