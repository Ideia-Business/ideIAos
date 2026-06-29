# ADR — v16 / R16-03: modelo de identidade & transporte GitHub (híbrido faseado, regime free advisory)

**Status:** **ACEITO 2026-06-29** (decisão do dono). Resolve o R16-03 (BLOCKER-CONDICIONAL #2 do ADR `v15-cockpit-split-plane-control-plane.md`). Fundamentado em análise multi-agente (`wf_1d7ecdf6`, lente de arquitetura de segurança) + probe `gh` por exit-code + confirmação do dono sobre o estado real das contas.
**Não revoga:** a autoridade do v16 (RBAC provado por assinatura O2 + pin local) — esta decisão é sobre **transporte/identidade GitHub**, eixo ortogonal à autoridade. `credential-isolation` permanece regra-piso: nenhum token transita pelo contexto do LLM.
**Relaciona:** ratifica o calcanhar deixado aberto em `v15-cockpit-split-plane-control-plane.md` §"DECISÃO CRÍTICA — conta GitHub COMPARTILHADA vs. contas PESSOAIS".

## Contexto

O Cockpit multi-dev (v16) precisa de um modelo de identidade GitHub. Estado factual (probe `gh` por token admin + confirmação do dono, 2026-06-29):

- A **organização** `Ideia-Business` é plano **FREE** (`plan:free`, 12 seats, `default_repository_permission:write`, 2FA não-obrigatório). O "Pro" mencionado é da **conta pessoal** `desenvolvimento@ideiabusiness.com.br` — plano individual que **NÃO habilita recursos de organização** (branch protection em repos privados, política enforced de FG-PAT, audit-log API).
- A credencial em uso é um **token clássico org-wide** (escopo `repo`+`workflow`+`read:org`) da conta compartilhada `DevIdeiaBusiness` — comprometer **1 máquina** = push em **toda a org**. É o BLOCKER-CONDICIONAL #2.
- **Todos os devs já têm contas próprias autorizadas** por nível de acesso (o dono = `gustavolpaiva`, admin). O 2º dev real (`lucas-abreu56`, não-admin) já está ativo.
- A **autoridade real nunca esteve no GitHub**: o RBAC do v16 é provado por assinatura O2 + pin local (19/19 proof-gates). O GitHub é só canal de transporte (push/PR/workflow do autosync). Logo R16-03 afeta apenas 3 eixos secundários: **blast-radius do push-token, atribuição de commit, custo operacional**.

## Decisão

**Opção C (híbrido), faseada, em regime FREE (governança advisory).**

1. **Automação** (autosync/CI/Lovable) → **service account** `DevIdeiaBusiness` formalizada como bot, autenticando por **FG-PAT escopado por-máquina** (não mais o token clássico org-wide). `actor_class=bot` (já modelado no read-model).
2. **Ação humana interativa** → **contas pessoais** de cada dev (já autorizadas por-repo). Commit de pessoa = conta real; commit de daemon = service account.
3. **Regime FREE / advisory** (escolha do dono): a org permanece free. Sem hard-gate de organização — a política de FG-PAT é por-**convenção**, branch protection só em repos públicos, sem audit-log API.
4. **2FA obrigatório: ADIADO** (escolha do dono) — reavaliar quando houver mais devs.

## Alternativas consideradas

- **A — FG-PAT mantendo conta compartilhada como autora:** descartada como destino — mantém a poluição de autoria (tudo é `DevIdeiaBusiness`) e não separa humano de bot. (Seu passo de FG-PAT-bot é absorvido por C, no eixo automação.)
- **B — contas pessoais puras (inclusive autosync):** descartada — forçaria reconfigurar autosync/CI/Lovable por máquina agora e lidar com o dev que sai quebrando o caminho automatizado provado. Atribuir ao humano um commit que o daemon fez é semanticamente incorreto.

## Consequências

**Ganhos (imediatos, sem custo de plano):**
- Aposentar o token clássico org-wide corta o pior vetor: 1 máquina comprometida deixa de dar push em toda a org. Blast-radius cai de **org-wide → por-repo** (escopo do FG-PAT daquele dev/máquina).
- Atribuição honesta: humano-vs-bot distinguível na origem (`actor_class`), resolvendo a poluição de autoria da conta compartilhada.
- Reversão isolada: revogar 1 dev = remover do repo / revogar o FG-PAT daquela máquina — sem rotação global.

**Limites assumidos conscientemente (regime free — honestidade estrutural):**
- O escopo do FG-PAT é **disciplina, não garantia enforced** (sem política centralizada de FG-PAT, que exige org Team). Um dev pode, por engano, emitir um PAT mais amplo.
- **Sem hard-gate de branch protection em repos privados** → a fila de Publish (R16-05) permanece **advisory cooperativa**, nunca hard-gate no GitHub (já era a conclusão da Fase B do v10; agora confirmada pela escolha de plano).
- **Audit-log API indisponível** (R16-06 segue parqueado) → o cross-check telemetria↔audit-log fica best-effort, sem a fonte nativa do GitHub.
- **2FA não-obrigatório** → a conta pessoal do dev é o elo mais fraco (phishing/credential-stuffing); risco aceito pelo dono por ora. Mitigação parcial: a autoridade de comando real está no pin O2 local, não na conta GitHub.

Estes limites **não comprometem a autoridade** (sempre local/O2). Comprometer o transporte GitHub rende, no pior caso, push indevido em repos de código — não capacidade de assinar/pinar/comandar a frota.

## Implementação (runbook — execução do dono; tokens NUNCA pelo contexto do agente)

> `credential-isolation`: o **valor** de qualquer token é manuseado só pelo dono, fora do contexto do LLM. O agente referencia por nome, nunca por valor.

**Fase imediata (aposentar o org-wide):**
1. No GitHub (conta `DevIdeiaBusiness`, Settings → Developer settings → **Fine-grained tokens**): emitir 1 FG-PAT por-máquina, escopo = só os repos que aquela máquina sincroniza, permissões mínimas (Contents: RW, Workflows: RW se necessário). Expiração curta + renovação.
2. Em cada máquina: `gh auth login --with-token` (ou configurar o credential helper do git-autosync) com o FG-PAT daquela máquina. NÃO commitar o valor em lugar algum.
3. **Revogar** o token clássico org-wide (Settings → Personal access tokens (classic) → revoke) só **depois** de validar que o autosync de todas as máquinas funciona com os FG-PATs.
4. Validar por exit-code: o FG-PAT de uma máquina escopada a `{repoA}` NÃO consegue push em `{repoB}` (teste negativo do blast-radius).

**Fase humana (já habilitável — contas pessoais autorizadas):**
5. Devs usam suas contas pessoais para ação interativa (PRs, commits manuais). A service account fica reservada à automação.

**Futuro (gated em necessidade — reabrir este ADR):**
6. Migrar a org para **Team** se/quando for preciso enforcement HARD (branch protection privado + política de FG-PAT enforced + caminho a audit-log). Ligar **2FA obrigatório** (free) quando o nº de devs justificar o atrito de onboarding.

## Rastreabilidade

- Calcanhar: `docs/decisions/v15-cockpit-split-plane-control-plane.md` §"DECISÃO CRÍTICA conta compartilhada vs pessoais" + BLOCKER-CONDICIONAL #2.
- Requisito: `.planning/milestones/v16-REQUIREMENTS.md` R16-03.
- Análise: workflow `wf_1d7ecdf6` (lente arquitetura de segurança, 3 opções × 5 eixos) + probe `gh`.
- Invariante preservado: `credential-isolation` (rule), RBAC-por-assinatura (`specs/cockpit/spec.md` linha 157).
