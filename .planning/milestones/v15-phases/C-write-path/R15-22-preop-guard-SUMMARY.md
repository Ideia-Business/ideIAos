# R15-22 — Pre-op guard anti-autosync-race · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 1) · **Veredito:** pass (9/9 por exit-code).
**Movimento-âncora da Fase C** — a alavanca preventiva que o crítico do v15 identificou e nenhuma
proposta capturou. Protege as próprias cirurgias da Onda 3 contra o autosync.

## Problema (3 incidentes reais)

O `git-autosync` (daemon 900s) atropelou cirurgia git 3× em produção:
[[autosync-races-ai-git-surgery]] · [[stale-autosync-branch-off-main]] ·
[[claude-settings-deny-live-reload-autosync-capture]]. O `autosync-pause.sh` (manual) resolve, mas
depende de "lembrar de pausar" — exatamente o que falhou.

## O que foi feito

### 1. Sentinela AUTOMÁTICA de cirurgia (`source/lib/surgery-lock.sh` — NOVO)
- `surgery_begin [reason]` põe `~/.local/state/git-autosync.surgery` (`pid=`/`started=`/`reason=`/`by=`)
  e arma `trap surgery_end EXIT INT TERM` — **teardown garantido** (espelha `temp-privilege-window-teardown-grants`).
- `surgery_end` só remove se o `pid` casa (não apaga lock de cirurgia concorrente).
- `surgery_active` retorna 0 só se a cirurgia está **viva**: **stale-guard falha-segura** — ignora se
  o PID morreu (`kill -0`) OU o TTL (30 min) expirou. **Um script que crashar sem limpar NUNCA trava
  o autosync para sempre** (senão a cura vira a doença).

### 2. Consumo INLINE no daemon (`source/autosync/git-autosync.sh`)
- `_autosync_surgery_active` (cópia inline da lógica — daemon auto-contido, distribuído por cópia; o
  contrato produtor↔consumidor é o **formato do arquivo**, não o código).
- Guard estendido (após o pause-file manual): pula o repo se há cirurgia viva **ou** `.git/index.lock`
  recente (<120s = operação git atômica em curso). Loga `(R15-22)`.

### 3. Wiring nos 3 scripts de edição multi-arquivo (produtores)
`propagate-if-changed.sh`, `apply-to-all-projects.sh`, `install-global-patches.sh` sourceiam o helper
(fallback no-op se ausente) e chamam `surgery_begin` **só no modo de escrita real** (não em dry-run).

## Verificação (`tests/v15/test-preop-guard.sh` — 9/9, exit 0)

| Caso | Resultado |
|------|-----------|
| `surgery_begin` cria a sentinela; trap EXIT a remove (teardown) | ✅ |
| `surgery_active`=0 com sentinela fresca | ✅ |
| **`surgery_active`=1 com PID morto (stale → falha-segura)** | ✅ |
| **`surgery_active`=1 com TTL expirado (stale → falha-segura)** | ✅ |
| autosync PULA com sentinela viva (não toca o repo; HEAD inalterado) | ✅ |
| **autosync IGNORA sentinela stale (não trava — falha-segura)** | ✅ |
| autosync PULA com `.git/index.lock` recente | ✅ |
| `bash -n` nos 5 arquivos · source-headers · plugin-membership · readme-sync 140/140 | ✅ |

O caso negativo crítico (sentinela stale **não** trava o autosync) é o que distingue esta sentinela
do pause-file manual — e o que impede a prevenção de virar um novo modo de falha.

## Pendência de deploy (fechamento da fase)
O daemon DEPLOYADO (`~/.local/bin/git-autosync`) ainda é a cópia antiga — re-deploy via
`propagate-if-changed` no pós-merge; **verificar por grep** `_autosync_surgery_active` no binário
deployado (invariante autosync-race), não confiar em "status".

## Arquivos
- `source/lib/surgery-lock.sh` (novo) · `source/autosync/git-autosync.sh` (consumo inline + guard)
- `scripts/{propagate-if-changed,apply-to-all-projects,install-global-patches}.sh` (wiring produtor)
- `tests/v15/test-preop-guard.sh` (novo, 9 asserts)
