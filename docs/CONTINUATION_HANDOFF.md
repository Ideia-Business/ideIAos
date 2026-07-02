# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-07-02 (keep-alive Supabase — v16 F1 INALTERADO)

---

## ▶ ÚLTIMA SESSÃO (2026-07-02, Mac mini) — keep-alive dos bancos Supabase free-tier · ⚠️ NÃO muda o v16 F1 (próximo passo real = "RETOMAR AQUI" abaixo)

Operacional. O dono recebeu e-mail de pausa automática do projeto Supabase `IdeiaOS - Cockpit` (free-tier pausa após 7d ociosos, enquanto o Cockpit não roda diariamente). Criada rotina de keep-alive.

- **Rotina entregue (commit `b21dce6`):** `.github/workflows/supabase-keepalive.yml` (cron diário 12:17 UTC + `workflow_dispatch`; `curl` SELECT em cada projeto; alvos via secret `SUPABASE_KEEPALIVE_TARGETS`) + `supabase/keepalive.sql` (tabela `public.keepalive`, SELECT `anon`, idempotente) + runbook `docs/guides/supabase-keepalive.md` (+ índice). Validado por exit-code: YAML ruby-parse OK · `bash -n` do bloco `run` OK · dry-run do loop = 2/2 alvos + rejeita linha malformada.
- **Escopo:** 2 bancos IdeiaOS da org `tflylcjdmjctdzhwzbcm` — `stepup` (`xdikjgpkiqzgebcjgqmu`, PAUSADO) + `view` (`ysttvskswqsvtdftjhfn`, criado 30/06). NFIdeia (`pdljyfyyxufkqejncccv`) é produto/outra org — fora de escopo.
- **⚠️ 3 AÇÕES DO DONO p/ ativar** (nenhuma manuseável pelo agente — `credential-isolation`): **(1)** despausar `xdikjgpkiqzgebcjgqmu` no dashboard (*Restore*); **(2)** aplicar `supabase/keepalive.sql` no SQL Editor dos 2 projetos; **(3)** criar o secret `SUPABASE_KEEPALIVE_TARGETS` (`LABEL|URL|ANON_KEY` por linha; anon key do dashboard → Settings → API, **nunca** `service_role`). **Verificar:** Actions → supabase-keepalive → *Run workflow* → run verde (`✅ stepup/view — HTTP 200`). Passo a passo: `docs/guides/supabase-keepalive.md`.

---

## ▶ SESSÃO ANTERIOR (2026-06-30, MacBook-Air-2) — manutenção transversal do OS · ⚠️ NÃO muda o v16 F1 (próximo passo real = seção "RETOMAR AQUI" abaixo)

Sessão paralela ao v16 — fortaleceu o OS sem tocar o motor RLS do P3. Tudo em `work`, mergeado p/ `main`.

- **Deno runtime** instalado (`~/.local/bin`, v2.9.0) + `scripts/install-deno.sh` idempotente — mata o aviso recorrente "Deno não instalado" (era fallback de `deno test` em edge functions). Endurecido por review adversarial (8 achados). Memória [[reference-deno-install-local-bin]]. ✅ **WIRING DURÁVEL p/ TODA a frota (fix desta sessão 2026-06-30):** o instalador NÃO estava órfão — já rodava no **bootstrap `setup-dev-machine.sh §3.5`** (one-time, máquina nova do zero). O gap real: o caminho de **refresh recorrente** (`setup.sh --global-only`, rodado pelo `sync-all.sh` e pelo branch global da propagação `propagate-if-changed.sh:226`) NÃO instalava o Deno → **máquinas já existentes** (bootstrap rodado antes do installer existir, ou que simplesmente não re-rodam o bootstrap) seguiam sem o binário e emitindo o aviso. Fix: **step 6.3 na fase global do `setup.sh`** chama o mesmo installer → o refresh recorrente passa a cobrir a frota inteira (nova via bootstrap §3.5, existente via propagação/sync-all). Fail-soft (runtime opcional; falha de rede não aborta o setup). Provado por exit-code: `bash -n setup.sh`=0, `install-deno.sh --quiet`=0 (no-op idempotente), lógica do step 6.3=0. **Furo de propagação fechado (mesma sessão):** `setup.sh` estava só em `PROJECT_PATHS` → mudança na fase global dele acionava só `apply-to-all-projects` → `setup.sh --project-only`, que **pula** a fase global (step 6.3); a fase global vive NO arquivo, não em `source/`, então nenhum global-path a representava. Fix: `setup.sh` adicionado também a `GLOBAL_PATHS` em `propagate-if-changed.sh` → a propagação do Deno à frota existente agora é **determinística** (antes só "pegava carona" se outro global-path mudasse no mesmo range). `install-global-patches.sh` NÃO tocado (evitou renumerar 15 patches; a propagação já passa pelo `--global-only` antes dele).
- **Doc de anatomia** (máquina×repo×projeto) no README + **3 templates `source/templates/ideiaos/*.tmpl`** (os gerados `docs/ideiaos/*` e `IDEIAOS.md` são GITIGNORED → editar os TEMPLATES, não os gerados — [[learning-generated-docs-gitignored-edit-template]]).
- **`docs/AI-OS-GAP-ANALYSIS.md`** — scorecard 9 dimensões (média **3,67/5**; gargalo = coesão GSD↔AIOX **2/5**) + roadmap faseado até a **Deia-kernel** ([[project-deia-kernel-vision]]: IdeiaOS é o harness central; AIOX/GSD = executores plugáveis). 2 eixos futuros: doc-lifecycle greenfield→brownfield; doc viva por projeto.
- **Quick wins:** (QW2) `check-manifest-drift.sh` + doctor §18 — achou `ecc/lovable/supabase` fora do manifesto, órfão `instinct-recover` catalogado; (QW3) Security-Freshness **LIGADO na frota** (`SECFRESH_GATE_ENABLED:-1` + re-selo PASS) + **bug do `policy.sh`** corrigido (sourced fora de ordem → override era inerte); (QW1) allowlist least-privilege no spawn de `/instinct-analyze` ([[learning-headless-spawn-needs-allowedtools]]) + doctor §19.

✅ **PENDÊNCIA QW1 RESOLVIDA 2026-06-30 (sessão interativa real).** A verificação revelou que o `--allowedTools` era **necessário mas não suficiente** — havia uma **segunda barreira, esta fatal**: a **Regra Inviolável #1 (R4-04)** da skill `instinct-analyze` mandava *encerrar imediatamente se `IDEIAOS_INSTINCT_SPAWN` setado*; mas o hook SEMPRE seta essa flag ao invocar a skill → ela abortava na **linha 1**, todo spawn, sempre (logs 0-byte). A flag tinha 2 papéis conflitantes: conter os hooks observadores (correto — `observe-*.sh` fazem early-exit por ela) **e** abortar a própria skill-alvo (errado).
- **Fix:** reescrita a Regra #1 nas **3 cópias** (`source/skills/`, `plugins/ideiaos-core/skills/`, `~/.claude/skills/` — hash idêntico) — a skill não aborta mais pela flag; anti-runaway é responsabilidade só dos hooks.
- **Provado por exit-code:** rodando o comando EXATO do hook (com a flag) → `before=0 → after=6` instincts, **6/6 íntegros** (`test -s`), privacidade limpa (0 secrets/paths), **0 runaway** (1 binário claude vivo, 0 re-spawns, sentinela escrito, breadcrumb órfão limpo). `idea-doctor §19` verde (**83 OK/1 WARN/0 FAIL**).
- **Propagação cross-máquina confirmada:** deploy 5.21b do `setup.sh` é content-aware (`diff -rq`, re-espelha dir inteiro) e a skill está no manifesto (`installStrategy: always`, `targets:[claude]`) → `git pull` + `setup --global-only` propaga o fix; não é version-gated.
- **Validação adversarial** `wf_153c3893` (3 lentes — completude / anti-runaway / regressão-recover — **todas SEGURO**; veredito `COMPLETO_E_SEGURO`). Único achado não-INFO (LOW): falta de `flock` no breadcrumb `.spawn-<proj>.state` compartilhado entre `observe-session-end.sh` e `instinct-recover.sh` → janela teórica estreitíssima de *lost-update* (NÃO corrupção; pior caso = um `evidence_count` perdido). **Não é regressão deste fix.**
- 🔧 **Débito opcional (LOW, não-bloqueante):** envolver a escrita de `.spawn-<proj>.state` em `flock` nos dois hooks. Só vale se a recorrência de recovery aumentar. Memória atualizada: [[learning-headless-spawn-needs-allowedtools]] (causa dupla + anti-padrão generalizado "flag-guard de spawn mata o alvo").

---

## ▶ FECHAMENTO (manutenção, Mac mini, 2026-06-29 noite) — runner v15 órfão REMOVIDO + sync verificado · o "RETOMAR AQUI" real é a seção v16 logo abaixo

**Sessão operacional curta no Mac mini (NÃO muda o milestone nem o próximo passo).** O dono apontou um agendamento local e pediu p/ cancelar se obsoleto.

- **✅ Pendência fechada — LaunchAgent `com.ideiaos.soak-v15-oneshot` órfão REMOVIDO do Mac mini** (plist + `~/.local/bin/ideiaos-soak-v15-oneshot.sh` + log). Era o auto-tag zero-touch do v15.0; como `v15.0` já está tagueada/publicada (`7dbc31a` no origin — confirmado local + remoto), o runner era redundante (se disparasse, veria a tag e só se auto-removeria). `launchctl` confirmou que **não estava carregado**; `bootout` idempotente + `rm`. Resolve a "⚠️ PENDÊNCIA" da seção v15.0 SHIPPED abaixo.
- **✅ Sync verificado:** `work` local == `origin/work` (`8b7e88a`); `main` local alinhada a `origin/main` (`79d0f62`, FF ref-only); working tree limpo; tag `v15.0` no origin. Os 4 daemons IdeiaOS (`envsync`, `cockpit`, `gitautosync`, `refresh-ai-security`) ativos — o `gitautosync` se autoprovou vivo (commitou o handoff `8b7e88a` durante a própria checagem).
- **Intacto:** nenhum outro LaunchAgent tocado.

**🚦 Próximo passo (INALTERADO):** a **DECISÃO v16 (frente A = R16-03 FG-PAT · A' = runbook p/ 3 máquinas · B = motor RLS → F1)** — seção logo abaixo.

---

## ▶ RETOMAR AQUI — v16 F1: schema RLS do P3 APLICADO + GATE PASS contra backend real (teste negativo exit 0) → próximo = credencial de ingestão + re-apontar ingest (2026-06-30)

**Sequência aprovada pelo dono:** `(feito) runbook A' documentado → B (motor → schema RLS → telas) → A executada numa pausa da B`.
A e B são **independentes**; o dono optou por construir B primeiro, aceitando conscientemente que o token org-wide
fica ativo durante a B (teto do dano limitado: a autoridade está no pin O2 local, não no GitHub).

### ✅ Frente A' DONE — runbook de migração FG-PAT documentado
- **[`docs/guides/r16-03-fg-pat-migration.md`](docs/guides/r16-03-fg-pat-migration.md)** (indexado em `docs/guides/README.md`).
  Runbook por-máquina reproduzível (token org-wide → FG-PAT escopado), produzido pelo workflow `wf_631edb5c-e96`
  com **verificação adversarial** (2 HIGH + 2 MED + 2 LOW achados e **todos incorporados**): caminho osxkeychain
  direto (não `gh auth setup-git`), teste negativo endurecido contra falso-verde (rede/404/escrita), ator emissor
  por-máquina resolvido (o **dono** emite na sessão local de cada máquina, inclusive SSH no ThinkPad do Lucas —
  token nunca por mensageria), `rm` efêmero eliminado. **Execução = do dono**, quando quiser (numa pausa da B).
- 📍 Mapa de auth desta máquina (MacBook-Air-2), não re-investigar: conta `gh` = `DevIdeiaBusiness` (service account),
  token `gho_***` OAuth **org-wide** (`read:org,repo,workflow`), helper `osxkeychain`, autosync delega ao keychain,
  **5 repos** `Ideia-Business` (`cfoai-grupori`,`IdeiaOS`,`lapidai`,`nfideia`,`ideiapartner`) = escopo do FG-PAT.

### 🟢 Frente B — motor DECIDIDO 2026-06-30 (ADR [`v16-r16-02-motor-plano-view.md`](docs/decisions/v16-r16-02-motor-plano-view.md))
- **Decisão:** **Supabase Postgres dedicado**; **P3 (Plano de View) = projeto NOVO** na org IdeiaOS (free, 2º projeto),
  **fisicamente distinto** do step-up. Análise (4 lentes convergentes): [`.planning/milestones/v16-motor-decision-analysis.md`](.planning/milestones/v16-motor-decision-analysis.md)
  (`wf_631edb5c-e96`). Descartadas: SQLite+app = **teatro de RLS**; Postgres self-hosted = mata o propósito; Neon = dominada.
- **🚨 Achado-chave (RESOLVIDO):** o ref `xdikjgpkiqzgebcjgqmu` que o `v16-REQUIREMENTS` citava como motor de view é, na
  verdade, o projeto **step-up/P4** (memória `stepup-backend-provisioned` + STATE + painel confirmam) — reuso violaria
  S-04/R-WP12. Painel: org IdeiaOS **Free, 1 projeto** (Cockpit/step-up) + **folga p/ o 2º** → P3 novo é **grátis**. Ref corrigido no requirements.
- **Decisões do dono (tomadas):** free tier (cold-start aceito) · Auth-leitura por **contas pessoais** (≠ service account) · hosting da UI **na fase de telas**.
- **Condições inegociáveis (gate de F1):** SERVICE_ROLE nunca no browser · schema sem `value`/sem INSERT-da-UI ·
  **teste negativo de RLS por-campo por exit-code contra o backend REAL** (necessário=RLS-enforced; suficiente=teste) · P3≠P4.

**🚦 Próximo passo concreto:**
1. ✅ **(dono) P3 CRIADO 2026-06-30** — ref **`ysttvskswqsvtdftjhfn`** (org IdeiaOS, ≠ `xdikjgpkiqzgebcjgqmu`/step-up → P3≠P4). Chaves no `.env` local do dono, fora do contexto.
2. ✅ **(agente) `schema.sql` DO P3 ESCRITO + VERIFICADO + ENDURECIDO 2026-06-30** — [`source/console/p3/schema.sql`](source/console/p3/schema.sql).
   - **Arquitetura 3-schemas (defesa estrutural):** `data.*` = 12 tabelas-base **não-expostas ao PostgREST**, `ENABLE`+`FORCE` RLS deny-all (8 read-model portadas + `app_user`/`user_project_scope`/`station_enrollment` RBAC + `scope_audit` append-only) · `app.*` = 5 funções de autz `SECURITY DEFINER` com `search_path=''` (`role_of`/`is_member`/`is_admin`/`can_see_project`/`can_see_machine`) · `public.*` = 12 views de apresentação = **único ponto de leitura da UI** (`authenticated`), onde mora o mascaramento por-campo.
   - **Verificação adversarial = 2 agentes** (`rls-reviewer` veredito BLOQUEAR + `security-reviewer` veredito WARN). **1 CRITICAL + 4 HIGH + vários MED incorporados:** o bypass-raiz `can_see_machine` (snapshot/mcp/eventos machine-level cru furava o escopo-por-projeto pois o payload de máquina ⊃ projetos fora do escopo) → fechado **admin-only**; `api_key_v` critical fora do escopo **OMITIDA** + postura (`present`/`committed`/cadência) mascarada; `machine_v` restrita a `can_see_machine` + fingerprint só admin; nova trilha `scope_audit`; `revoke usage from anon` + `alter default privileges revoke`. **Corretos e intactos:** zero `value`, `search_path=''` sem hijack, FORCE RLS, `station_enrollment` sem-autoridade, fail-closed sob `auth.uid() IS NULL`.
   - **D1 DECIDIDO (dono, 2026-06-30):** D1-A "catálogo + máscara" (dev vê existência de projetos + chaves non-critical fora do escopo com postura mascarada; critical omitida) — leitura literal do contrato L438.
   - **Invariantes determinísticos verdes** (exit-code): zero `value`, zero `CREATE POLICY`, 12/12 `ENABLE`+`FORCE` RLS, 12 views, begin/commit. (`psql` ausente nesta máquina → parse real fica nos gates G1-G7.)
3. ✅ **(agente+dono) GATE RLS PASS 2026-06-30** — schema aplicado no P3 REAL pelo dono (SQL Editor) + **gate por exit-code verde contra `ysttvskswqsvtdftjhfn`** (`node source/console/p3/gate-rls.mjs --test` → exit 0). Artefatos versionados: `gate-rls.mjs` (testador fetch-nativo) + `gate-seed.sql` (cenário de teste) + `gate-teardown.sql`. Provado: **G1** teste NEGATIVO (dev fora do escopo: 0 nome critical, 0 linha critical, postura/cadência mascaradas; mas VÊ a critical do próprio escopo) · **G2** admin visão completa · **G3** `machine_snapshot_v`/`mcp_connection_v` admin-only (o bypass-raiz fechado, confirmado live) · **G5** `data.*` não acessível via REST · **G7** anon 0 rows · **G4** `auth.uid()` sob `search_path=''` (implícito — G2 só passa se resolver). **Pendente não-bloqueante: G6** (viewowner dedicado — hoje é `postgres`/superuser via SQL Editor; o controle vive nos `where app.*()`, provados por G1-G3; hardening S-06 fica p/ depois). **Cenário de teste (zzgate-/@gate.invalid) ainda no P3** — `gate-teardown.sql` + `--delete-users` limpam quando for popular dados reais.
   - **🚦 PRÓXIMO (gated no dono):** **credencial de ingestão** (D2: edge function + SERVICE_ROLE server-side RECOMENDADO) → **re-apontar ingest** (SQLite-local → UPSERT por `machine_id` no P3) → **admissão pin O2** → **Auth-leitura** (contas pessoais GitHub OAuth) → **telas/read-fan-out** → consolidar `/spec` (merge+archive R16-02) + re-selar security-freshness.
   - **Decisões abertas (refinar via `/spec`, não bloqueiam):** D2 (transporte de ingestão) · D3 (gestão RBAC via edge SERVICE_ROLE) · D5 (mascaramento extra em `project_v`) · D6 (snapshot/eventos por-projeto p/ reabrir a dev) · G6/S-06 (viewowner dedicado).
   - **Como re-rodar o gate** (qualquer máquina): `set -a; . ~/.ideiaos/p3.env; set +a` → `node source/console/p3/gate-rls.mjs --create-users` → colar `gate-seed.sql` no SQL Editor → `node source/console/p3/gate-rls.mjs --test`. `~/.ideiaos/p3.env` tem P3_URL/P3_ANON_KEY(publishable)/P3_SERVICE_ROLE(secret), fora do repo/contexto.

A Frente A (executar o runbook FG-PAT) entra em qualquer pausa da B. v16 segue **ATIVO**.

---

## ▶ RETOMAR (histórico) — v16 ATIVO: ratificação DONE + R16-03 DECIDIDO (Opção C); construção F1 gated em runbook do dono (2026-06-29)

**Sessão "vamos ao milestone v16, execute com perfeição".** O v16 (Plataforma de Time) é gated; executar
com perfeição = **ratificar o contrato (pure-design) sem super-construir**. Dois gates destravaram: v15
SHIPPED ✅ + **2º dev real confirmado** (Lucas = `lucas-abreu56`, não-admin). Autosync NÃO foi pausado
(só edição de specs/docs, sem cirurgia git multi-repo até o closeout).

- **✅ Ratificação do contrato `specs/cockpit/spec.md` (20 → 24 reqs)** — 4 SHALL ADICIONADOS via `/spec`
  (delta `specs/_archive/2026-06-29-v16-ratificacao-split-plane/`): (1) Plano de View read-only,
  divergência=ALERTA (R-WP12 pt1); (2) P3 estruturalmente incapaz de autoridade — sem coluna `value`,
  não assina/pina, exit 9 ALERT, P3≠P4 (R-WP12 pt2); (3) RLS deny-all + mascaramento por-campo por papel
  (R16-02); (4) Admissão de estação por pin O2 + escopo default-deny (R16-02). **4 gates passaram:**
  spec-validate exit 0 · **verificação adversarial 4/4 MANTER, 0 invenção** (workflows `wf_1d7ecdf6`
  understand + `wf_77cf95b6` refute) · spec-merge OK · spec-analyze 0 defeitos HARD.
- **🔵 Parqueado (NÃO entrou no contrato):** R16-06 Audit-Log API (inviável: org free→404, só Enterprise);
  R16-04/R16-05 (F3/F4 gated por colisão-medida); step-up-loopback (rebaixado a defesa-em-profundidade).
- **🟢 R16-03 (transporte GitHub) — DECIDIDO 2026-06-29** (ADR `docs/decisions/v16-r16-03-github-identity-transport.md`).
  Probe: org `Ideia-Business` é FREE (≠ conta pessoal `desenvolvimento@`=Pro, que NÃO habilita recursos de
  org). Dono confirmou: todos os devs já têm contas próprias autorizadas (Gustavo=`gustavolpaiva` admin).
  **Decisão = Opção C (híbrido faseado), regime FREE advisory, 2FA adiado:** service account com FG-PAT
  escopado por-máquina p/ automação (aposentar o token clássico org-wide); contas pessoais p/ ação humana.
  Trade-off assumido: governança advisory (FG-PAT por-convenção, branch protection só público, sem
  audit-log) — não compromete a autoridade (sempre pin O2 local). Runbook de execução no ADR.
- **🎉 v16 ATIVO:** os 4 gates de ativação resolvidos (v15 shippado · 2º dev real · R16-03 decidido · contrato ratificado).

**🚦 Próximo:** **(dono)** executar o runbook do ADR R16-03 (emitir FG-PATs + aposentar token org-wide — não
manuseável pelo agente, credential-isolation). **(técnico)** escolher motor multi-usuário (Supabase
`xdikjgpkiqzgebcjgqmu`) → RLS/admissão saem do contrato p/ código (teste negativo = gate) → F1 read-fan-out.
R16-04/05 seguem parqueados por necessidade comprovada.

---

## ▶ RETOMAR (histórico) — 🏷️ v15.0 SHIPPED (tag `d7cf626`, 2026-06-29) — tagueada manualmente da MacBook-Air-2

**O auto-tag do Mac-mini NÃO disparou** (a máquina ficou desligada desde 27/06; SOAK seguia 0d). Dono
autorizou destravar daqui. Procedimento `TAG-READY-v15.md` executado da MacBook-Air-2:

- **✅ SOAK fechado:** `check-soak.sh v15 --record` (idea-doctor PASS + regressão PASS) → heartbeat
  MacBook-Air-2 @ 2026-06-29T14:07 (commit ledger `d7cf626`). Gate: **2 máquinas · span 2d** · exit 0.
  Gate irmão `check-security-freshness --gate` = tier=ok (advisory).
- **✅ ff-merge `work→main`** (`80ce4fc..d7cf626`) + **tag anotada `v15.0`** (@devops) **pushada** →
  `work == origin/main == origin/work == d7cf626`. v15.0 inclui Onda A/B/C (R15-01..23 exceto R15-17
  GATED) + DX (Cockpit launcher/Atalaia/auto-bootstrap) + MEMORY.md cap. **R15-17 = escopo parcial** (igual v10/v14).

**✅ RESOLVIDO 2026-06-29 (noite, Mac mini) — runner auto-tag órfão REMOVIDO** (ver "FECHAMENTO" no topo do handoff). _Contexto histórico:_ o LaunchAgent `com.ideiaos.soak-v15-oneshot`
seguia armado no Mac-mini. No próximo boot gravaria heartbeat + tentaria `git tag -a v15.0` →
**falha (tag já existe)** e (sendo defensivo) abortaria+notificaria → ruído recorrente.
**AÇÃO executada quando o Mac-mini ligou:** removido o LaunchAgent + runner:
`launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ideiaos.soak-v15-oneshot.plist 2>/dev/null; rm -f ~/Library/LaunchAgents/com.ideiaos.soak-v15-oneshot.plist ~/.local/bin/ideiaos-soak-v15-oneshot.sh`

**🚦 Próximo:** **v16 — Plataforma de Time** (`.planning/milestones/v16-REQUIREMENTS.md`), gated por blockers
(conta GitHub compartilhada) + 2º dev real. Housekeeping: branch stale remota `sec/lovable-mcp-deny` em cfoai/nfideia.

---

## ▶ RETOMAR (histórico) — v15 ARMADO PARA AUTO-TAG zero-touch no boot do Mac-mini (dom/seg); auditado SHIP + nfideia re-contido (2026-06-26)

**Sessão "conclua 100% do cockpit" pós-/compact.** Autosync pausado na cirurgia; daemon re-deployado (HEALED) e religado ao fim; `work→main` ff-merge feito.

> **🎯 Auditoria adversarial multi-agente pré-tag (`wf_6d5aef84-56b`) = veredito SHIP.** Baseline GREEN por exit-code (idea-doctor exit 0 · OK:80/WARN:1/FAIL:0 · tests/v15 6/6). 7 achados brutos → 6 refutados → 1 LOW confirmado (AR-02) **e remediado na mesma sessão**. Doc: `.planning/v15-MILESTONE-AUDIT.md`.

- **✅ Fix AR-02 (`17ec199`)** — o stale-guard do surgery-lock (`surgery_active` + cópia inline `_autosync_surgery_active`) abortava o subshell sob `set -uo pipefail` se a sentinela tivesse `started=`/`pid=` não-numérico (corrupção out-of-band). Sanitização numérica `case "${x:-}" in *[!0-9]*|'') x= ;;` nos 2 sites → valor corrompido cai no path de stale (falha-segura). Reproduzido por exit-code (corrompido+pid-morto → STALE; não-aborta); daemon re-deployado canônico (HEALED, binário verificado por grep == fonte); tests/v15 6/6; idea-doctor §6 sem drift.
- **✅ SOAK 2ª máquina FECHADA** — ledger tem **Mac-mini-de-Gustavo + MacBook-Air-2** (2 distintas). **Span 0d** (delta ~1,4h) é o único pendente.
- **✅ MEMORY.md durabilidade (`1de7312`)** — causa-raiz do "compactação não colou": o índice é GERADO do `description:` de cada fato (memory-import §7 + memory-export build_shared_index); editar o índice à mão é descartado na regen. Inchava com description-parágrafo (v10/v14 ~1500c). **Fix estrutural:** ambos os geradores **capam o label da linha em 120c** (description completa fica no fato → recall íntegro). 22,9KB→15,9KB, 74/74 entradas, imune a verbosidade futura. tests/v5-memory 4/4. **Entra na v15.0** via auto-tag (DX, testado/gateado). [[learning-soak-span-is-record-delta-not-wallclock]]-style: artefato gerado se corrige na FONTE/gerador, nunca no artefato.
- **✅ Cockpit DX a/b/c (`2d26027`, 2026-06-27)** — (a) `scripts/cockpit-up.sh` launcher único (read.js + Vite + browser num comando, trap teardown); (b) **Atalaia**: `GET /alerts` (`read.js handleAlerts`) catálogo doc 77 A1–A11 — A5/A7/A9/A10/A11 computados do read-model, A1/A2/A6/A8 `no-data` honesto — + card no `Overview.tsx` + gate `scripts/test-cockpit-alerts.sh` (seed isolado via `COCKPIT_DB` + assert 11 ids) + `COCKPIT_DB` override; (c) `ideiaos-update.sh` step 6 = bootstrap idempotente do daemon `com.ideiaos.cockpit` com node REAL (nvm/homebrew, corrige `/usr/local/bin/node` hardcoded) → a **MacBook ativa o agentd sozinha** no próximo `git pull && bash scripts/ideiaos-update.sh`. Verif por exit-code: node --check + bash -n + test 11 ids + SPA build (tsc+vite, dist OK) + README sync + idea-doctor 0 FAIL + §15 verde. **Entra na v15.0** via auto-tag (DX & Frota). **Cockpit:** completáveis fechados (launcher · alertas · auto-ativação da frota); **resta** write-path cross-máquina (R15-17 GATED, 2º host) + multi-user/time (v15/v16). Como abrir: `bash scripts/cockpit-up.sh`.

**🤖 v15.0 ARMADO PARA AUTO-TAG (zero-touch — autorizado pelo dono, noite de 2026-06-26):**
- LaunchAgent `com.ideiaos.soak-v15-oneshot` (Mac-mini; `RunAtLoad` + 15:17 + trava de horário-alvo
  `TARGET=1782583866`). O Mac-mini estará DESLIGADO até dom/seg de manhã; **no boot** o runner
  `~/.local/bin/ideiaos-soak-v15-oneshot.sh`: grava o heartbeat (fecha o span ≥1d) → idea-doctor 0 FAIL →
  ff-merge work→main → `git tag -a v15.0` + push → notifica → self-remove. **DEFENSIVO:** aborta+notifica
  se algo não estiver limpo (span não fecha, idea-doctor FAIL, work divergiu) — nunca tagueia estado ruim.
  **R15-17 GATED** = exclusão de escopo (não bloqueia), igual v10/v14.
- Atalho opcional: se ligar o MacBook antes, rodar o bundle (re-contém nfideia local + `check-soak v15 --record`)
  fecha o span mais cedo; o auto-tag ainda dispara no boot do Mac-mini (o runner vê o span fechado e tagueia).

**🩹 Regressão tratada (2026-06-26 noite):** nfideia perdeu a contenção Lovable (deny=0 em main → idea-doctor
FAIL, bloqueava o re-record). Re-contido DURÁVEL via `settings.local.json` (18 mutantes, local/gitignored —
sobrevive a deploy Lovable, ≠ `settings.json` que é zerado). idea-doctor 0 FAIL. **Branch stale
`sec/lovable-mcp-deny` do nfideia DELETADA** (cfoai já estava limpa). Auditoria pré-tag (`wf_6d5aef84-56b`) = SHIP.

---

## ▶ RETOMAR (manutenção 2026-06-26) — Cockpit daemon ATIVADO na MacBook-Air-2 + fix cwd no collect.js

**Sessão operacional (NÃO muda o milestone v15 — o próximo-passo canônico é o bloco SHIP acima).**
Disparada por `rodar idea-doctor` → resolver os WARN da §15 Cockpit → `ideiaos-update.sh` → fechamento.

- **✅ Cockpit daemon ativado nesta máquina (582572114c20 = MacBook-Air-2):** LaunchAgent
  `com.ideiaos.cockpit` instalado e ativo (3+ runs, todos exit 0). Snapshot da máquina gerado +
  read-model reconstruído (3 máquinas). **Gotcha nvm:** o plist versionado hardcoda
  `/usr/local/bin/node` (inexistente em máquina nvm) → criado symlink `~/.local/bin/node` + cópia
  INSTALADA do plist apontando p/ ele (template fica pristine). [[project-cockpit-daemon-nvm-install-and-cwd]].
- **✅ Bug de cwd no `collect.js` (commit `9d9e129`):** `soakDir` (`process.cwd()`) e a chamada
  `check-security-freshness.sh` (path relativo) ainda dependiam de cwd — quebravam sob launchd
  (`safeExec warn` + `security_freshness` ausente do snapshot). R15-12 só ancorara o `versions.lock`.
  Fix: constante `ROOT` (`__dirname`-based) nos 3 pontos. Provado de `cwd=/tmp` + kickstart real.
  [[learning-daemon-cwd-fix-needs-whole-file-sweep]].
- **✅ `ideiaos-update.sh` rodado:** tudo idempotente/canônico; idea-doctor **OK:80 · WARN:1 · FAIL:0**
  (o único WARN = 3 marcadores `debt:` intencionais — visibilidade, não defeito).
- **📚 Learning extraído + promovido** (global + vault): daemon-cwd-fix-needs-whole-file-sweep.
- **⚠️ Housekeeping descoberto (não-bloqueante):** o `MEMORY.md` é **regenerado** pelo `memory-import`
  a partir das `description:` dos fatos (compactar à mão NÃO persiste). Correção durável = encurtar
  as descriptions longas OU truncar `label` no gerador (`source/hooks/memory-import.sh:~271`).
  [[project-memory-index-regenerated-from-fact-descriptions]].

**Carry-forward:** nenhum bloqueio novo. Próximo passo canônico = SOAK span ≥1d (bloco SHIP acima) p/ tag v15.

---

## ▶ RETOMAR (histórico) — v15 Onda 3 (Fase C) COMPLETA (6/6 não-gated); falta SOAK 2ª máquina + R15-17 GATED p/ tag v15 (2026-06-26)

**Sessão "siga" pós-/compact — Onda 3 inteira (R15-18..23, exceto R15-17 GATED) construída e provada por exit-code.**
Autosync pausado nas cirurgias, daemon re-deployado (HEALED) e **religado ao fim**; `work→main` ff-merge feito.

> **🎯 Fase C (Onda 3) = 6/6 não-gated DONE · 60/60 asserts · suíte tests/v15 6/6 · idea-doctor 0 FAIL.**
> Planos/SUMMARYs em `.planning/milestones/v15-phases/C-write-path/` (INDEX.md). Método-espelho GSD.

- **✅ R15-22 (98dc3fa)** pre-op guard anti-autosync-race: sentinela automática `source/lib/surgery-lock.sh`
  (posta pelos 3 scripts de edição multi-arquivo) + consumo inline no daemon, **stale-guard falha-segura**
  (PID morto/TTL → nunca trava o autosync). 9/9.
- **✅ R15-20 (291fd9e)** auto-cura visível: ledger de propagação local-only (append atômico, sem hash-chain)
  + heartbeat no `idea-doctor §16` (WARN se última propagação FALHOU). 6/6.
- **✅ R15-19 (8e608e5)** `idea update`: comando único canônico (`scripts/idea-update.sh`) +
  `source/lib/redeploy-daemon.sh` (cp-canônico que cura drift) usado por idea-update/propagate/ideiaos-update
  step 2e — 1 lógica. Patchers in-place 2/2b/2c/2d **deprecados (debt:)**. Prova de CURA num daemon legado. 13/13.
- **✅ R15-21 (e34f202)** gerador de hooks data-driven: `source/lib/deploy-hooks.sh` (lista única `IDEIAOS_HOOKS`
  + loop no setup.sh 5.4b); blocos antigos marcados debt: (remoção incremental). Gate de **igualdade de SET**. 8/8.
- **✅ R15-18 (485ad7d)** allowlist write-path LOCAL: `reseal_security` (carimbava selo @security-reviewer por
  clique = **fraude de gate**) → `security_status` read-only; ledger hash-chained **wired** ao /command
  (aceitas+rejeitadas). Gate-negativo provado. SPA alinhada + rebuild. 11/11.
- **✅ R15-23 (fb8d44d)** proof-gate teardown re-pin local O2: opera por exit-code o invariante de revogação
  own-fleet (re-pin rotaciona; revoke-local faz teardown; ref **fail-closed** — pin preservado após revogação
  forjada). Re-pin LOCAL, não a cerimônia N=2. 13/13.
- **🔒 R15-17 GATED** — `push_cmd_ref` + executor cross-máquina + **cerimônia N=2 das ENC-KEYS** exige 2ª máquina
  física + decisão do dono. Não-executável autonomamente (carimbar = fraude do gate de integridade).

**⚠️ Atividade paralela observada (não-nociva):** durante a sessão apareceu na `work` o commit **d4102a7**
("fix(lovable-mcp): query_database opt-in, §7e threshold 19→18") de OUTRA sessão/ator (autosync pausado, então
não foi ele; minha identidade git). Cadeia LINEAR, `idea-doctor.sh` final tem AMBOS (o fix d4102a7 + meu §16 R15-20),
sem regressão (regiões diferentes do arquivo). Incluído no ff-merge. + 1 auto-commit `c9c871d` do autosync (só
`.planning/STATE.md`) na janela de 8s ANTES da minha pausa.

**🚦 Falta para tagear v15:**
1. **R15-17** (GATED — cerimônia enc-keys N=2 + 2ª máquina física, decisão do dono).
2. **SOAK** — `bash scripts/check-soak.sh v15 --record` em ≥2 máquinas + span ≥1d (DoD `idea_doctor=PASS` ✅ já ok).
3. Housekeeping: MEMORY.md perto do limite; branch stale remota `sec/lovable-mcp-deny` em cfoai/nfideia.

---

## ▶ RETOMAR (histórico) — "faça tudo até 100%": Fase 1 + Fase 3 DONE, **idea_doctor=PASS (DoD ok)**; só falta Onda 3 (pós-/compact) (2026-06-26)

**Sessão "faça tudo, faseado, toque até 100%".** Autosync religado ao fim; `work→main` ff-merge feito.

> **🎯 DoD do SOAK SATISFEITO:** `idea-doctor` = **ok 78 · warn 3 · fail 0 · exit 0**. Os 3 fails de
> Lovable-MCP fecharam: ideiapartner (local) + cfoai (PR #44) + nfideia (PR #43, re-ramificado). Os 4
> produtos contidos (deny=19). **Falta só a Onda 3 + SOAK 2ª-máquina/span p/ tagear v15.**

- **✅ Fase 1 — frescor-tier + re-coleta (commit `80d8074`):** `collect.readSecurityFreshness()`
  (`check-security-freshness --tier`) → `agentd` snapshot → `read.js /overview` agrega pior tier →
  card R15-14 pilar 3 mostra o tier real (verde "fresco"). **+ Fix de 2 bugs do `readDoctor`** que
  mantinham o doctor SEMPRE vazio na coleta: (1) timeout 10s<16s; (2) `--json` sai exit 1 em FAIL e
  o `execSync` descartava o stdout → `|| true` + timeout 60s. Re-coleta (`agentd --once`) preencheu
  installed_versions(8)/mcp(6)/supabase(4/8)/security_freshness(ok)/doctor(real). SUMMARY:
  `R15-14-frescor-tier-SUMMARY.md`.
- **✅ Fase 3 — os 3 fails de Lovable-MCP FECHADOS (dono autorizou "abrir+mergear ambos"):**
  - **ideiapartner deny 16→19** (LOCAL, `.claude/settings.json` gitignored). Achado da re-coleta: o
    handoff o dava como "nada a fazer", mas faltavam as 3 tools MAIS perigosas (`deploy_project`,
    `query_database`, `send_message`). Efêmero ([[learning-uncommitted-security-config-ephemeral]]).
  - **cfoai (PR #44)** — branch `sec/lovable-mcp-deny` era cirúrgica → merge `sec→main` (deploy Lovable).
  - **nfideia (PR #43)** — ⚠️ a branch `sec/lovable-mcp-deny` estava **STALE** (revertia migrations/
    hooks que main ganhou) → **re-ramifiquei de main HEAD** (`sec/lovable-mcp-deny-v2`, só settings.json)
    e mergeei. [[learning-stale-autosync-branch-off-main]]. (A branch stale antiga remota ficou — a
    deleção foi bloqueada por não-autorizada; housekeeping p/ depois.)
  - **Doctor: fail 3→0.** Re-coleta final do agentd → snapshot doctor exit:0.
- **⏳ Onda 3 (R15-18..22) — PRÓXIMA, pós-/compact (dono pediu /compact antes):** construção pesada
  (allowlist write-path **LOCAL** — wiring NOVO provar por gate-negativo, ledger não wired ao /command;
  idea update — provar equivalência vs binário legado; auto-cura visível; refactor gerador de hooks
  — só metade deploy, por último; pre-op guard anti-autosync-race). **R15-17 GATED** (enc-keys N=2 +
  2ª máquina física — decisão do dono). Plano nos REQUIREMENTS `.planning/milestones/v15-REQUIREMENTS.md`.
- **Housekeeping pendente:** MEMORY.md em ~21KB (perto do limite 24KB) — compactar p/ <17KB. Branch
  stale remota `sec/lovable-mcp-deny` em cfoai/nfideia (deletar quando autorizado).

---

## ▶ RETOMAR (histórico) — v15 Fase B COMPLETA (8/8); próximo = Fase C (GATED) ou tag (2026-06-26)

**Onde estamos:** **Fase B (Onda 2) ✅ COMPLETA (8/8).** Sessão "continuar pós-compact" → R15-15 +
par de UI R15-13/R15-14. Autosync pausado nas cirurgias, **religado ao fim**.

- **✅ R15-13 + R15-14 (par de UI — fecha a Fase B) DONE** (regime-R: render+screenshot+network +
  exit-code tsc/build/test-recorder):
  - **R15-13** Flight Recorder **1ª-classe** (movido do rodapé p/ após o hero) + **microcopy LAW vs
    INTERPRETED visível** ao usuário (antes só em comentário). Filtro DIFERIDO. `test-recorder.sh`
    exit 0 (gate lê o JSON, não o `.tsx`).
  - **R15-14** card **"Saúde & Governança"** servido por **GET read-only** (sem `POST /command`/
    spawn/`--record`): 3 pilares — Saúde (`/overview`), **Releases-SOAK consumindo o `/soak` REAL**
    (que NENHUMA tela usava), Frescor-tier **DIFERIDO** honesto (`aguardando coleta`).
  - Arquivos: `apps/cockpit/src/pages/Overview.tsx`, `…/components/FlightRecorder.tsx`. SUMMARY:
    `.planning/.../B-governanca/R15-13-14-ui-pair-SUMMARY.md`. Render provado ao vivo (machines=2,
    5 milestones span≥1d, 2 hosts; `/overview` `/soak` `/fleet` 200; só favicon 404 benigno).
- **✅ R15-15 (runbook único)** DONE no mesmo dia (stub 163→22 linhas + índice `docs/guides/README.md`
  + gate de cobertura em `check-readme-sync.sh`, anti-teatro provado). SUMMARY: `R15-15-runbook-SUMMARY.md`.

- **Placar Fase B = 8/8:** ✅ R15-09 `--fleet` · R15-10 CI governance · R15-11 lembrete selos ·
  R15-12 exposição Cockpit · R15-13 Flight Recorder 1ª-classe · R15-14 card Saúde & Governança ·
  R15-15 runbook · R15-16 hello-world.

**🚦 Próximo passo — escolha do dono:**
- **(a) Fase C (Onda 3) R15-17..23** — começa GATED: **R15-17 espera a cerimônia das enc-keys**
  (decisão do dono pendente). Os não-gated (R15-18..22) podem ser planejados.
- **(b) Caminho p/ tag v15** — fechar o **resíduo p/ DoD**: PR `sec→main` cfoai/nfideia (fecha os 2
  FAILs do doctor; cfoai é PARTICULAR) + **re-coleta do agentd** (preenche os 2 n/a do doctor +
  `supabase_project_id` + `installed_versions` + abre caminho ao frescor-tier do R15-14). SOAK exige
  `idea_doctor=PASS`.
- **Net-new diferido (não-bloqueante):** frescor-tier de segurança no `collect.js` → o pilar 3 do
  card Saúde & Governança troca `aguardando coleta` pelo tier real.

---

## ▶ RETOMAR (histórico) — v15 Fase A COMPLETA + Fase B iniciada (R15-09); settings dos produtos PUSHADOS (2026-06-26)

**Onde estamos:** **Fase A (Onda 1) COMPLETA** (8/8, R15-01..08; ver `v15-phases/A-destravar/INDEX.md`).
**Fase B (Onda 2) INICIADA — R15-09 DONE:**
- **R15-09** (`3b05c00`) `idea-doctor --fleet` — agregador read-only de saúde cross-máquina sobre o ref `cockpit` (nome via alias-map A-05, idade anti-falso-verde, status honesto DORMANT/VAZIO/FAIL/OK; sem jq, bash 3.2).
- **bugfix `f80e9c5`** (commit SEPARADO) `idea-doctor --json` não vaza debt-markers (§12 sem guard `JSON_MODE`) — causa-raiz que o `--fleet` expôs (todos os snapshots vinham `doctor.exit=-1`/`sections=[]`). Destrava a coleta do doctor na frota.
- docs `cb1b2d1` (INDEX Fase B + carry-forwards).

**✅ RESOLVIDO (item 1 — settings dos produtos PERSISTIDOS + PUSHADOS via @devops 2026-06-26):**
- **cfoai-grupori, nfideia** → branch nova `sec/lovable-mcp-deny` (criada de main HEAD, commit cirúrgico só do `settings.json`, deny=19 ativo + velho mantido), **PUSHADA** (`8bf5ca2`/`66f1df51`). **cfoai é PARTICULAR.**
- **lapidai** → commit `8f08a62c` em `work`, **PUSHADO** (FF); pause-file por-repo removido.
- **ideiapartner** → `.claude/settings.json` gitignored, local-only (nada a fazer).

**⏳ PENDENTE (decisão do dono):** abrir/mergear **PR `sec→main`** em cfoai/nfideia. Enquanto não mergear, `idea-doctor` mostra **2 FAILs** (cfoai/nfideia "SEM contenção" em main, deny=0) — o §7e audita o working-tree da branch em checkout (main), e o fix vive em `sec/`. **NÃO é regressão** (estava mascarado pelo `--json` quebrado, agora consertado). O DoD do v15 exige `idea_doctor=PASS` p/ SOAK → fechar via merge controlado OU `settings.local.json`. Ver [[learning-gate-audits-current-branch-not-other-branch]].

**Próximo passo:** (1) PR `sec→main` cfoai/nfideia (fecha os 2 FAILs); (2) Fase B EM ANDAMENTO (**4/8 + R15-12 coleta**) — ✅ R15-09 (`--fleet`) · ✅ **R15-10** (`governance.yml` — CI dos 2 gates repo-puros faltantes; `1100f3f`) · ✅ **R15-11** (`remind-closeout-gates.sh` + LaunchAgent — notifica ff-merge/SOAK/frescor, nunca carimba; `01dc378`) · 🟡 **R15-12 b+c** (coleta destravada: `installed_versions` via `__dirname`, `mcp_connections` via `readMcp` → pilar Sinapse; `bceb326`); **próximo = R15-12 (a)** exposição read.js (JOIN `supabase_project_id` da tabela `project`, span SOAK = max-min dos epochs, drill-down `doctor.sections`, gh accounts — toca backend+SPA) · ✅ **R15-16** (hello-world §0.5 do onboarding + roteamento Deia; `987dcaf`); restam **R15-12(a)** exposição read.js + **R15-13** (Flight Recorder) + **R15-14** (card governança) + **R15-15** (runbook). Fase C: R15-17 GATED na cerimônia enc-keys. (R15-10/R15-12-coleta provam no Actions/próximo ciclo do agentd.)

**Learnings desta sessão (memória nativa):** [[learning-aggregator-status-from-verdict-not-absence]] · [[learning-gate-audits-current-branch-not-other-branch]] · [[learning-stale-autosync-branch-off-main]].

> v15/v16: **v15 = DX & Frota** (`.planning/milestones/v15-{REQUIREMENTS,ROADMAP}.md`, 23 reqs, 3 ondas);
> **v16 = Plataforma de Time** (renumeração do ex-"v15" split-plane, aviso no ADR). Índice `.planning/ROADMAP.md`
> com v14/v15/v16; repo é PÚBLICO (`Ideia-Business/ideIAos`).

**Decisões do dono que gateiam fases (não o milestone):**
1. ~~**R15-06** — cfoai Lovable-MCP `deny=0`~~ **RESOLVIDO 2026-06-25 = branch A** (remediar os 19 deny no prefixo do server ativo; fix §7e prefix-aware incondicional). Executado no A-08 (Wave 2).
2. **R15-17** — cerimônia das **enc-keys (B0-bis)**: a N=2 anterior provou só signing, não as enc-keys do selo (gate do write-path own-fleet).
3. **Tensão SOAK↔cfoai (crítico §3):** reconciliar se o `idea_doctor=PASS` do SOAK do v14.1 e o FAIL ao-vivo do cfoai medem o mesmo escopo.

**Teste do Lucas (Windows) — ainda válido, mas DESACOPLADO de R15-01:** o teste de 5 min de
`docs/guides/windows-wsl.md` §A.0 decide se o Windows **nativo+Git Bash** vira caminho de consumidor
(PASS) ou se fica só WSL2 (FAIL). Os demais fixes de `docs/process/multi-os-hardening-plan.md` foram
**absorvidos pela Onda 1 do v15** (R15-01/02/03). NÃO portar p/ PowerShell.

---

## Linhagem GSD — VERDADE CANONICA

GSD neste projeto = @opengsd/get-shit-done-redux 1.1.0 (org opengsd).
NAO e gsd-pi (3.x) nem pacote da org gsd-build.
Pin revertido 3x — ver versions.lock (nota expandida) e check-versions-lock.sh.
Proibido editar gsd= no versions.lock manualmente.

---

## Sessão 2026-06-24 — endurecimento de durabilidade do autosync (manutenção, não muda milestone)

Disparada por falha do LaunchAgent autosync na **MacBook-Air-2**. Diagnóstico cross-host (Mac mini ↔ MacBook)
achou DOIS problemas e uma auditoria de durabilidade (`wf_ab41764e`) achou mais gaps. Tudo fechado — commits
`a485588 → 5af6864 → dbfb017 → ac37eb3` (branch `work`):

1. **Incidente node/PATH (MacBook):** launchd não herda o PATH interativo; o node vem do **nvm**
   (`~/.nvm/versions/node/<v>/bin`, invisível ao launchd) → `setup.sh` falhava ("Node.js 18+ ausente") → propagate
   falhava nos 4 produtos. Fix: PATH-hardening no topo de `setup.sh` + `propagate-if-changed.sh` cobrindo
   Homebrew + `~/.local/bin` + nvm (`sort -V|tail -1`, corrige eleger a MENOR versão) + fnm/volta/asdf; gate Node≥18.
2. **Divergência `planning`/`cockpit` (causa-raiz):** `push_*_ref` fazia `git push` ingênuo sem reconciliar non-FF →
   loop crônico de "FALHOU" até reconciliar à mão. Substituído por **`_push_state_ref`** (auto-cura: FF-local/push/
   notify-once+flag; bootstrap de tracking; nunca `--force`). Provado em sandbox `/tmp` 11/11.
3. **Distribuição:** o daemon agora é **fonte-de-verdade versionada** em `source/autosync/git-autosync.sh`
   (heredoc removido do `setup-dev-machine.sh`); `propagate-if-changed.sh` o re-deploya (atômico) quando muda →
   correções chegam à frota sozinhas. `idea-doctor §6` detecta drift de conteúdo do daemon.

**Veredito:** a MacBook (e qualquer máquina nova) se auto-cura no próximo `git pull` do autosync — **sem passo
manual**. Detalhe durável na memória [[autosync-durability-hardening]]. **Q5 do v14.4 + fase de feature cross-máquina
seguem as pendências reais** (ver "## Próximo passo" abaixo).

---

## Sessão 2026-06-18 — remediação doctor + incidente autosync + housekeeping produtos

**Manutenção, NÃO muda o milestone v10.** A seção `## Próximo passo` (v10, abaixo) segue válida.

Disparada por `git pull && bash scripts/ideiaos-update.sh` → `idea-doctor` deu **FAIL de secret**. Tratado:

1. **Scanner endurecido (durável)** — `scripts/idea-doctor.sh:225`: o FAIL era **falso-positivo** num dummy de fixture (`OPENAI_API_KEY=sk-abcdEFGH1234…`, do `test-memory-export.sh`). `plausible_sk()` agora rejeita corridas sequenciais/dicionário. **Insight (observer effect):** redigir o transcript não converge — auditar o dummy o **propaga** para novos logs (a contagem subiu 1→4); fix certo é a heurística, não caçar transcripts. Doctor → **65 OK / 0 WARN / 0 FAIL**. Varredura exaustiva: **zero secret real** comprometido (só anon keys Supabase públicas-por-design + tokens de sessão expirados).
2. **Incidente autosync × cirurgia git** — o daemon `com.ideiaos.gitautosync` correu em paralelo às operações multi-repo: entregou o IdeiaOS sozinho (commit `wip: autosync`, conteúdo correto), **bloqueou** o push do nfideia (clone 78 atrás) e **contaminou** uma branch do ideiapartner (`add -A` varreu `package-lock.json` + um `CONTINUATION_HANDOFF.md` com marcadores de conflito). Com autorização do usuário: **pausado** (`launchctl bootout`) → repos reconciliados limpos → **religado** (`launchctl bootstrap`, status=0). _Lição: pausar autosync (com restauração garantida) antes de entrega git multi-repo assistida por IA._
3. **Housekeeping produtos (Lovable — branch, nunca main):** nfideia `.env` **untrackeado** + push (`94fffd05` em `work`; `.env` no disco preservado, só `.env.example` rastreado). ideiapartner: branch suja **removida** (local+remote), de volta na `main` `d0dc883c`; split público(`.env`)/secret(`.env.local`) preservado por design (não recebeu untrack — intencional).
4. **2 learnings extraídos** (memória global + vault): `secret-scanner-observer-effect`, `autosync-races-ai-git-surgery`.

**Notas informativas (resolvido 2026-06-19, não-pendência):** os stashes citados aqui foram triados no item 5 — nfideia `stash@{0}` e o autostash órfão do ideiapartner eram noise regenerável (dropados); o type-safety pass do ideiapartner foi arquivado em patch git-excluded e dropado (ver bloco "▶ RETOMAR AQUI"). SHAs dropados recuperáveis via reflog ~90 dias.

**2ª onda — gap-closure audit (ultracode) + prevenção:**
5. **Regressão de segurança HIGH achada e remediada:** auditoria read-only (`wf_247740a6`) achou a contenção Lovable MCP (`deny=19`) em só **2/5** alvos — os blocos uncommitted-on-main de nfideia/cfoai se perderam. Reaplicado e **PERSISTIDO em 5/5**: nfideia `e43f35f5` + cfoai `cdfa8d6` (commit na `work`) + ideiapartner `settings.local.json` (local; `.claude` gitignored lá). Verificação adversarial 4 lentes (`wf_a910bea1` + `wf_455c4880`) = PASS após corrigir claims stale de doc (MEMORY/STATE/handoff).
6. **Prevenção (a regressão passou despercebida porque nada falhava alto):** novo **check 7e** no `idea-doctor` — valida `deny>=19` por produto Lovable, **FAIL** se regredir; lê `settings.json` ou `settings.local.json`; skip gracioso sem produto. + teste de regressão (`tests/idea-doctor/test-lovable-mcp-containment.sh`, 9 asserts, prova o caminho de FALHA) + wiring no CI (`evals.yml`). 3ª learning: `uncommitted-security-config-ephemeral`.
7. **ENV-06 DESCONSIDERADO** (decisão do usuário): Ideia Chat é teste, não vai a produção → secret no histórico do ideiapartner é inócuo, rotação dispensada (memória `project-ideia-chat-test-secret-acceptable`).
8. **Housekeeping rules (PRG-03):** 8 `.claude/rules/ideiaos-common-*` materializadas em nfideia/cfoai/ideiapartner (paridade lapidai). Gap de propagação já fechado em código (`66598c1`).

**PR aberto:** [#3](https://github.com/Ideia-Business/ideIAos/pull/3) — `work`→`main`, consolida a sessão (11 commits). Revisar/mergear ou ff-merge direto (padrão IdeiaOS). Estado verificado: idea-doctor **69/0/0** (5/5 contidos) · teste 9/9 · readme-sync 116/116.

---

## Sessão 2026-06-16 (Cursor) — pesquisa + plano milestone v9 (Camada de Alinhamento)

Sessão de **pesquisa + planejamento**. **Nenhuma skill/código implementado** — só o pacote de planejamento do milestone **v9 — "Camada de Alinhamento"** (absorção seletiva de `mattpocock/skills`, MIT). Tudo já commitado/pushado nesta sessão.

**Pacote v9 entregue (artefatos para retomada rápida):**
- `docs/research/2026-06-16-mattpocock-skills-analise.md` — análise comparativa (8 seções): 3 GAPs reais (glossário de linguagem ubíqua durável; grilling colaborativo pré-plano desacoplado de fase GSD; ritual de "deepening" arquitetural), veredito por skill, encaixe do `/grill-with-docs`, orquestração da Deia, exemplo no nfideia.
- `security/quarantine/mattpocock-skills/` — material-fonte estagiado (18 arquivos, LICENSE MIT, `scan-absorbed.sh` PASS/exit 0).
- `docs/decisions/v9-mattpocock-skills-absorcao.md` — ADR (Aceito): absorver a TÉCNICA, não a ideologia anti-framework; `/grelha` roda SOB a Deia (gate opcional). Espelhado no Obsidian `Decisions/`.
- `.planning/milestones/v9-REQUIREMENTS.md` (R9-01..R9-07) · `.planning/milestones/v9-ROADMAP.md` (Fases A–F) · `.planning/milestones/v9-IMPLEMENTATION-PLAN.md` (grafo de dependências, esforço, gates, DoD, Fase G could-haves) · `.planning/milestones/v9-phases/{A..F}-*/*-01-PLAN.md` (PLAN por fase, formato GSD).

**Recomendação (resumo):** skill `/grelha` (alias `/grill`) = grilling pré-plano + glossário `CONTEXT.md` (glossário-only) + ADR inline; rule nova `ubiquitous-language`; gate opcional Passo 1.5 na Deia (`source/skills/idea/SKILL.md`); SHOULD: `/improve-architecture` (deepening). Padrão de absorção = igual v8 (addyosmani/agent-skills).

**Estado git ao fim:** `main` == `work`; `planning` pushado; working tree limpo (ver `git log`; hashes voláteis não fixados aqui).

> **Lição desta sessão:** não fixar hashes voláteis de `work`/`main` em STATE/handoff — hash volátil induz commits em cascata. Referir `git log`.

---

## ✅ v6 SHIPPED (2026-06-16) — atualização do IdeiaOS fechada

Milestone v6 "Resiliência + Marketing + GSD/OpenSpec" COMPLETO: 9 fases (23-31), 15 reqs, auditoria 15/15, tag v6.0. work=main pushed.

**Entregue:** antifragile gates (`source/lib/gates.sh`) · resiliência do instinct loop (`instinct-recover.sh`, 12/12 testes) · `/forge-agent` + `--validate-parity` · **Camada de Marketing** (`/marketing`, 4 agents, 22 BPs, sub-plugin) · 5 suites tests/v6-hooks (78 asserts no CI) · blindagem linhagem GSD (versions.lock) · context-packet handoffs · **`/spec` delta-spec brownfield** (21/21 testes) · 2 ADRs. README atualizado (105/105). Detalhes: `milestones/v6-ROADMAP.md`.

**Próximo (v7 — a definir):** piloto `/spec` num produto brownfield (nfideia) · gsd-browser quando publicado · novas demandas.

**Deploy nas máquinas:** `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh`
---

## Sessão 2026-06-16 — pesquisa: habilitar DeepSeek V4 Pro na AIOX (decisão adiada)

Sessão **consultiva** (ultracode/workflow de research). **Nenhuma mudança no repo IdeiaOS.** Usuário tem chave DeepSeek e perguntou como habilitar V4 Pro na aiox-core; pediu para **adiar a decisão**. Contexto completo em memória (`project-deepseek-v4-enablement-pending`).

**Descoberta-chave (não óbvia):** `.aiox-ai-config.yaml` (consumido pelo runtime Node `ai-provider-factory.js` em `~/dev/.aiox-core/...`) e o **Claude Code são planos separados** — o Claude Code não lê esse arquivo; os agentes AIOX usados aqui são subagentes Claude Code com `model: opus`. A config só alimenta features de IA dos **produtos** (via factory), e **nenhum código de produto chama a factory hoje** (`getProviderForTask`/`executeWithFallback` → grep vazio em `~/dev`). Logo, adicionar o bloco DeepSeek **não tem efeito** até o produto chamar a factory.

**Decisão pendente — onde habilitar:** (a) nos **produtos** (editar `.aiox-ai-config.yaml` + ligar a factory no código de cfoai/nfideia/etc.) ou (b) no **Claude Code** (settings + proxy OpenAI→Anthropic, pois DeepSeek é OpenAI-compatible). Facts verificados (docs oficiais): model `deepseek-v4-pro`, base `https://api.deepseek.com`, env `DEEPSEEK_API_KEY`; legados `deepseek-chat`/`deepseek-reasoner` aposentam **2026-07-24**; campos `bulk`/`feature_flag_env`/`fallback_to` no YAML não são lidos por esta versão do runtime (só `primary`/`fallback`/`routing`).

**Nota de higiene:** working tree tinha mudanças **não-minhas** (hooks/autosync: `.claude-plugin/marketplace.json`, `scripts/build-plugins.sh`) — deixadas como estão; não commitadas.

## Sessão 2026-06-14 (tarde) — v5 Memória entre IDEs IMPLEMENTADO

Milestone v5 aberto E implementado nesta sessão (5 fases 18-22, 11 reqs). Orquestrado por workflows (ultracode): research 4+1 agentes → build 6 agentes → verificação adversarial 13 céticos.

**Entregue (tudo no `work`, verificado local):**
- `source/hooks/memory-import.sh` (SessionStart: planning shared → memória nativa; tolera slug #30828; exit-0 offline; gera ponte Cursor `.mdc`; defesa `.git/info/exclude`)
- `source/hooks/memory-export.sh` (Stop: nativa → planning via **git plumbing** primário, worktree fallback; secret-scan; nunca toca main)
- `source/skills/memory-sync/SKILL.md` (export explícito `/memory-sync`)
- `source/templates/memory/` (MEMORY.header, fact.schema, planning.gitignore)
- `scripts/check-memory-not-on-main.sh` + wiring em `install-git-hooks.sh` (pre-commit/pre-merge) — guard instalado e provado (bloqueia memória em main, permite em work, override OK)
- autosync (`setup-dev-machine.sh`): exclui memória + branch guard + push planning
- `docs/decisions/v5-memory-topology.md` (ADR) + `docs/memory-sync-model.md` (3 camadas)
- `scripts/install-global-patches.sh` Patches 12/13 (instalados live) + `scripts/idea-doctor.sh` Seção 9 (memória) + varredura de leak no main
- `tests/v5-memory/` 3 suites (import, export 16/16, guardrails 10/10) — **todas verdes**
- Store semeado no branch **`planning`** (`.planning/memory/shared/` + `.planning/.gitignore`)
- Propagado: `build-plugins.sh` + `build-adapters.sh`. README sync 96/96. **`idea-doctor` = 0 FAIL (61 OK)**.

**Verificação adversarial:** 10 PASS / 1 PARTIAL / 1 FAIL → ambos remediados (PARTIAL R5-10 = patches não instalados → instalados; FAIL invariante = guard não instalado + defesa → guard instalado + `.git/info/exclude` + doctor leak-scan). Re-provado em sandbox isolado.

### ✅ Dogfood ao vivo + bug corrigido (2026-06-14, fim)
- Usuário publicou `origin/planning`. O `memory-export.sh` rodou de verdade num Stop e exportou **4 fatos reais** para `planning:.planning/memory/shared/facts/` — sistema provado end-to-end com dados reais.
- **Bug pego pelo dogfood:** o export commitava `.planning/memory/local/staging/` (via `update-index`, que ignora `.gitignore`) → buffer per-máquina vazava pro remoto (viola Phase 19 SC#4). **Corrigido** (`945a09b`): export só commita `shared/facts/` + `MEMORY.md`. Regressão T5 adicionada. `planning` limpo via worktree (`ec36f36`). Plugin hooks sincronizados.

### ✅ v5 (deliverable IdeiaOS) = COMPLETO. Itens abaixo são de OUTROS repos/máquinas.
**Re-escopo (2026-06-14, fim):** R5-01 misturava 2 coisas. A **prevenção** de leak (guard, `.gitignore`, doctor Seção 9) é trabalho de v5 e está no IdeiaOS = ✅ feita. A **remediação** do arquivo `.lovable_mem_tmp.md` é de UM artefato pré-existente que vive em `nfideia:main` (outro repo de produção, commit `604c0a19`) — **NÃO é construção de v5**; é housekeeping operacional de outro repo. IdeiaOS está limpo em todos os branches.

1. **Re-push `planning`** (se ainda à frente) — `AIOX_ACTIVE_AGENT=github-devops git -C ~/dev/IdeiaOS push origin planning`. (work o autosync empurra). [pode já estar sincronizado]
2. **nfideia housekeeping (opcional, fora do v5):** remover `.lovable_mem_tmp.md` de `nfideia:main`. O `.gitignore` do nfideia **já contém** o padrão (não recorre), então não há urgência. Fazer com nfideia em `main` limpo: `cd ~/dev/nfideia && git rm -f .lovable_mem_tmp.md && git commit -m "chore: remove leak" -- .lovable_mem_tmp.md && AIOX_ACTIVE_AGENT=github-devops git push origin main`. ⚠️ nfideia é produção em dev ativo (branches mudando) — fazer deliberadamente, não automatizado.
3. Deploy do v5 nas demais máquinas/projetos: `bash scripts/ideiaos-update.sh`.

## Sessão 2026-06-14 — auditoria + limpeza de pendências obsoletas

idea-doctor: **51 OK · 0 WARN · 0 FAIL** (ambiente saudável). Auditadas as pendências registradas contra a realidade — 3 eram registro obsoleto, agora corrigidas:

- **Atualizar máquinas (esta):** ✅ já feito — doctor confirma `ideiaos-update.sh` rodou no `MacBook-Air-2` (11/11 patches, 0 drift, versões = pin).
- **Feature "Novidades":** ✅ mergeada nos 2 repos — `feature/novidades*` não existe mais em `ideiapartner` nem `nfideia`; conteúdo está no `main` (hashes novos via merge/squash). O registro "branches aguardando o usuário" estava defasado.
- **Stub "Ultima sessão automática":** placeholder vazio auto-gerado pelo hook de sessão — consolidado.
- **Doc-drift:** STATE/handoff não mencionavam o 11º patch (`backlog-sync`, `c0da5d1`) nem os fixes do doctor (`94083bf`, `a58bb17`) de 06-13 — registrado.

**Pendências que restam (não-obrigatórias / externas):**
- Mac mini rodar `git pull && bash scripts/ideiaos-update.sh` — baixo risco (esteve ativo 06-13; `versions.lock` protegido repo-wide). Confirmável só rodando o doctor lá.
- Deploy em prod das Novidades (migration + Lovable Publish) — decisão do usuário.
- `/gsd-new-milestone "IdeiaOS v5"` — opção, se desejar abrir o ciclo.

## Sessão 2026-06-13 — padronização AIOX + escopo do manifesto

**Decisão estratégica AIOX (ADR `docs/decisions/aiox-gitignore-npx-vs-global.md`):**
- **Instrução = global, engine = por-máquina.** GSD + `/idea`/Deia + personas AIOX (`@dev`/`@qa`/`@architect`) ficam globais (`~/.claude`/`~/.cursor`); o engine `.aiox-core` (npm `@aiox-squads/core-internal` v5.2.x, stateful, ~58M) é tratado como `node_modules` — instalado por máquina via `npx aiox-core@latest install` e **nunca versionado**. Orquestrador oficial = `/idea` (Deia) + IdeiaOS.
- **`setup.sh`** passou a gitignorar `.aiox-core/` + agentes multi-IDE em todo projeto (previne o drift que divergiu os 4 repos).
- **Aplicado retroativamente nos 4 repos** (ideiapartner, nfideia, lapidai, cfoai-grupori): `.aiox-core` v5.2.9 local + gitignored, tracking antigo `git rm --cached`.

**Manifesto v1.1** (`manifests/modules.json`): `catalogScope` esclarece que o manifesto = só código-fonte próprio (`source/`); GSD/AIOX são camadas centrais mas **dependências upstream** rastreadas em `versions.lock`. Confirmado 1:1 com `source/`.

**Fix:** `source/skills/idea/SKILL.md` — referência morta `/dev-setup` → `/ideiaos-setup` (6×).

**Segundo cérebro (Obsidian) sincronizado:** o `Changelog/IdeiaOS` do vault estava em 12/jun e a pasta `Decisions/` vazia desde 28/mai (ADRs nunca espelhados — sync repo→vault é manual). Corrigido: entrada 2026-06-13 no Changelog, 2 ADRs espelhados em `Decisions/`, `00 Index.md` alinhado (verificado por 3 agentes, 0 issues). Encodado no `extract-learnings` **Passo 4c** para não repetir (commit `caf5ad8`, propagado ao plugin `ideiaos-core`).

**Commits:** `d53c1e7` · `5a81b48` · `5619d17` · `761f8a8` · `caf5ad8` (+ autosyncs). Working tree limpo, `work` = `origin/work`.

## 🏁 PLANO MAIOR 100% CONCLUÍDO

3 milestones shipped em 2026-06-12: **v2.0** (absorção ECC, 8 fases) → **v3** (refinamento, 5 fases) → **v4** (produção, 3 fases). 16 fases, 42 planos, tags v2.0/v3.0/v4.0. Auditorias: 8/8, 19/19, 8/9+1warn.

## Atualizar as máquinas — status (verificado 2026-06-14)

- ✅ `MacBook-Air-2` — feito (doctor confirma: statusline presente, 11/11 patches, 0 drift)
- ⚠️ `Mac mini` — confirmar quando conveniente (baixo risco): `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh`

## Decisões registradas (2026-06-12)

1. **Secret ANTHROPIC_API_KEY: NÃO** — evals LLM só localmente (`bash evals/run-evals.sh --ci`); job de CI skipa limpo por design
2. **Repo: manter PRIVADO** — marketplace funciona nas máquinas autenticadas; público só se quiser distribuir como open source
3. ~~checkout@v4→v5~~ ✅ aplicado (151132a)

## v5 — Fase 17 CONCLUÍDA (2026-06-12)

Critérios de eval robustos entregues: avaliador híbrido Sinais + LLM-judge, 22 casos atualizados, 3 vereditos corrigidos fail→pass. Ver `17-01-SUMMARY.md`.

**Feature Novidades — ✅ MERGEADA nos 2 produtos (verificado 2026-06-14):**
- **NFideia**: feature no `main` (badge não-lidas + "marcar como lida"); `feature/novidades*` não existe mais. Branch original `bab37b99` entrou via merge/squash (hash não preservado).
- **Ideiapartner**: feature no `main` (release_notes + reads RLS, UserChangelog, badge no header); `feature/novidades` não existe mais. Branch original `d124e409` entrou via merge/squash (hash não preservado).
- **Pendente (decisão do usuário):** aplicar migration em prod + Lovable Publish onde aplicável — não verificável por git.

## Sessão 2026-06-16 (Cursor) — encerramento + alinhamento de branches

**Parte 1 — fechamento admin:** commit `a834544` (`STATE.md` + handoff) pushed em `origin/work`. Sem código novo.

**Parte 2 — alinhamento (pedido do usuário):**
- `main` fast-forward ← `work` — **23 commits** (v6/v7/v8, marketing, `/doubt`, etc.) → `origin/main` @ `a834544`
- `planning` merge ← `work` → `origin/planning` @ `5c23b48` (artefatos GSD v6–v8 + memória v5 preservada)
- **`main` = `work`** no mesmo hash; working tree limpa

**Parte 3 — commit/push final (pedido do usuário):**
- Commits docs: `fd56c8d`, `0ffd912`, `647c242` — pushed em `origin/work`, `origin/main`, `origin/planning`
- Estado final: **`main` = `work` = `647c242`** · **`planning` = `a89e34b`** · working tree limpa
- `propagate-if-changed` disparou ao merge em `main` → setup em 6 projetos `~/dev/*` (Jarvis, cfoai, ideiapartner, lapidai, nfideia, IdeiaOS)

**Verificação pós-sync:** README 112/112 ✅ · idea-doctor 61 OK / 2 FAIL — secrets em memória Claude de **Jarvis** e **iCloud Projects** (não IdeiaOS); remediação manual em `~/.claude/projects/`.

## Próximo passo

> **▶ RETOMAR AQUI (2026-06-26 — v15 Fase B 5/8; R15-12 exposição DONE; próximo = R15-15 runbook, interpretação JÁ DECIDIDA) — leia primeiro:**
> Sessão "vamos continuar" (pós-compact). Autosync pausado durante a cirurgia, **religado ao fim**.
> - **✅ R15-12 (Cockpit — expor dados ricos) DONE** (commit `461fd7e`): camada de exposição GET no `apps/cockpit/server/read.js` — `GET /projects` (supabase_project_id), `GET /soak` (span REAL = MAX-MIN epoch, não wall-clock), `GET /doctor?cell=<mid>` (drill-down sections, MID_RE), `accounts` no `GET /fleet` (gh, metadata-only). **7 gates por exit-code** (incl. input inválido `/doctor?cell=NAO_EH_MID`→400; zero-leak no /fleet). `doctor.sections=[]`/`supabase_project_id=null` hoje são honestos (snapshots pré-fix `--json`; preenchem no próximo ciclo do agentd). SUMMARY: `.planning/milestones/v15-phases/B-governanca/R15-12-dados-ricos-SUMMARY.md`.
> - **Placar Fase B = 5/8:** ✅ R15-09 `--fleet` · R15-10 CI governance · R15-11 lembrete selos · R15-12 exposição · R15-16 hello-world. Restam: **R15-13** (Flight Recorder 1ª-classe) + **R15-14** (card Saúde & Governança GET) = **par de UI** (Overview.tsx; consomem os GET do R15-12; exigem **frontend-visual-loop**, regime-R) + **R15-15** (runbook).
> - **🚦 PRÓXIMO = R15-15 (runbook único) — INTERPRETAÇÃO DECIDIDA PELO DONO 2026-06-26: "eliminar duplicação + índice" (NÃO fundir 5 num monólito).** Plano concreto:
>   1. `docs/guides/windows-wsl.md` = **runbook único de Windows** (single-source dos 3 gotchas: `checkout work`/`/mnt/c`/`autocrlf` — já cobre 6/2/2).
>   2. `INSTALL-WINDOWS.md` (raiz, **54% verbatim** = 32/59 linhas dup do Caminho B) → **stub-ponteiro fino** p/ `windows-wsl.md` Caminho B. Ninguém o referencia exceto o REQUIREMENTS → impacto baixo.
>   3. **Índice de instalação** (no onboarding ou doc próprio) que aponta cada aspecto ao seu doc — NÃO funde `onboarding-novo-dev.md`/`env-setup-dev.md` (heterogêneos, zero gotchas).
>   4. **Estender `scripts/check-readme-sync.sh`** (NÃO criar script novo) com **gate de cobertura**: cada gotcha aparece ≥1 no runbook (grep -c antes/depois), e o stub não re-duplica o corpo.
>   - Hard-gate R15-05 ✅ satisfeito (A-04 DONE). ⚠️ Sessão longa — **/compact recomendado ANTES de executar R15-15**.
>
> **▶ RETOMAR AQUI (2026-06-24 tarde — v14.4 Q5 RATIFICADO + substrato LOCAL B5–B8 construído e adversarialmente verificado; próximo = seal/push_cmd_ref, GATED no owner) — leia primeiro:**
> Sessão "siga com os pendentes, múltiplos agentes, ultracode". 4 workflows em sequência, tudo por **exit-code**.
> - **Q5 ratificado** (`docs/decisions/v14.4-command-ref-origin-exposure.md` → **ACEITO 2026-06-24**) após re-review adversarial (`wf_ceb14fd4-9d3`, 8 agentes, refutação). **2 reconciliações de segurança aplicadas ANTES do flip:** (1) canonical do `payload_hash` alinhado ao código real (`sha256` dos bytes do command-file producer-canonical, NÃO um canonical literal de 6 campos) + `target_machine` pinado obrigatório cross-máquina; (2) primitiva de selo nomeada (`age`/X25519) + **B0-bis** (`enc_pubkey` no pin). Step-up reconciliado; SUMMARY bootstrap 45→47.
> - **Substrato LOCAL B5–B8 SHIPPED** (cripto-local, ZERO segredo/produção/provedor): `source/agentd/{cmd-ref,ledger,ack,rate-limit}.sh` + 4 testes standalone + gate agregado **`scripts/test-writepath-substrate.sh`** (4/4 + meta-canário + gate-negativo; exit 0). Bootstrap B0–B4 não regrediu (47/47). `refs/ideiaos/cmd` ausente no repo vivo. SUMMARY: `.planning/milestones/v14-phases/14.4-write-path/14.4-01-substrate-SUMMARY.md`.
> - **Verificação adversarial achou e FECHOU 2 reais no `ledger.sh`:** 🔴 CRITICAL (verify cego na CAUDA: editar/substituir/truncar/append-no-fim da última davam verify=0) → **âncora-de-cauda** (HEAD-file `contagem|sha`); 🟠 HIGH (append não-atômico perdia entradas sob concorrência) → **lock-por-dir + O_APPEND**. Re-verificação focada (`wf_51de2527-d3b`) → **PASS** (4 ataques de cauda→3; 30 paralelos→30/verify=0; zero bug novo). `test-ledger.sh` 13/13 + 2 mutações.
> - **SEAL + B0-bis CONSTRUÍDOS (mesma sessão, tarde):** `age` **dispensado** — seal = **sealed-box X25519 nativo do `node:crypto`** (já na stack): `source/agentd/{seal,unseal}.mjs` (`assina(P)→sela(P‖sig)`, destinatário no ciphertext, seal-then-sign recusado por construção) + `pinned-keys.sh` 5º campo `enc_pubkey` (retrocompat; bootstrap 47/47). `test-seal.sh` 7/7 + verificação adversarial PASS (`wf_a538aa42`, 0 achados). Gate agregado **5/5**. Pré-cond #1/#4 do ADR Q5 = VERDE.
> - **🚦 PRÓXIMO PASSO (gated — só 2º host físico OU admin GitHub):** (1) **`push_cmd_ref`** ao origin (espelha `_push_state_ref`) + cerimônia **N=2 das enc-keys** + **feature cross-máquina** (executor do token verificado + UI de aprovação) — TODOS exigem **2ª máquina física real** (não construir dormente = dead code). (2) **HEAD-assinado** do ledger = Wave de wiring (`debt:` honesto; opcional seria downgradeable = teatro). (3) **R-WP10 segue FECHADO**. (4) **Lovable persist** (cfoai/lapidai = só infra; nfideia/ideiapartner têm produto misturado — branch+PR infra-only). (5) **FG-PATs** org `Ideia-Business` = admin GitHub.
>
> **▶ RETOMAR AQUI (2026-06-23 — v14.0 TAGGED + v14.4 F0a (scaffold step-up) EXECUTADO/VERIFICADO; próximo = F0b humano OU tag v14.1) — leia primeiro:**
> Sessão "Deia, resolver pendências" (autosync pausado durante a cirurgia git; religado ao fim).
> - **Tags `v14.0` + `v14.1` FECHADAS** (SOAK re-record → span 1d cada, gate exit 0, `git tag` + push via @devops). **SOAK queue VAZIA.** Idioma fixado em pt-BR (`.claude/settings.json` `language=portuguese` + diretiva no `CLAUDE.md`, commitado; global + cfoai/ideiapartner ajustados local-por-máquina).
> - **v14.4 F0a (scaffold autônomo do B3 + B4) EXECUTADO** — o step-up HYBRID em disco, **ZERO segredo/produção/provedor**, provado por **exit-code (47/47)** no gate agregado `scripts/test-writepath-bootstrap.sh`. Artefatos em `source/agentd/`: `stepup-verify-comprovante.mjs` (verify Ed25519/WebCrypto, **autenticidade ANTES do binding**), `stepup-token.sh` (produtor O2: atômico, subject-do-comprovante, jti+subject-charset, jti-consume fail-closed), `stepup-verify-token.sh` (verify O2 fail-closed, nonce durável cross-processo **fail-closed**), `stepup-otp-client.sh` (seam de transporte, código por STDIN, fail-closed), `stepup-pin-backend.sh`, `stepup-tier-policy.sh`, `stepup-touchid.sh`; backend scaffold `source/agentd/stepup/` (4 edge functions: CSPRNG, comprovante assinado-não-booleano, OTP só como **digest salgado** no DB, CORS loopback) + `schema.sql` + `README.md` (passos F0b); test signer `tests/writepath/lib/{fake-stepup-backend.mjs,stub-transport.sh}`. SUMMARY: `.planning/milestones/v14-phases/14.4-write-path/14.4-00-SUMMARY.md`.
> - **Verificação adversarial (2 rounds) achou e FECHOU 1 CRÍTICO:** `stepup-verify-token.sh` aceitava QUALQUER token forjado (`if ! cmd; then rc=$?` → `$?` sempre 0 → exit 0); o gate 34/34 NÃO pegava (blind-spot: todo caso B4 alimentava token VÁLIDO). Fix + 3 casos B4 negativos (sig-forjada→3 / não-pinada→4 / sem-sig→6), **mutação-provado**. + HIGH subject-binding (subject agora do aprovador-OTP, não do command-file), OTP-via-STDIN, salted-digest no DB, atomic-publish, S-N1 anti-replay **fail-closed**, S-N2 subject-charset. **O gate é mutação-testado** (sabotar qualquer check → vermelho; 8 sabotagens mortas).
> - **F0b MAJORITARIAMENTE EXECUTADO 2026-06-23** (projeto Supabase `IdeiaOS - Cockpit`, ref `xdikjgpkiqzgebcjgqmu`): ✅ 4 edge functions deployadas (`--no-verify-jwt`); ✅ secrets `STEPUP_SIGNING_KEY`/`KID`(`eb502ee5408cb7c1`)/`ALLOWED_SUBJECTS` (privada gerada local, **nunca no contexto**); ✅ pubkey pinada no agentd (out-of-band); ✅ `schema.sql` aplicado (dashboard); ✅ transporte real `transport-curl.sh`. **PROVA END-TO-END NO BACKEND REAL PASSOU:** `verify-otp` real → comprovante ASSINADO não-booleano; `stepup-verify-comprovante.mjs` verificou contra a pubkey pinada → **exit 0** (Deno↔Node canonicalização byte-idêntica — *o* risco fora do gate); **binding A≠B → exit 7**; **single-use → 400**. (Management API via keychain falhou — token go-keyring; schema via dashboard; signing key por referência de arquivo /tmp 0600 deletado → credential-isolation respeitado.)
> - **F0b COMPLETO 2026-06-23:** `RESEND_API_KEY` + `STEPUP_MAIL_FROM` (`cockpit@updates.ideiabusiness.com.br` — domínio verificado; é `updates.`, NÃO `atualizações.`) setados; **fluxo OTP-por-e-mail REAL provado** (`send-otp`→Resend entregou→código `462245` na caixa→`verify-otp`→comprovante assinado→`stepup-verify-comprovante.mjs` exit 0; single-use→400). Backend step-up funcional ponta-a-ponta.
> - ✅ **Hardening Resend FEITO 2026-06-23:** `RESEND_API_KEY` trocada por **sending-only** restrita a `updates.ideiabusiness.com.br` (validado: envio 200, `GET /domains`→401 escopo-restrito, `send-otp`→200). Full-access removida do secret (decisão de separar — atende uso-futuro do IdeiaOS sem acoplar blast-radius ao step-up).
> - ✅ **CERIMÔNIA N=2 FEITA 2026-06-24** (2º host = MacBook-Air-2): eixo **comprovante** — MacBook pinou o backend out-of-band (FP `f933d155…` MATCH) + verificou `verify-otp` real → exit 0, binding → 7; eixo **O2** — MacBook gerou chave de máquina (FP `SHA256:pEOUnDWm5…`), assinou, Mac mini pinou `macbook-air-2`(dev) + **verificou → exit 0** (tamper → 3). **R-WP10 SATISFEITO no regime N=2 real.** Runbook em `source/agentd/stepup/README.md`. (Pin permanente: a Mac mini agora confia em `macbook-air-2`; reverter = `pinned-keys.sh revoke-local macbook-air-2`.)
> - **🚦 PRÓXIMO PASSO (gated, owner):** (1) **Q5** — ratificar o ADR `docs/decisions/v14.4-command-ref-origin-exposure.md` (ref único opaco + bundle selado). (2) **Construir a fase de FEATURE cross-máquina** (o transporte do comando via ref `cmd`, o agentd-alvo executando o token verificado, a UI de aprovação) — o bootstrap+N=2 provam a PRIMITIVA, não a feature. (3) Fine-grained PATs na org `Ideia-Business` (owner). Limpeza opcional dos OTPs de teste: `delete from public.otp_codes; delete from public.otp_attempts;` no projeto `xdikjgpkiqzgebcjgqmu`.
>
> **▶ RETOMAR AQUI (2026-06-22 noite — v15 design REVISADO por review adversarial + RECONCILIADO; veredito F0=GO; próximo = codar B3 = F0a-scaffold, MAS o pré-req é o mini-ADR do comprovante já criado) — leia primeiro:**
> Sessão "revisar os designs (81/82/v15) antes de construir" → rodei o review adversarial **`wf_8432e800-818`** (20 agentes, 5 lentes, cada HIGH refutado por cético independente). **Veredito: a espinha é sólida e F0 é GO** — a tese "F0 está bloqueado" foi REFUTADA 2× (loopback já é condição #7 das 8; split autônomo/humano já encodado em `autonomous:false`+`<prereq>`). **APLIQUEI TUDO (pure-design, zero código):**
> - **1 bloqueador REAL de F0 (sobreviveu à refutação):** o esquema de chave do **comprovante assinado** do step-up estava não-especificado → criei **`docs/decisions/v14.4-stepup-comprovante-key-scheme.md`** (Ed25519 DEDICADA do backend P4, privada no env por NOME; pubkey **pinada no agentd** no enrollment; `stepup-token.sh` **verifica a assinatura ANTES do binding**, fail-closed; estende a condição #1 → comprovante com hash certo mas sig-inválida/chave-não-pinada = RECUSADO, exit 3/4). **É pré-req de codar B3.** Linkado no `14.4-CONTEXT.md`.
> - **Decisão GitHub CORRIGIDA (honestidade):** o "MITIGADO" que gravei era prematuro. **Probe `gh`:** org `Ideia-Business`=FREE, credencial atual=**token OAuth clássico org-wide**, gestão FG-PAT **não provisionada** (endpoint owner=404). → BLOCKER #2 (reversão) = **[BLOCKER-CONDICIONAL]** (gateia F1 por teste-negativo de PAT; blast-radius é org-wide HOJE). Atribuição (#1) = **[MITIGADO-PARCIAL/DESLOCADO]** (telemetria assina a TELEMETRIA, não o push; +cross-check audit-log). Step-up-loopback (#4) **rebaixado a defesa-em-profundidade** ("única barreira" refutada). +HARDENING novo nomeado: DNS-rebinding/CSRF-loopback (#5).
> - **2 contradições de doc reconciliadas em 81:** FG-PAT-por-estação agora desenhado (era ZERO no 81 vs asserido no ADR); **Pilar A REBAIXADO** (não é mais pilar — atribuição vira Visão por telemetria assinada). **Reversão = dupla-teardown** (re-pin O2 **+** revoke-PAT; corrigida a frase falsa "re-pin corta a autoridade").
> - **Cortes de MVP aplicados (enforce-simplicity):** F1 **magra** (3 tabelas; papel binário `admin|dev` — CTO+TechLead=admin; onboarding estático); vínculo **por snapshot** (agentd NÃO conduz OAuth); F2/F3 **gated-por-dev-real**, não por tempo.
> - **🚦 PRÓXIMO PASSO:** o operador escolheu "aplicar tudo + mini-ADR agora" (FEITO). Próximo build = **F0a = scaffold autônomo de B3** (send-otp/verify-otp/schema/`stepup-token.sh` em disco + proof-gates locais por exit-code, ZERO segredo, honrando o mini-ADR do comprovante), depois **F0b** (humano: provisionar `ideiaos-cockpit-stepup`+deploy). **Antes de F1 (não F0):** merjar via `/spec` **R-WP12 + RLS-por-campo + Admissão/Autorização** (SHALL verificáveis) + ratificar v15. ⚠️ Sessão ~750 tool calls — **/compact recomendado antes do build F0a**.
> - Verificação por exit-code dos edits: mini-ADR 49 linhas; FG-PAT 10× em 81 (era 0); blockers re-rotulados; dupla-teardown nos 2 docs; Pilar A=0 como autoritativo. Output do review: `tasks/wb32qdcn6.output`.

> **▶ RETOMAR AQUI (2026-06-22 tarde — v14.4: contrato MERJADO + ADRs ACEITOS + bootstrap B0/B1/B2 EXECUTADO + step-up PIVOTADO p/ HYBRID email-OTP; próximo = executar B3-HYBRID + B4, OU 2ª máquina p/ tag) — leia primeiro:**
> Sessão "faça isso tudo" → "vamos em frente" → "comece a execução": contrato `/spec` v14.4 **merjado**, ADRs **aceitos**, plano de bootstrap **verificado**, e **Wave 1 + B2 EXECUTADOS** (19/19 proof-gates por exit-code).
> - **Contrato MERJADO** em `specs/cockpit/spec.md` (**9→20 reqs**, +R-WP1..R-WP11). spec-validate + spec-merge + spec-analyze (gate da fonte pós-merge) todos exit 0 / 0 HARD. Arquivo em `specs/_archive/2026-06-22-v14.4-write-path-security/`. Verificação prévia: painel adversarial 3 lentes (`wf_7cb55bba`) = SOUND, 9 achados integrados (1 HIGH loophole R-WP10 + R-WP11 rate-limit novo).
> - **ADRs Q1-Q3 ACEITOS** (`docs/decisions/v14.4-*`): `origin-auth-signing-mechanism` (Q1+Q2) = **O2** (par por-máquina no keychain; **fato verificado: signing-git NÃO bootstrapado** → O3 descartado); `step-up-without-relying-party` (Q3) = LocalAuthentication-via-agentd + fallback terminal. Adversarial 2 lentes = SOUND-WITH-FIXES; **CRÍTICO** corrigido: **lista pinada autoritativa-LOCAL** (ref = espelho não-confiável) + papel ligado à chave pinada + revogação só por re-pin out-of-band. Aceitar **NÃO abre o gate** (reversível).
> - **PLANO DE BOOTSTRAP escrito + verificado** (`.planning/milestones/v14-phases/14.4-write-path/14.4-00-bootstrap-PLAN.md` + `14.4-CONTEXT.md`): fase-GATE, **5 proof-gates B0-B4** fail-closed por exit-code, ZERO mutação de produção / comando cross-máquina / API de provedor. 2 lentes (security-reviewer + gsd-plan-checker, este **probou o host**) pegaram **2 BLOCKERS** (openssl do host é LibreSSL sem Ed25519 → `ssh-keygen -Y`; `ssh-keygen -Y` ignora byte pós-footer → veneno vira payload-tamper) **+ 2 CRITICALs** (anti-teatro do agregado virou estrutural c/ manifesto+REASON+canário; revogação-forjada agora assinada-por-peer-pinado) — integrados. Commit `b23ac7e`.
> - **BOOTSTRAP Wave 1 + B2 EXECUTADO** (commit `e57c6bf`): `source/agentd/{sign-payload,verify-payload,pinned-keys}.sh` + `14.4-00-SUMMARY.md`. **19/19 proof-gates por exit-code** — **B0** (par `ssh-keygen -Y`; privada nunca na saída/value-compare; lista pinada **autoritativa-LOCAL**; estrutura), **B1** (fail-closed: payload-tamper=3 / não-pinada=4 / papel-forjado=5-do-PIN / só-sha256=6 / downgrade=3), **B2 = o CRÍTICO** (revogação FORJADA assinada-por-peer-pinado RECUSADA + adição-via-ref recusada). Cripto-local puro, ZERO produção. idea-doctor 76/3/0.
> - **PIVÔ step-up Touch-ID → HYBRID email-OTP** (commit `bb8091f`): objeção do operador (Touch ID não-universal: Mac minis/teclados externos/Linux/Windows sem sensor). `@security-reviewer` = **ADOPT-WITH-CONDITIONS/HYBRID**. Step-up = **email-OTP universal** (projeto Supabase **DEDICADO** `ideiaos-cockpit-stepup` — operador escolheu p/ isolar blast-radius) + **Touch ID atalho local**; ambos alimentam a assinatura O2. **Fix CRÍTICO S-01:** o `verify-otp` do ideiapartner retorna `{verified:true}` solto (inseguro p/ aprovação-de-ação → confused-deputy/replay) → exige **binding `payload_hash`** + comprovante ASSINADO. ADR-2 revisado (8 condições). R-WP3 não muda. **Material a minerar/adaptar:** `~/dev/ideiapartner/supabase/functions/{send-otp,verify-otp,register-trusted-device,check-trusted-device}/` (RLS deny-all + lockout reusáveis; +binding +CSPRNG +rate-limit-não-IP; NÃO copiar signInWithPassword/roles-de-produto).
> - **🚦 PRÓXIMO PASSO:** **executar B3-HYBRID** (`autonomous:false`, exige você): (1) provisionar o projeto Supabase dedicado `ideiaos-cockpit-stepup`; (2) minerar+adaptar as edge functions do ideiapartner (binding+CSPRNG+fail-closed+tiering); (3) `stepup-token.sh` + `stepup-otp-client.sh`; provar por exit-code as 8 condições (binding A≠B, comprovante-assinado-não-booleano, fail-closed, CSPRNG, tiering). Depois **B4** (gate agregado `scripts/test-writepath-bootstrap.sh`). 5/5 verde = pré-condição R-WP10 (**mono-máquina**). **Aberto:** cerimônia **N=2 real** + **Q5** → fase de feature. ⚠️ Sessão longa — considere `/compact` antes do build B3.
> - **Tags v14.0/v14.1:** SOAK **≥2 máquinas ✓** (o record da MacBook-Air-2 chegou; `.planning/soak/v14.{0,1}.log` têm Mac-mini + MacBook). Falta só **span ≥1d**: re-record `check-soak.sh v14.0 --record` após **hoje ~21:58**, `v14.1 --record` após **amanhã ~11:00** → `git tag`.
> - **v14.2:** ainda a definir (precisa `/grelha` p/ escopar). Autosync religado ao fim desta sessão.
>
> **▶ RETOMAR AQUI (2026-06-22 — v14.1 MVP Bridge CLOSEOUT CONCLUÍDO; próximo = 2ª máquina p/ tag, ou v14.2) — leia primeiro:**
> O **closeout da v14.1 está completo** (detalhes em `STATE.md` § "Sessão 2026-06-22"). Feito: **8/8 planos, A1–A12 9/9 exit-code** + **passe visual A7/A10** (frontend-visual-loop: Overview/Frota/Cofre + ⌘K com verbos **inline** `run_doctor→exit 0` / `pause_autosync` arm→Confirmar?→exit 0) + **🔴 bug CORS-preflight S-05 achado NO visual-loop e corrigido** (`read.js` `OPTIONS /command`→404 fazia o `POST` falhar no browser; curl mascarava — [[learning-curl-masks-cors-preflight-verify-browser]]) + **re-selo `@security-reviewer` PASS** (review full + re-review focada do delta S-05, 0 findings) + **README** (seção console) + **vault** (Changelog+Learning) + **memória nativa** + **STATE** + **SOAK v14.1 heartbeat** (1 máq/0d).
> - **Push + merge FEITOS:** `work` pushado p/ `origin/work` (via @devops) e **PR [#6](https://github.com/Ideia-Business/ideIAos/pull/6) `work`→`main` mergeado (FF)** → `main`=`work`. Autosync **RELIGADO** (`autosync-pause.sh off`, status ATIVO).
> - **Follow-ups de debt — RESOLVIDOS (commit `b960daf`):** (a) ANSI literal no stdout da ⌘K → `stripAnsi` no render (verificado no browser); (c) idea-doctor §15 MID divergente (`awk|shasum` hasheava o `\n`) → fix `printf '%s'|shasum` casa o `collect.js`, §15 resolve `c706ac77d577`, exit 0. (b) `/fleet` "agressivo" reavaliado: **não é bug** (poll de 3s do heartbeat, ~20 req/min, design legítimo). Re-selo pós-polish PASS (`b57d1a2`).
> - **Tag `v14.1` DEFERIDA** (1 máq/span 0d, igual v11–v14.0): precisa **≥2 máquinas + span ≥1d** sobre epochs em `.planning/soak/v14.1.log`. Rodar `bash scripts/check-soak.sh v14.1 --record` numa 2ª máquina (MacBook-Air-2) + re-record após 1 dia → `git tag v14.1`. **É o ÚNICO item pendente da v14.1, e é gate-bloqueado por design (não fraudar o SOAK).**
> - **Próximo milestone:** **v14.2** (a planejar, espelhando o método v14.0). Aberto 🔴: origin-auth v14.4 (gate de toda escrita cross-máquina).

> **▶ (histórico — fase + closeout JÁ CONCLUÍDOS acima) RETOMAR AQUI (2026-06-22 — v14.1 MVP Bridge EXECUTADO/code-complete; próximo = CLOSEOUT) — leia primeiro:**
> Os **8 planos da v14.1 foram EXECUTADOS** sequencialmente (gate por wave, espelhando o método v14.0 — escolha do usuário). **22 commits locais em `work` (ahead 22, NÃO pushados; autosync PAUSADO)** — range `7673478..cd5a062`. **Suite A1–A12 exit-code = 9/9 verde** (A1,A2,A3,A4,A5,A6,A8,A9,A12); cada plano com `14.1-0N-SUMMARY.md` + verificação independente do orquestrador. Waves: W1 {01 data-access, 05 flight-recorder, 07 ttt-harness} · W2 {02 overview+shell} · W3 {03 frota-cofre, 04 ⌘K} · W4 {06 zero-leak, 08 closeout/exit-code}. ⌘K (04) rodado em **opus**, S-01..S-04 provados por HTTP-code (403/412/400); Zero-Leak (06) limpo→exit 0 + 3 venenos→exit≠0 (regex/entropia/runtime), sem FP.
> - **FALTA só o CLOSEOUT (Task 3 = `checkpoint:human-action`) — tudo do orquestrador, NÃO feito ainda:**
>   1. **A7/A10 visual** via `frontend-visual-loop` (Chrome DevTools): Overview/Frota/Cofre + ⌘K com ≥3 verbos inline. ⚠️ **NUNCA disparar B2 `resume_autosync` nem B4 `force_sync`** (des-pausam o autosync) — usar **B6 `run_doctor`** (read-only) + **B1 `pause_autosync`** (arm-confirm, idempotente).
>   2. **Re-selo de segurança:** `@security-reviewer` sobre o diff da fase (cobre o novo canal `POST /command` + auth Origin+Host+token efêmero) → `bash scripts/check-security-freshness.sh --record PASS @security-reviewer`.
>   3. **README** (recursos novos: Overview/Frota/Cofre, ⌘K allowlist B1-B6, Flight Recorder v0, gate Zero-Leak 7-superfícies, harness TtT Bridge) + **vault Obsidian** (Changelog + extract-learnings).
>   4. **STATE.md + este handoff** (estado final).
>   5. **SOAK v14.1** 1º heartbeat: `bash scripts/check-soak.sh v14.1 --record` — **tag v14.1 DEFERIDA** (1 máq/span 0d hoje, igual v11–v14.0; precisa ≥2 máq + span≥1d).
>   6. **Push** via `AIOX_ACTIVE_AGENT=devops git push` (IdeiaOS pode main).
> - **⚠️ autosync PAUSADO** (`bash scripts/autosync-pause.sh status`) — religar (`off`) **só ao FIM** do closeout, após o push.
> - **Follow-up não-bloqueante (achado durante 08):** idea-doctor §15 check-(d) dá **WARN** porque o MID local computado (`131fd55c7b65` via `ioreg|shasum`) ≠ o MID do snapshot no ref (`c706ac77d577`, que o agentd/`collect.js` grava). A derivação manual difere da do `collect.js`; idea-doctor fica **verde** (degrada gracioso). Investigar a derivação real do `collect.js` antes de confiar no sub-sinal de frescor local do read-model.
> - **Decisões travadas:** capability/ref = `cockpit` (NUNCA `mission-control`); data access = `node:sqlite`; execução = gate-por-wave sequencial. CLI GSD não resolve fases v14.

> **▶ (histórico — fase JÁ EXECUTADA acima) RETOMAR AQUI (2026-06-21 noite — v14.1 MVP Bridge PLANEJADO; próximo = EXECUTAR) — leia primeiro:**
> `/gsd-plan-phase v14.1` concluído. **8 `PLAN.md` (17 tasks / 4 waves)** + `14.1-CONTEXT/RESEARCH/PATTERNS/VALIDATION.md` em `.planning/milestones/v14-phases/14.1-mvp-bridge/`. Método **espelhou o v14.0** (dir manual + multi-agente) porque o CLI GSD **não resolve fases v14** (`roadmap.get-phase 14.1`→`found:false`; milestone usa `v14-cockpit-PLAN.md`, não `v14-ROADMAP.md` canônico — mesma causa do `phase.complete` falho no 14.0).
> - **Verificado por 3 lentes adversariais:** plan-checker = CONCERNS (0 bloqueador de goal) · security-reviewer (opus) = SOUND-WITH-FIXES (1 HIGH **S-01** = canal `POST /command` só com CORS → CSRF/DNS-rebinding driva `spawnSync`; **corrigido**) · antifragile-gates = **0 violações** (52 critérios; A3/A8/A12 exit-code testados empiricamente). **9 fixes aplicados** (contidos a 5 planos + `VALIDATION.md`; 02/05/07 intactos). Todos os 8 planos `valid:true` no validador SDK.
> - **Decisões travadas:** capability/ref = **`cockpit`** (NÃO `mission-control` — codinome morto nos docs 02/71); data access = **`node:sqlite`** (NÃO `better-sqlite3`); Zero-Leak = regex+entropia+veneno triplo; Flight Recorder v0 = 13 commits reais do `versions.lock` via `classifyActor`; ⌘K = `cmdk` + `POST /command` enum tipado default-deny (auth Origin+Host+token efêmero).
> - **Waves:** W1 {01 data-access, 05 flight-recorder, 07 ttt-harness} · W2 {02 overview+shell} · W3 {03 frota-cofre, 04 ⌘K} · W4 {06 zero-leak, 08 closeout}. R14-05 (6 planos) + R14-06 (4 planos) cobertos.
> - **🚦 PRÓXIMO PASSO:** **`/gsd-execute-phase 14.1`** com **contexto fresco** (`/clear`). Manter **autosync pausado** durante os gates git (`test:recorder`/`test:zeroleak` em sandbox `/tmp`). A task `14.1-08` Task 2 (suite A1–A12) é a mais pesada → rodar após `/compact`.
> - Aberto 🔴: origin-auth v14.4 (gate). Commits limpos `work`: `3972a88`→`2c4cb11`→`5c89a2c`→`3a69f67`.

> **▶ RETOMAR AQUI (2026-06-21 noite — v14.0 Substrato+Espinha EXECUTADO/COMPLETO; próximo = v14.1) — leia primeiro:**
> `/gsd-execute-phase 14.0` rodado em **modo SEQUENCIAL** (escolha do usuário — fase auto-modificante). **7/7 planos DONE**, verificação goal-backward **24/24 gates por exit-code** (`.planning/milestones/v14-phases/14.0-substrate-spine/14.0-VERIFICATION.md` status=passed). Entregue: `idea-doctor --json` (§0-§15) · ref `cockpit` (git-plumbing, **pushed `cockpit@{u}=30edb3e`**) · `ideiaos-agentd` read-only (Zero-Leak=0) · `console-ingest`→SQLite (api_key sem `value`, A5) · TtT harness · SPA black-gold loopback renderiza card real (screenshot anexado em `14.0-07-spine-screenshot.png`).
> - **⚠️ AUTOSYNC foi HARD-STOPPED nesta sessão (`launchctl bootout com.ideiaos.gitautosync`)** — o pause-file `autosync-pause.sh on` é **INERTE** porque o binário deployado `~/.local/bin/git-autosync` **não tem o guard de pause-file**. **VERIFICAR/RESTAURAR:** `bash scripts/autosync-pause.sh status` e `launchctl list | grep autosync`; se ausente → `launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`. Learning [[learning-autosync-pause-file-guard-not-deployed]].
> - **Tag v14.0 DEFERIDA** (no-tag, igual v11-13): SOAK `.planning/soak/v14.0.log` = 1 máquina/0d; precisa ≥2 máquinas + span≥1d sobre epochs gravados. Security re-selo **PASS** já no ledger.
> - **`phase.complete` CLI FALHOU** ("Phase 14.0 not found") — o milestone v14 não tem `v14-ROADMAP.md` padrão (foi planejado com `v14-cockpit-PLAN.md`). Completude marcada **manualmente** (STATE + milestone PLAN + este handoff). _Follow-up: criar `v14-ROADMAP.md` ou ajustar a estrutura p/ o CLI achar as fases v14._
> - **PRÓXIMO PASSO:** **v14.1 — MVP Bridge read-only** (R14-05/06): `/gsd-plan-phase v14.1` (Overview/Frota/Cofre-Espelho + ⌘K + Flight Recorder v0 + gate Zero-Leak + TtT meta <10s). Aberto 🔴: origin-auth v14.4 (gate).

> **▶ RETOMAR AQUI (2026-06-21 noite, Mac mini — SOAK queue FECHADA: v12.0 + v13.0 taggeados) — leia primeiro:**
> Pedido: testar o comportamento de uma task agendada para hoje. As **duas tasks one-shot de fechamento de SOAK não completaram**: `close-soak-v12-tag-tonight` (devida 06-20 22:45) **disparou mas abortou** antes de taggear (ledger sem re-record → bailou num gate inicial); `close-soak-v13-tag-tomorrow` (devida hoje 17:50) **nunca disparou** (overdue — essas tasks exigem o app Claude Code aberto na Mac mini no gatilho). O gate em si estava correto (recusava taggear com span 0d).
> - **Fechado manualmente na Mac mini (com confirmação do usuário):** re-record v12 + v13 (idea-doctor PASS + regressão PASS, span→1d cada) → push ledgers (`3100e45→57daf9c`) → verify exit 0 nos dois → `git tag v12.0 v13.0` + push (`AIOX_ACTIVE_AGENT=devops`). Autosync pausado/religado. **Ambas as tasks agora `enabled:false`** (sem risco de re-fire). Re-record na Mac mini fecha só o span de tempo — os ≥2 atores reais distintos já estavam no ledger, então não fraudou o gate ([[learning-automate-the-reminder-not-the-integrity-stamp]], [[learning-soak-span-is-record-delta-not-wallclock]]).
> - **Estado:** `v11.0`+`v12.0`+`v13.0` todos taggeados; **SOAK queue VAZIA**; `work` 0/0; idea-doctor verde.
> - **🚦 DESBLOQUEIO — v14.0 deixa de estar gated:** os blocos v14.0 abaixo dizem "só executar quando o v13 tagar". **O v13 tagou agora.** O acoplamento temporal pelo arquivo compartilhado `scripts/idea-doctor.sh` (cujo SOAK do v13 o RE-EXECUTAVA na re-gravação) **está resolvido** — não há mais milestone ativo em SOAK tocando esse arquivo. **Próximo passo real do v14:** `/gsd-plan-phase v14.0` consumindo `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md`, com **contexto fresco**. (Ligar `SECFRESH_GATE_ENABLED=1` segue decisão à parte, pós-1º-ciclo.)

> **▶ RETOMAR AQUI (2026-06-21, tarde — sessão headroom/cookbook, INDEPENDENTE do v14) — leia primeiro:**
> - **Headroom (`chopratejas/headroom`) avaliado → NÃO adotar** como proxy/MCP/dependência. Memória `headroom-eval-2026-06`; relatório `/tmp/headroom-analysis/HEADROOM-ANALYSIS.md` (efêmero — recriável do clone).
> - **`/tool-output-compressor` SHIPPED** (padrão minerado, invertido p/ CLI-First): skill + lib stdlib + spec viva (7 req) + tests verdes + plugin + **roteado pela Deia**. Commits `05d7149→9f3d02a→f50c022`. Uso: `bash ~/.claude/skills/tool-output-compressor/lib/toc.sh compress --json`. Opção (b) hook auto-compressão por limiar = **PARQUEADA não-bloqueante**.
> - **HF cookbook (`huggingface/cookbook`) — CONCLUÍDA: NÃO absorver.** 6 especialistas + verificação adversarial 8/8. 3 wins de pattern-transfer no produto (extração-com-âncora→nfideia; PII-scrubber→cfoai/nfideia; DDL-subset-text2SQL→cfoai); RAG gated em ter retrieval. Guia durável: `docs/guides/hf-cookbook-patterns.md`; memória `hf-cookbook-eval-2026-06`.
> - Não toca o v14 (paths distintos). O próximo passo do v14 segue abaixo, **intacto**.

> **▶ RETOMAR AQUI (2026-06-21, Mac mini — v14.0 PLANEJADO via multi-agente; execução GATED pelo v13) — leia primeiro:**
> A fase **v14.0 (Substrato + Espinha)** do Cockpit foi **planejada** (não executada). Frota Ultracode:
> `gsd-pattern-mapper` → `gsd-planner` → **3 verificadores adversariais paralelos** (plan-checker +
> security-reviewer + auditor antifragile).
> - **Entregue (commit `9bcb15c`, `work` 0/0):** 7 PLAN.md GSD em
>   `.planning/milestones/v14-phases/14.0-substrate-spine/` (**20 tasks / 3 waves**) — 01 idea-doctor
>   `--json` · 02 ref `cockpit` por plumbing · 03 TtT baseline · 04 SPA scaffold black-gold · 05 agentd
>   collector+plist · 06 schema.sql (8 tabelas, **ApiKey sem value**) + ingest.js · 07 SPA lê read-model
>   + gates/SOAK. + `14.0-CONTEXT.md` + `14.0-PATTERNS.md` + seção "v14.0 PLANEJADO" no `v14-cockpit-PLAN.md`.
> - **6 defeitos pegos e corrigidos pela revisão adversarial** (todos re-verificados por exit-code, 0
>   violações antifragile): gate-theater tautológico; regex JWT fraca p/ service_role; falta de gate
>   bind-loopback (`127.0.0.1`); falta de diff de não-regressão §15; IDs `R14-CTX-A*` **fantasma**
>   (violação Art. IV No-Invention); tabela errada p/ `last_doctor`.
> - **🚦 NÃO executar ainda — gate concreto, não só disciplina:** `/gsd-execute-phase 14.0` só **depois
>   do v13 tagar**. O plano `14.0-01` edita `scripts/idea-doctor.sh`, e o SOAK pendente do v13
>   **RE-EXECUTA** o `idea-doctor` na re-gravação (`idea_doctor=PASS|regression=PASS`) → editar agora
>   arriscaria a tag do v13. Os milestones compartilham o **mesmo arquivo vivo**. Se forçar, rodar só
>   Wave 1 **menos o `14.0-01`**. Learning: [[learning-active-milestone-gate-couples-via-shared-file]].
> - **Estado do gate v13 (medido 2026-06-21 01:20):** SOAK 2/2 máquinas ✓, **span 3968s de 86400s** ✗;
>   a janela ≥1d abre quando um heartbeat for gravado **≥ 2026-06-21 17:46:26** — o que a task agendada
>   `close-soak-v13-tag-tomorrow` faz (exige app Claude Code aberto na Mac mini). Só `v11.0` tagado.
> - **Próximo passo real:** quando o v13 tagar → `/gsd-execute-phase 14.0` com **contexto fresco**.

> **▶ RETOMAR AQUI (2026-06-21, Mac mini — v14 IdeiaOS Cockpit: PLANO COMPLETO + apuração 100%, PROPOSTO/zero-código) — leia primeiro:**
> Pedido: transformar instalação/ativação/gestão dos projetos numa **página web de visão CTO** = **IdeiaOS Cockpit** (console local-first sobre o substrato auto-telemetrado do IdeiaOS). **Doc-only, zero código de produto.** Decisões do usuário (AskUserQuestion): nome **Cockpit**; **formalizar via /spec+GSD antes de código**; comando cross-máquina **aprovado p/ v14.4 gated** por threat-model; brand ouro.
> - **Pacote (`docs/ideiaos-console/` — 20 docs):** blueprint multi-agente (13 agentes; o crítico adversarial pegou contradição fatal — "piggyback no SOAK `--record`" é manual) + roadmap + phase-1 spec + 6 docs de especialista (10-60) + apuração (70-79).
> - **Contrato `/spec` VIVO:** `specs/cockpit/spec.md` (9 req SHALL/DEVE), validado+merged+arquivado (`specs/_archive/2026-06-20-v14-cockpit-foundation/`). **1º uso de `specs/` no próprio IdeiaOS.** **ADR** `docs/decisions/v14-cockpit-local-first-git-as-bus.md` (Aceito). **Plano GSD** `.planning/milestones/v14-cockpit-PLAN.md`.
> - **Apuração 100% (validada NA própria Mac mini — doc 73):** corrigiu `192`→**MacBook-Air-2** (não Mac-mini); Constelação = **7 projetos** reais (Jarvis 469 sessões → descobrir, não hardcodar 5); **nenhum segredo crítico git-tracked**. Docs 74-79 fecham: resiliência (agentd empurra o ref `cockpit` por si → autosync vira redundância), DDL (ApiKey **sem coluna value**), produtividade (KPI-âncora SOAK; multi-usuário gated por 2º ator), alertas+allowlist (`revoke`-em-massa fica fora pra sempre), testes (Zero-Leak + dogfood de veneno), glossário 22 termos + **registro mestre de 39 questões (doc 79)**.
> - **Commits limpos:** `90b3062` (ADR+plano) + `2f0d288` (wave 74-79); resto via autosync. `work` 0/0. idea-doctor verde.
> - **Próximo passo real:** `/gsd-plan-phase v14.0` consumindo `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md` — **SÓ quando o v13 tagar** (não entrelaçar milestones ativos). **Aberto 🔴:** Q1 — autenticação de origem cross-máquina (`sha256 ≠ assinatura`) faz a v14.4 ser **GATE, não milestone**; o `/spec` de segurança consome as 9 questões (doc 70/79). _Planning-sync do `.planning/` v14 defere à ativação do milestone; a memória já propaga via hook._ Learning: [[learning-deterministic-replay-needs-structured-event-store]].
>
> **▶ RETOMAR AQUI (2026-06-20 noite, Mac mini — SOAK 2ª máquina v12/v13 + LaunchAgent + tag v12 agendada) — leia primeiro:**
> Rodada operacional na **Mac mini** (2ª máquina) para destravar o SOAK de v12 e v13:
> - **v12-qa-security:** heartbeat da 2ª máquina gravado (idea-doctor+regressão PASS), commit+push (`462ce2b`, capturado pelo autosync — benigno). Ledger agora **2 máquinas distintas**; span fecha **hoje 22:36:36**. **Tag `v12.0` AGENDADA** p/ hoje **22:45** via task local `close-soak-v12-tag-tonight` (`~/.claude/scheduled-tasks/`): re-grava heartbeat (fecha span ≥1d) → verifica `check-soak` exit 0 → `git tag v12.0` + push. **Aborta sem taguear** se qualquer gate falhar. ⚠️ exige o app Claude Code **aberto** na Mac mini às 22:45 (senão roda no próximo launch).
> - **v13-security-freshness:** heartbeat da 2ª máquina gravado (`703da4d`, pushed). Ledger **2 máquinas**; span fecha **amanhã 2026-06-21 17:46:26**. Tag `v13.0` aguarda 1 re-gravação **após** esse horário (`check-soak v13-security-freshness --record` → commit/push → `git tag v13.0`).
> - **LaunchAgent mensal AI-security ATIVADO na Mac mini** (`com.ideiaos.refresh-ai-security`, bootstrap OK status 0; dispara dia 1 de cada mês 09:00). _Pendência v12 do LaunchAgent: FECHADA._
> - Autosync pausado durante a cirurgia e **religado** ao fim. idea-doctor verde nas 2 gravações.
> - **Housekeeping (mesma sessão) — "deixe 100% correto":** idea-doctor **3 WARN → 0** (`75/0/0`): /spec drift corrigido (global sem 3 libs v11 — `setup.sh --global-only` é version-gated, espelhei o dir); AI-security snapshot bootstrapado; **suíte de design re-ancorada à proveniência real `b7e3af80`** (content-match verificado; `update-design-suite.sh` é destrutivo p/ ref-SHA — `f1c4e53`). **Branch `planning` reconciliado + sincronizado p/ v13** (`4dd9c1f`: merge de `origin/planning` 10/2 diverso, memory store preservado 47 facts; STATE v10→v13; ROADMAP +v9–v13; `planning` 0/0). **Os 2 defeitos de script CORRIGIDOS e testados:** (a) `setup.sh` deploy version-gated → content-aware (`4c878b5`); (b) `update-design-suite.sh` destrutivo → `cp -RL` + salvaguarda + clone direto p/ ref-sha (`a5d3590`+`4ab4e9a`). **Causa real do (b) era `cp -R` copiando os symlinks `data//scripts/` do upstream como DANGLING (NÃO o clone-por-sha)** — reproduzir o passo exato pegou a diagnose errada inicial (net-del 9374→112 no teste; pin `b7e3af80` está correto). ⚠️ **Autosync da Mac mini é pré-v11 (não honra o pause-file)** — comitou meus fixes como "wip: autosync"; rode `ideiaos-update.sh` no mini p/ deployar o autosync guard-aware. Ambos os defeitos em memória ([[learning-global-skill-deploy-version-gated-misses-lib-changes]], [[learning-design-suite-sha-pin-clone-destructive]]).
>
> **▶ RETOMAR AQUI (2026-06-20 — v13 Security Freshness Gate: núcleo + surfacing C + propagação, PARCIAL/no-tag) — leia primeiro:**
> Milestone **v13** ("Selo de Frescor de Segurança") implementado e propagado. Segurança verificada periodicamente e **por sistema**, padrão SOAK aplicado a dívida de segurança (gatilho determinístico risk-weighted → `@security-reviewer` → re-selo). **Nunca gateia PR de feature.**
> - **Núcleo W1-W4** (`8779d88`): `check-security-freshness.sh` + ledger + idea-doctor §14 (ADVISORY) + rule `security-freshness` + sandbox 10/10.
> - **Surfacing por produto = opção C** (`a6ab59d`): hook **`post-commit` advisory** (não bloqueia por construção). `SECFRESH_ROOT` → 1 engine no IdeiaOS audita qualquer repo → **produto não versiona script** (zero trigger Lovable). `setup_security_freshness_layer()` no `setup.sh --project-only` (bootstrap ledger local + install husky-aware + `.git/info/exclude`). Sandbox 14/14.
> - **Propagação 4 produtos (local-only, surgical):** nfideia `.husky/post-commit` (excluído); ideiapartner/lapidai/cfoai `.git/hooks/post-commit`. Verificação binária: 4/4 OK, **0 tracked churn** (sem trigger Lovable, sem race autosync → não precisou pausar autosync). Live-test cfoai: warn→exit 0, fresco→silêncio.
> - **SOAK:** heartbeat gravado (`.planning/soak/v13-security-freshness.log`, 1 máquina/0d).
>
> **Passos restantes p/ TAG `v13.0` (operacionais, não-código):**
> 1. **2ª máquina** (Mac mini): `bash scripts/check-soak.sh v13-security-freshness --record` (após pull). 
> 2. **Span ≥1d:** re-gravar 1 heartbeat **≥ 2026-06-21 17:46:26** (o `≥1d` é delta entre gravações, NÃO wall-clock — esperar não basta, tem que RE-gravar; ver [[learning-soak-span-is-record-delta-not-wallclock]]).
> 3. `bash scripts/check-soak.sh v13-security-freshness` → exit 0 → `git tag v13.0`.
> - **Ligar o gate** (`SECFRESH_GATE_ENABLED=1`) é decisão **pós-observação do 1º ciclo** (R13-07 — estreia advisory).
> - **Rule auto-propaga** via post-merge a cada pull de `main` (lapidai já tem); não foi commitada manualmente nos produtos.
> - ⚠️ Antes de cirurgia git multi-repo: pausar autosync (`scripts/autosync-pause.sh on/off`, com `trap`). _Esta sessão não precisou (footprint 100% local/untracked)._
>
> **✅ v11.0 TAGUEADO 2026-06-20** (`ec965b1`→`1ba01c8`, pushed). **SOAK 2ª máquina FEITA na Mac mini para v12 E v13** (2026-06-20 noite) + **LaunchAgent mensal AI-security ATIVADO na Mac mini**. Restam só os spans ≥1d: **v12.0** será taguada via task agendada hoje 22:45 (`close-soak-v12-tag-tonight`); **v13.0** aguarda re-gravação após amanhã 17:46:26. (Nota: a rotina `ideiaos-soak-tag-readiness` NÃO estava persistida nesta máquina — `list_scheduled_tasks` vazio; substituída pela task local one-shot.)

---

> **▶ RETOMAR AQUI (2026-06-19 noite — propagação v12 aos produtos + ROADMAP) — leia primeiro:**
> Esta rodada fechou 2 gaps de documentação/propagação **além** do v12:
> - **ROADMAP atualizado** — `.planning/ROADMAP.md` estava parado no v8; adicionados v9 (tag `v9.0`) + v10/v11/v12 (PARCIAL/no-tag) (`843f499`). Vault `Changelog/IdeiaOS.md` ganhou entrada v11+v12.
> - **Propagação v12 aos 4 produtos = COMPLETA E ATIVA.** A `propagate-if-changed` automática falhara numa corrida com o autosync (21:41). Repropagado com segurança (autosync pausado+religado via `trap`): **lapidai**/**cfoai-grupori** (branch `work`) commitados; **ideiapartner** (rules gitignored → local-ativo, sem commit); **nfideia** (rules **tracked em main**, Lovable) via PR [nfideia#41](https://github.com/Ideia-Business/nfideia/pull/41) — **MERGED** (squash `9728b153`) + pull ff-only → **ativo em main**. Os 4 agora com **10 `ideiaos-common` rules + `credential-isolation`**; drift (7/8/9/8) zerado.
> - **Recomendação (futura, opcional):** alinhar **nfideia** ao modelo do ideiapartner — **gitignorar `.claude/rules`** — para que próximas propagações sejam automáticas (sem PR). Exige `git rm --cached` + 1 commit em main (decisão Lovable à parte).
> - **Mecanismo @devops:** `git push`/`gh pr create|merge` são gated pelo hook constitucional `enforce-git-push-authority.cjs` (Art. II — bloqueia até a string literal em `echo`/`grep`). Sob autorização explícita do usuário, satisfaz-se o gate prefixando o comando com `AIOX_ACTIVE_AGENT=devops` (detecção command-scoped, aliases `devops`/`aiox-devops`). Ver [[learning-devops-push-gate-command-scoped-agent]].
>
> **Pendências restantes = só 2** (operacionais, detalhe no bloco v12 logo abaixo): TAG `v11.0`/`v12.0` (SOAK) + LaunchAgent mensal na Mac mini. **nfideia NÃO é mais pendência.**

---

> **▶ RETOMAR AQUI (2026-06-19, v12 QA & AI-Security — 4 ondas + refresh DONE, PARCIAL/no-tag):**
> milestone implementado e commitado em `work` (`8d18650`). Origem: análise multi-agente
> `docs/research/2026-06-19-qa-security-arsenal/` (`wf_50d8299b-f69`, 20 agentes; 4 docs:
> ANALYSIS/PROPOSAL/SECURITY-KNOWLEDGE/MONTHLY-REFRESH-SPEC). Absorção **conceito-only**
> (licenças via GitHub API: Hercules **AGPL-3.0** · TalEliyahu **MIT** · muellerberndt **SEM LICENÇA**):
> - **W1** `antifragile-gates` (2 regimes: artefato-exit-code vs runtime-NL) + `operating-discipline` #6 + nova rule `credential-isolation` (+ entry no `modules.json`)
> - **W2** `security-reviewer` (OWASP LLM Top 10 condicional + prompt-injection-runtime) + `mcp-hygiene` (critérios MCP SlowMist/TTPs + "Excessive Agency")
> - **W3** `docs/process/qa-coverage-index.md` (índice + 3 gaps) + `docs/reference/ai-governance-crossmap.md`
> - **W4** `evals/cases/EVAL-026/027/028` (anti-injection adversarial, ADVISORY)
> - **Refresh mensal:** `scripts/refresh-ai-security.sh` (curl+diff+sha, nunca executa; snapshot **LOCAL/gitignored** — muellerberndt all-rights-reserved) + `infra/launchd/com.ideiaos.refresh-ai-security.plist` + idea-doctor §13
>
> ADR `docs/decisions/v12-qa-security-absorption.md`; plano `.planning/milestones/v12-qa-security-PLAN.md`.
> Verificado: idea-doctor **73/1/0**, readme-sync 120/120, evals dry-run lista os 3 casos. Propagado a `.claude`/`.cursor`/`plugins`.
>
> **2 passos restantes (ambos operacionais, não-código):**
> 1. **TAG `v12.0`** — pendente do SOAK (`.planning/soak/v12-qa-security.log`: 1 máquina/0d agora; precisa ≥2 máquinas + ≥1d). Rodar `bash scripts/check-soak.sh v12-qa-security --record` na 2ª máquina + esperar 1 dia, como o v11.
> 2. **Ativar o refresh mensal na always-on (Mac mini):**
>    `cp infra/launchd/com.ideiaos.refresh-ai-security.plist ~/Library/LaunchAgents/ && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ideiaos.refresh-ai-security.plist`
>
> ⚠️ **Lição:** dogfood pegou um agente alucinando "Hercules = Apache-2.0"; a API confirmou **AGPL-3.0**. Verificar licença de repo via `gh api repos/<o>/<r> --jq .license.spdx_id`, NUNCA via alegação de LLM. Ver [[learning-gitignore-third-party-verbatim-snapshot]].

---

> **▶ RETOMAR AQUI (2026-06-19, v11 COMPLETO — fechamento PARCIAL/no-tag · SOAK 2/2 máquinas PASS):** as **6 ondas do v11 estão DONE**, commitadas + pushadas em `work` (`origin/work=049a947`, 0/0):
> - **W1** autosync guard-aware — `44336c5`
> - **W2** CI repo-self-consistency gates + `check-source-headers` + design-suite ref resolvido — `ccb3ff0`
> - **W3** SOAK gate `check-soak.sh` + surface-budget + `/idea` routing eval cases — `70f0cd6`
> - **W4** `/spec --analyze`+`--converge` (libs `spec-grammar`/`analyze`/`converge`, tests 23 asserts) — `e65d0e0` **+ hardening** `4011186` (corrigiu bloqueador A2-template-FP + 9 achados da verificação adversarial wf_99173505)
> - **W5** deltas LOW R2/R4/R6/R8 — `4637b1d`
> - **W6** 2 ADRs (`v11-spec-kit-analyze-converge`, `v11-license-provenance-quarantine`) + SOAK heartbeat — `0ede0c0`; fix ledger gitignored — `c60d97a`; plugins/+README sync — `78e55b9`/`671f2de`
>
> **SOAK status (ledger `.planning/soak/v11-arsenal.log`):** 2/2 máquinas PASS — MacBook-Air-2 @17:51 (`4011186`) + Mac-mini-de-Gustavo @18:30 (`2ca25df`), ambos idea_doctor+regressão PASS → **durabilidade cross-máquina GREEN** (o risco real do gate fechou). Falta **só o span ≥1d** (ambos heartbeats de 06-19, ~39min → `0d`).
>
> **ÚNICO passo restante para a TAG `v11.0` (amanhã ≥ 2026-06-20 17:51:44, qualquer máquina):**
> ```
> bash scripts/check-soak.sh v11-arsenal --record
> git add .planning/soak/v11-arsenal.log && git commit -m "chore(soak): heartbeat +1d v11-arsenal" && git push
> bash scripts/check-soak.sh v11-arsenal     # exit 0
> git tag v11.0 && git push origin v11.0
> ```
> **Nada de código pendente.** O 1º heartbeat ancora a janela em 06-19 17:51:44; o gate só vira verde com um heartbeat ≥ 06-20 17:51:44 (o `≥1d` é delta entre gravações, NÃO wall-clock — esperar não basta, tem que RE-gravar). Sem bypass (`SOAK_MIN_DAYS=0` trairia o gate integridade-first). Metodologia: design por painel (`wf_449a5952`) + verificação adversarial 5-lentes (`wf_99173505`). Tracker: `.planning/milestones/v11-arsenal-absorption-PLAN.md`. ⚠️ Pausar autosync antes de cirurgia git (`scripts/autosync-pause.sh on/off`).

---

> **▶ RETOMAR AQUI (sessão anterior, HISTÓRICO) — leia primeiro:** validação de resíduos um-a-um **COMPLETA (5/5)**. Itens 1–4 fechados (verify-deploy `IN_SYNC` · ENV-04 · Mac mini baixo-risco · nfideia spec → PR [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40)). **Item 5 (stashes) RESOLVIDO em 2026-06-19:**
> - `nfideia stash@{0}` — confirmado noise (1 linha na seção auto-regenerada "Ultima sessao automatica") → **dropado** (`251593f1`).
> - `ideiapartner stash@{0}` (autostash órfão) — noise + deleção stale de `package-lock.json` (−442, blob mudou desde) → **dropado** (`4e37d1be`).
> - `ideiapartner stash@{1}` (type-safety pass, 2026-06-03) — revisado: 16/20 arq = casts `as TablesUpdate` (inócuos), MAS 4/20 = mudanças schema-coupled NÃO-verificáveis (`useAdminPartners` dropa `approved_at`/renomeia `paid_at`→`pix_paid_at`; `useCSAdvanced` reestrutura insert p/ `metadata`; `useAISystemContext` **conflita** na main atual). Veredito: **NÃO aplicar** (repo Lovable = source-of-truth no cloud; stale 3 sem; conflito). **Arquivado** em `~/dev/ideiapartner/.stash-archive/type-safety-pass-cursor-2026-06-03.patch` (24 KB, git-excluded via `.git/info/exclude`) e **dropado** (`b6975338`). Re-aplicável via `git apply` ou alimentar à Lovable se desejado.
>
> **Não há próximo passo pendente de IA** — todos os 5 resíduos fechados. **Resíduos user-only restantes (sua ação):** (a) mergear/squash PR ideIAos [#4](https://github.com/Ideia-Business/ideIAos/pull/4) (work→main, v6→v10; 121 dos 413 commits são autosync → squash recomendado); (b) mergear [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (Lovable-safe, doc-only). ⚠️ Lembrete p/ futura cirurgia git multi-repo: pausar autosync antes (`launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync`) e religar (`bootstrap … ~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`).

> **ATUALIZAÇÃO 2026-06-18 (fechamento) — leia primeiro:** a contenção `deny=19` descrita mais abaixo como "uncommitted em nfideia/cfoai" **REGREDIU e foi RE-REMEDIADA p/ 5/5 PERSISTIDO** (nfideia `e43f35f5` + cfoai `cdfa8d6` na `work`; ideiapartner `settings.local.json`) — ver §Sessão 2026-06-18 (2ª onda). Novo **check 7e** no `idea-doctor` previne nova regressão. **PR [#3](https://github.com/Ideia-Business/ideIAos/pull/3) MERGEADO** (mac-mini, 2026-06-19). **Sessão 2026-06-19 (validação de resíduos um-a-um):** ✅ item 1 `/lovable-mcp verify-deploy` e2e RODADO contra nfideia → `IN_SYNC` (Fase A validada end-to-end); ✅ ENV-04 (OpenRouter) FECHADO (decisão do usuário); ✅ Mac mini FECHADO como baixo-risco (git-synced confirmado; rodar `ideiaos-update.sh` no mini quando for usá-lo); ✅ nfideia spec PR RESOLVIDO — specs do piloto portadas p/ main via PR limpo [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (cherry-pick doc-only, 6 arquivos em `specs/`, fix nfse já estava na main, branch stale não arrastada; autosync pausado/religado). **Resíduos user-only restantes:** mergear [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (Lovable-safe) · revisar stashes (ideiapartner `stash@{1}` = type-safety real). ENV-06 = desconsiderado (Ideia Chat é teste). O texto v10 abaixo segue como contexto histórico.

**🔵 ATUAL (2026-06-18) — Integração Lovable MCP v10: Fase A (v1 read-only) SHIPPED.** A camada de verificação read-only foi construída e verificada. **Entregue:** skill `/lovable-mcp` (`source/skills/lovable-mcp/SKILL.md`) com 2 verbos read-only — `verify-deploy` (deploy-drift cruzando o commit da Cloud com `origin/main`) e `detect-hotfix` (edições do chat Lovable ausentes no Git); helper `source/lib/lovable-mcp.sh` (gateado por `gates.sh`, verdicts binários, **testado em sandbox git** + parser de escopo); resolver de escopo identity-aware (2 tiers `todos`/`pessoal`, override `lovable-scope.yaml`); **harness-deny de 19 tools mutantes** (+ `query_database` em deny PURO) no `.claude/settings.json` + `disabledMcpServers`; rule `source/rules/lovable/mcp-protocol.md` (doutrina: contenção, @devops, dois-escritores, fronteira MCP×GitHub); empacotamento completo (`build-plugins.sh` LOVABLE_SKILLS + `build_lovable()` cp da rule, `modules.json`, `plugin-membership.md`, `README.md`) e cross-link no `/lovable-handoff`. **Gates verdes** (membership 0 deriva, readme-sync 116/116, build OK). **Verificação adversarial de 4 lentes (workflow `wf_e0d15139-74a`)**: deny-completeness CLEAN, read-only-integrity CLEAN, helper + packaging com achados — todos **corrigidos** (parser awk: dash coluna-0 e `#` entre aspas; exit-codes normalizados; shallow-clone com aviso; contagem README 46). R10-01..05 = DONE.

**Rollout operacional Fase A — lado-AGENTE feito (2026-06-18); ⏳ só faltam 2 ações do USUÁRIO no painel.**

✅ **Feito (agente):** harness-deny das 19 tools mutantes + `query_database` deny PURO + `disabledMcpServers` aplicado e **validado por checagem binária** (`deny=19`, `disabled=True`) no `.claude/settings.json` dos **4 produtos Lovable**: nfideia, ideiapartner, cfoai-grupori, lapidai (ideia-chat ficou de fora — sem `.lovable/`). `language` preservado em cada um. Persistência por design: **ideiapartner** = gitignored (local-only); **lapidai** (branch `work`) = autosync commita+pusha pra `origin/work`; **nfideia + cfoai** = tracked-on-main, deixados **uncommitted** (autosync protege main dirty; não commitei em main Lovable — regra `feedback-lovable-projects-branch-commit`). Fonte-de-verdade para reaplicar = snippet canônico em `source/rules/lovable/mcp-protocol.md`.

✅ **Toggles de painel FEITOS (2026-06-18)** — o usuário deixou apenas **Grupo Ideia - Dev** (`2NHPnABxF0jdSX3qVLCw`) no alcance, satisfazendo o Gate 3 da Fase B (os outros workspaces — Grupo IDeia - Projects `A0gwgrenO8S5IrZtE4ig` e Dev's Lovable `pyHOQY0YDL838zK8GbR3` — fora do alcance).

✅ **Resíduo FECHADO (2026-06-19):** `/lovable-mcp verify-deploy` rodado contra nfideia real → verdict binário **`IN_SYNC`** (`latest_commit_sha=3921f440a44eed620de6e60d3832f5c16f1022b8` == `origin/main`); escopo `in:todos`; só tools read-only; repo não-shallow. Fase A validada end-to-end.
   _(ids dos workspaces confirmados ao vivo via `get_me`/`list_workspaces` em 2026-06-18.)_

**Fase B (sandbox) — CONCLUÍDA 2026-06-18 — veredito 🔴 BLOQUEAR `publish` via MCP** (contexto do plano original, mantido como histórico): plano GSD escrito e verificado adversarialmente (3 lentes) em `.planning/milestones/v10-phases/B-sandbox/B-01-PLAN.md`. Experimento: `remix_project` de 1 produto pouco ativo (cfoai) → fork descartável na workspace dev → mede (A1) namespace/timing do mirror GitHub↔Cloud, (A2) se `deploy_project` lê de `main` ou do estado interno, (A3) se `commit_sha` do `list_edits` casa com `git log`. Gate de TODO write-path; C/D dependem de B. **Resultado abaixo + `.planning/v10-MILESTONE-AUDIT.md`.**

🟡 **Metade read-only da Fase B EXECUTADA (2026-06-18, zero crédito):** medido em nfideia real (`list_edits` × `git log origin/main` local) — **A1-namespace = ACOPLADO** (commit_sha da Cloud É o SHA do GitHub) + **A3 = PASS** (detect-hotfix no namespace certo); mirror **bidirecional** confirmado (commit `ai_update` `76e9cee5` do agente Cloud presente em `origin/main`). Ver `B-01-SUMMARY.md` + dossiê §2.5b. Isso retira 2 dos 3 riscos de desacoplamento e estreita o experimento de escrita.

✅ **Fase B (sandbox) CONCLUÍDA (2026-06-18) — veredito 🔴 BLOQUEAR `publish` via MCP.** Experimento de escrita rodado ao vivo: janela `deny→ask` aberta (`lovable-window.py open`), fork descartável criado, janela fechada (`close`, assert `deny=19`).

**Como foi:** preflight read-only (saldo 100/0; 5 IDs prod p/ guard) → Gate 3 satisfeito (usuário deixou **1 só workspace** no alcance; 1.622 + Dev's Lovable fora) → `remix_project(cfoai)` **falhou** (Supabase pesado, 0 órfão) → `remix_project(Mornings Day POA, sem DB)` → fork `1d0652c4` → Task 1b: DB isolado (disabled) + **busca de gitsync/repo = vazia**.

**MURO DE VIABILIDADE (achado central):** o MCP da Lovable **não expõe nem gerencia o gitsync GitHub** — nenhum connector "github" (`list_connectors`), zero conexão GitHub (`list_connections`), `get_project` sem URL de repo; o `sha_0` do fork não existe em repo nenhum (`gh search commits`=`[]`), nenhum repo auto-criado, fonte sem repo; `add_connector` está no `deny`. Logo **A1-lag + A2 são inmensuráveis num sandbox MCP** (sem `origin/main` no fork não há divergência a testar) → indeterminado vota **BLOQUEAR** (regra do PLAN). **Pior-caso do A2 REFUTADO** pelo read-only (git pushes `developer_update` entram no Cloud → não é bypass total; risco residual = lag de ingestão).

**Achado de segurança (bônus):** `permissions.deny` é **relido e enforçado mid-session** (o remix só funcionou com a janela aberta; assert pós-close passou) — a contenção do harness vale ao vivo, não só no startup.

**✅ Fork descartável DELETADO pelo usuário (2026-06-18)** — confirmado `get_project`=404 + `list_projects`=0. Zero resíduo do experimento na conta Lovable. (Não há `delete_project` no MCP → deleção é sempre manual no painel.)

**✅ v10 FECHADO em escopo PARCIAL (2026-06-18)** — auditoria de fechamento `.planning/v10-MILESTONE-AUDIT.md` (workflow `wf_4fec3ed7-fc0`, 4 auditores + síntese): veredito BLOQUEAR confirmado SOUND (confiança alta), contenção ÍNTEGRA nos 5 alvos (deny=19), todo o status obsoleto reconciliado. **Tag: `no-tag`** (precedente v2.0..v9.0: tag só em milestone COMPLETO; este fecha parcial). Disposição: R10-01..05 DONE; R10-06 DONE (veredito BLOQUEAR); R10-07/08 PARQUEADAS-GATED.

**Próximos passos do v10 (carried-forward):** (1) **Fases C/D seguem gateadas** até medir A2 **fora do MCP** (gitsync manual na UI do editor num projeto descartável + 1 push divergente + 1 deploy — critério objetivo de reabertura em `v10-MILESTONE-AUDIT.md` §9). (2) **Fase A** não depende de B e está operacional — falta só rodar `/lovable-mcp verify-deploy` num produto real como teste end-to-end (toggles de painel já todos feitos). Detalhe completo: `.planning/v10-MILESTONE-AUDIT.md` + `B-01-SUMMARY.md` + dossiê §2.5b.

_Contexto da formalização (2026-06-17): plano vetado por 9 agentes (workflow `wf_a9c61aa5-2bf`), 4 forks + modelo de acesso fechados via `/grelha`; dossiê `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json`), ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md`._

---

**✅ MILESTONE v9 (Camada de Alinhamento) SHIPPED — 2026-06-17, tag `v9.0`.**

Execução autônoma multi-agente (6 fases A–F, builders + painéis de revisão 3-lentes por fase). Entregue:
- `/grelha` (alias `/grill`) — grilling colaborativo pré-plano + glossário `CONTEXT.md` (R9-01/02)
- rule `ubiquitous-language` (distinção dos 3 CONTEXT) + ADR inline `ADR-FORMAT` (R9-02/03)
- Passo 1.5 (gate de alinhamento opcional/escapável) na Deia (R9-04)
- `/improve-architecture` (`/aprofundar`) — ritual de deepening Ousterhout (R9-05)
- empacotamento + propagação + ADR de postura (R9-06/07); auditoria `.planning/v9-MILESTONE-AUDIT.md` **PASSED**; dogfood `/doubt` sobre o diff = **SHIP** (zero fabricação). Inclui fix de precisão do scanner (`scan-absorbed.sh` Check-2 fence-aware, com control test).

**Fechamento operacional — TODAS as pendências do ship resolvidas (2026-06-17):**
- ✅ `work` = `origin/work` (commit `122da91` + agora o commit da Fase G).
- ✅ **tag `v9.0` empurrada** para `origin` (`9b51679`).
- ✅ branch `planning` sincronizado com os docs de milestone v9 via git plumbing (memory store `.planning/memory/` preservado intacto).
- ✅ LOW do dogfood resolvido — README esclarece que `scan-absorbed.sh` mira a quarentena, não `source/`.
- ✅ **Fase G (could-haves) entregue** — deltas `to-prd` (@pm) + nota de seam (`/gsd-debug`) viraram **Patches 14/15** do overlay (`install-global-patches.sh`); aplicados na cópia instalada (repo `.aiox-core` pristine); contagem "15 patches" sincronizada em script/README/doctor; idea-doctor Patch 14✓/15✓ (0 FAIL). Ver `v9-phases/G-could-haves/G-01-SUMMARY.md`.
- ✅ **Hardening de verificação** — `scripts/validate-agent-yaml.sh` (parser autoritativo js-yaml→ruby→python) wired no `idea-doctor` (gate) + Patch 14 (auto-validação + rollback). Fechou o gap "PyYAML ausente ≠ não dá pra verificar".
- ✅ **`main` reconciliada** com `work` por fast-forward (commit `20b4033`) — `main`=`work`=`origin`, divergência 0/0 (IdeiaOS vai direto na main, sem PR).
- ✅ **Aprendizado extraído + encerramento** — `docs/learnings/2026-06-17-git-plumbing-partial-branch-overlay-sync.md` (global → memória + vault); 3 memórias novas (git-plumbing, parser-autoritativo, aiox-core-pristine); Changelog do vault Obsidian atualizado para v9.

Nada bloqueia o repo. `main`=`work`=`origin`=`20b4033` (+ commits desta sessão de fechamento). Próximo: novas demandas.

---

_v2.0–v8 todos SHIPPED._ v8 (Camada de Disciplina) fechado em 2026-06-16 — 4 waves, auditoria PASSED, tag `v8.0`. Absorção de `addyosmani/agent-skills` (MIT): `/doubt` (doubt-driven) + rule sempre-on `operating-discipline` (6 condutas) + `/context-engineering` + convenção de autoria anti-racionalização + opt-in `/observability`/`/deprecation-migration`. **Dogfood:** doubt-driven rodado sobre o próprio diff achou e corrigiu citação fabricada no `/doubt`. Detalhes em `.planning/v8-MILESTONE-AUDIT.md`.

**R8-09 FECHADO (2026-06-16):** `build-adapters.sh build_claude_project_rules()` deploya `source/rules/common/*.md` → `<projeto>/.claude/rules/ideiaos-common-*.md` (paridade Claude×Cursor; Claude auto-carrega `.claude/rules/`). Verificado em sandbox `/tmp` + dogfoodado no repo (manual `operating-discipline.md` → gerado). **Sem pendências do v8.**

**Executável quando houver demanda:** (1) ✅ higiene memória Claude **RESOLVIDA 2026-06-18** (era falso-positivo de fixture; `idea-doctor` 0 FAIL; Jarvis ausente de `~/dev`); (2) backlog passivo v7 — `nfideia:spec/multi-tenancy-pilot` (2 specs + `PILOT-BACKLOG.md`); (3) monitorar `gsd-browser` upstream; (4) DeepSeek V4 Pro nos **produtos** (decisão adiada); (5) `ideiaos-update.sh` no Mac mini.

---
_Histórico v7 abaixo:_

**v2.0–v7 todos SHIPPED.** v7 fechado em 2026-06-16 (4 fases entregáveis, auditoria PASSED, tag `v7.0`). Nada bloqueia o repo. Detalhes em `.planning/v7-MILESTONE-AUDIT.md`.

- **Fase 1** — piloto `/spec` no nfideia: spec viva `specs/multi-tenancy/spec.md` (6 reqs do comportamento real) + ciclo de delta completo. 2 bugs do `spec-merge.sh` corrigidos (`mkdir -p _archive`; splice do ADICIONADO dentro de `## Requisitos`) + suite **27/27**. Gap de empacotamento fechado (`spec`/`forge-agent`/`memory-sync` no `CORE_SKILLS`).
- **Fase 1b** — artefatos do nfideia na branch **`spec/multi-tenancy-pilot`** e **pushada** (`origin/spec/multi-tenancy-pilot`); main intacta (Lovable-safe).
- **Fase 2** — **drift-guard** `scripts/check-plugin-membership.sh`: cruza `plugin:` do manifesto × arrays do `build-plugins.sh`; wired no pre-commit + idea-doctor (seção 10). Pegou `memory-import`/`export` (v5) → marcados `plugin:null` (patch-installed). 69 módulos, 0 deriva.
- **Fase 3** — rollout: 2ª capability `nfideia/specs/cofre-digital/spec.md` (RN-050..053) na mesma branch (`ffc48c9c`).

**Resta (Fase 4 — backlog passivo, NÃO bloqueante — nada depende de ação do usuário):**
1. **gsd-browser** — monitorar upstream (ainda não publicado no npm/crates); avaliar quando sair.
2. **agent-inbox** — uso sob demanda (só se uma tarefa precisar testar auth-email num produto).
3. **nfideia** (branch `spec/multi-tenancy-pilot`): 2 specs vivas + **`specs/PILOT-BACKLOG.md`** com as tasks de Storage tenant isolation prontas para rodar via GSD/@dev (o `.planning/` do nfideia é gitignored, por isso o backlog mora em `specs/`). Pronta para PR/merge.

> **DeepSeek removido do plano (2026-06-16):** decisão do usuário — habilitado no nível dos **produtos**, fora do escopo IdeiaOS.

> **Lição de segurança:** nfideia É Lovable (`lovable-tagger` + `componentTagger` no vite.config) — cuidar só dos projetos Lovable; IdeiaOS não é Lovable (commit livre). Memória: `feedback-lovable-projects-branch-commit`.

## Ultima sessao automatica (2026-07-02)

- Sessão salva em: `/home/lucas/.claude/sessions/2026-07-02-ideiaos-218590cf-025d-4f86-8da1-37d4884d.tmp`
- Próximo passo: (definir antes de retomar)
