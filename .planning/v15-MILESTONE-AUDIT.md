# v15-MILESTONE-AUDIT.md — Auditoria pré-tag v15.0 (DX & Frota)

**Data:** 2026-06-26 · **Repo:** `/Users/gustavolopespaiva/dev/IdeiaOS` (branch `work`) · **Escopo:** Fase C (Onda 3) — R15-18..23 (R15-17 GATED).
**Veredito:** **SHIP** · **Síntese:** baseline GREEN reconfirmado por exit-code; 1 achado LOW confirmado **e já remediado** (ver "Remediação pós-auditoria"); zero BLOCKER/HIGH.
**Método:** workflow adversarial multi-agente (`wf_6d5aef84-56b`) — 1 baseline + 6 finders por dimensão de invariante-piso + refutação por achado (refute-by-default) + síntese. 15 agentes, ~1,44M tokens.

## Baseline por exit-code (reconfirmado nesta máquina)

| Gate | Comando | Resultado |
|------|---------|-----------|
| idea-doctor | `bash scripts/idea-doctor.sh` | **exit 0** — OK:80 WARN:1 FAIL:0 |
| Suíte v15 | `tests/v15/test-*.sh` | **6/6 exit 0** (autocura-ledger · deploy-hooks · idea-update · preop-guard · repin-local · writepath-allowlist) |
| Sintaxe | `bash -n` nos libs/scripts novos | OK |
| bash 3.2 | `grep "declare -A"\|"jq "` nos arquivos novos | NENHUM (conforme) |
| no-R15-17 | `grep push_cmd_ref\|enc-keys` em source/scripts/apps | **vazio** — nenhum código de produção shipado |

## Verificação por invariante-piso

| Invariante | Evidência | Status |
|------------|-----------|--------|
| **antifragile-gates** (exit-code, nunca Read) | Asserts da suíte por exit-code; `ledger.sh verify` retorna 3 em cadeia quebrada | ✅ honrado |
| **autosync-race** (lock falha-segura PID+TTL) | `surgery-lock.sh:66-77` + consumo inline `git-autosync.sh:22-33`; stale-guard por `kill -0` + TTL 1800s + sanitização numérica | ✅ honrado |
| **credential-isolation** | `read.js` ledger recebe só `verb`/`exit:<code>`/`ok\|fail` — `combined`/`scanned.stdout` NUNCA passados ao ledger; Zero-Leak varre stdout antes do `res.end`; `/vault`/`/projects` SELECT sem coluna `value` | ✅ honrado |
| **@devops exclusivo p/ push** | Enum de 6 verbos LOCAL-reversíveis (`read.js:86`); FOREVER-OUT (A8): zero rotate/deploy/revoke/push | ✅ honrado |
| **bash 3.2 / sem declare -A / sem jq** | grep vazio nos arquivos novos | ✅ honrado |
| **no-invention** | R15-23 é proof-gate sobre `pinned-keys.sh` existente (não toca produção); R15-21 blocos antigos `debt:`, não removidos | ✅ honrado |
| **write-path seguro** | `read.js` fail-closed em ordem: Origin+Host → token efêmero `timingSafeEqual` → Content-Type+cap 4KB → enum default-deny → arm → exec sem shell (`spawnSync` argv-array) → Zero-Leak; `reseal_security` neutralizado → `security_status` read-only; gate-negativo audita verbo inválido como `rejected` | ✅ honrado |

## Achados por dimensão e severidade

| # | Dimensão | Severidade | Achado | Arquivo:linha |
|---|----------|-----------|--------|---------------|
| 1 | autosync-failsafe (robustez) | **LOW** (remediado) | Sentinela com `started=`/`pid=` não-numérico (corrupção out-of-band) abortaria o subshell `sync_one` sob `set -uo pipefail` na expansão aritmética `$((now - started))` — "unbound variable". Falha-SEGURA (repo é pulado, nunca push espúrio); subshell isolado não trava a frota; único produtor (`surgery_begin`) grava sempre inteiro puro. | `source/autosync/git-autosync.sh:28` (gêmeo `source/lib/surgery-lock.sh:72`) |
| — | write-path (R15-18) | — | Nenhum achado. Default-deny, ledger wired, gate-negativo provado. | — |
| — | ledger hash-chain (R15-18) | — | Nenhum achado. tail-anchor + lock-por-dir + O_APPEND; `verify` cego-na-cauda já fechado. | — |
| — | redeploy/deploy-hooks (R15-19/21) | — | Nenhum achado. cp atômico `.tmp+mv`, chmod antes do mv; `deploy_hook_file` sempre retorna 0 (seguro sob `set -e`). | — |
| — | idea-update (R15-19) | — | Nenhum achado. surgery_begin no topo; build-contract exit 1 em etapa crítica. | — |
| — | autocura visível §16 (R15-20) | — | Nenhum achado. WARN nunca FAIL; epoch sanitizado; `tail -1` heartbeat. | — |
| — | re-pin local (R15-23) | — | Nenhum achado. Proof-gate sobre capacidade existente; fase-4 prova revogação forjada via ref não muta o pin. | — |

**Refutação adversarial:** 7 achados brutos → 6 refutados (real:false / INFO) → **1 confirmado** (AR-02). O achado AR-02 não foi refutável (reproduzido empiricamente em bash 3.2.57) mas foi **recalibrado de MEDIUM→LOW**: a direção da falha é segura (não-sincroniza, nunca push espúrio) e o gatilho é exclusivamente out-of-band (corrupção de arquivo de runtime gitignored em `$HOME/.local/state/`). Nenhum invariante-piso violado.

## Veredito

**SHIP.** Baseline GREEN por exit-code, zero BLOCKER/HIGH, todos os invariantes-piso honrados. O único achado (LOW de robustez) foi remediado na mesma sessão (abaixo) — o código vai para a tag **limpo**.

## Remediação pós-auditoria (mesma sessão, 2026-06-26)

Diferente da recomendação do synth de enfileirar como `debt:`, o LOW foi **corrigido** por ser cirúrgico, in-scope (o próprio guard R15-22) e por tornar o fail-safe de fato à prova de corrupção:

- **Fix:** sanitização numérica de `started` e `pid` antes da aritmética, em **ambos** os sites — `source/lib/surgery-lock.sh:surgery_active` e a cópia inline `source/autosync/git-autosync.sh:_autosync_surgery_active`. Idiom: `case "${started:-}" in *[!0-9]*|'') started= ;; esac` (simetria com `idea-doctor.sh:902`). Valor corrompido → tratado como ausente → cai no path de stale (falha-segura), nunca aborta o subshell.
- **Verificação por exit-code:**
  - `bash -n` nos 2 arquivos: OK.
  - Reprodução sob `set -uo pipefail`: sentinela corrompida **não aborta mais** (token `REACHED` emitido em todos os casos). Regimes: `corrompido+pid-morto → STALE` (autosync se recupera), `TTL-expirado → STALE`, `cirurgia-viva → ACTIVE` — todos corretos.
  - Daemon re-deployado canônico (`redeploy_autosync_daemon` → HEALED); **binário deployado verificado por grep** (guard presente, byte-a-byte == fonte); `idea-doctor §6` = "git-autosync na versão canônica (sem drift)".
  - Pós-fix: **tests/v15 6/6** · **idea-doctor exit 0 (OK:80 WARN:1 FAIL:0)**.

## Gates remanescentes (não-auditáveis aqui — são gates de PROCESSO, não defeitos)

- **SOAK 2ª-máquina + span ≥1d** — `check-soak.sh v15`. Estado em 2026-06-26: **2 máquinas distintas** (Mac-mini + MacBook-Air-2) ✅, **span 0d** (delta de epochs ~1,4h) ❌. Fecha com **um `--record` a partir de 2026-06-27 15:11** (24h após o heartbeat mais antigo; span é record-delta, não wall-clock — `soak-span-is-record-delta-not-wallclock`). Pré-condição do `git tag v15.0`.
- **R15-17 (push_cmd_ref cross-máquina + cerimônia N=2 das ENC-KEYS / B0-bis)** — **GATED por decisão do dono**. Confirmado por grep: nenhum código de produção shipado. A N=2 das enc-keys exige 2ª máquina física + 2 atores reais distintos — carimbá-la autonomamente fraudaria o gate de integridade (`automate-the-reminder-not-the-integrity-stamp`). Reserva deliberada de poder irreversível, fora do escopo desta tag (igual v10/v14 parciais).
