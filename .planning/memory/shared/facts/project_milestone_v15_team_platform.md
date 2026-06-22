---
name: project-milestone-v15-team-platform
description: "v15 re-escopo do Cockpit de read-fan-out para PLATAFORMA DE TIME controlada (multi-dev hospedada); decisões de arquitetura, GitHub e deploy"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4ccbd936-70a0-46eb-ba25-4466087d60d1
---

**v15 "IdeiaOS Cockpit → Plataforma de Time Controlada"** — re-escopo decidido 2026-06-22 (sessão de design multi-agente). O Cockpit deixa de ser console local-first de 1 operador e vira **plataforma de time multi-dev hospedada em `cockpit.ideiabusiness.com.br`**, sem o CTO/TechLead perderem controle. Princípio-âncora do operador: **"delegar o TRABALHO sem delegar o CONTROLE."**

**Arquitetura (split-plane preservado):** autoridade+segredo LOCAIS (planos P0-P2: chave O2, lista pinada autoritativa-local, valor de segredo NUNCA vão ao cloud); só VIEW+identidade+coordenação remotas (P3 Supabase dedicado `xdikjgpkiqzgebcjgqmu` "IdeiaOS - Cockpit"; P4 step-up dedicado SEPARADO; P5 UI web). O painel rejeitou o "control plane pleno" como super-construção; venceu read-fan-out (Operability-first), agora APLICADO a multi-dev.

**5 alavancas de controle (todas dos admins CTO+TechLead):** Admissão (estação gera hash→PENDENTE→admin aprova = pin O2) · Autorização (RBAC-leitura, `user_project_scope`) · Reserva de poder (rotate/revoke/deploy atrás de step-up+admin; o **clique manual Update→Publish da Lovable é interceptado como verbo deploy gated**) · Visão (telemetria por-usuário→Vault) · Reversão (re-pin local, exit 9).

**2 pilares:** A=atribuição por AUTOR-DO-COMMIT (não conta GitHub) · B=cockpit guarda VÍNCULO, máquina guarda VALOR do token (OAuth roda local, `provider_link` sem coluna `value`).

**DECISÃO GitHub (2026-06-22): MANTER conta compartilhada `desenvolvimento@ideiabusiness` + mitigações.** Mitigação reforçada: **token POR-ESTAÇÃO** (fine-grained PAT por estação, escopado aos repos do dev) — "conta compartilhada ≠ token compartilhado" → Reversão isolada/efetiva + blast-radius isolado, sem contas pessoais. Atribuição autoritativa = **telemetria assinada-O2 da estação** (git author email = hint cosmético forjável). Residuais: org precisa habilitar fine-grained PATs; actor no audit-log GitHub é a conta compartilhada (distinção fina é cockpit-side via pat_id).

**Realidade de deploy (4 repos mapeados):** TODOS são Lovable Cloud, NENHUM tem preview-por-branch, deploy=clique humano manual Update→Publish sobre `main`; `main` SEM branch protection (403 Upgrade-to-Pro nos 4). → concern #1 NÃO se resolve por preview-por-branch: o cockpit **serializa o Publish** (fila gated admin+step-up) + **soft-lock de arquivo (R-COORD5)** para colisão de mesmo-arquivo. cfoai+ideiapartner COMPARTILHAM banco Supabase de prod → claim de migrations. lapidai tem risco "Update cinza".

**Camada de Coordenação & Experiência (doc 82, R-COORD1-5):** guia onboarding dinâmico · saúde por-operador (canivete suíço) · quadro de status+"eu pego isto" · marcação de itens de handoff (anti-duplicação) · **anti-colisão de arquivo via soft-lock advisory acima do git** (branch isola código mas NÃO previne mesmo-arquivo). Alimenta plano maior (GSD/.planning) + Vault; futuro orquestrador **DEV Tasks** consome os claims p/ paralelizar sem colidir.

**Faseamento:** F0 step-up P4 (PRÓXIMO TIJOLO, bootstrap B3-HYBRID, NÃO bloqueado) → F1 view+admissão+autorização (gated) → F2 pilares/enrollment → F3 coordenação/claims → F4 reserva-de-poder/Publish gated → F5 Vault+DEV Tasks.

**Segurança (@security-reviewer = NEEDS_REVISION; invariante zero-trust SUSTENTA-SE):** 2 blockers MITIGADOS (atribuição→telemetria assinada; reversão→PAT por-estação). 2 blockers ABERTOS p/ construção: **RLS por-campo** (mascarar nomes `risk_tier=critical`/cadência fora do escopo — cláusulas SHALL, bloqueia F1) e **step-up só-loopback proof-gated** (provar por exit-code que origem≠loopback é RECUSADA no send-otp/O2-sign — única barreira entre sessão-admin-web-roubada=recon vs =deploy-prod). + warns: enrollment remoto anti-MITM ×N; proof-gate Pilar B.

**Artefatos:** `docs/decisions/v15-cockpit-split-plane-control-plane.md` (ADR DRAFT/PROPOSTO), `docs/ideiaos-console/81-team-platform-control-DESIGN.md`, `82-team-coordination-onboarding-requirements.md`, `docs/decisions/v14.4-command-ref-origin-exposure.md` (Q5 PROPOSTO). Liga a [[project-milestone-v14-cockpit]]. Tags v14.0/v14.1 ainda DEFERIDAS (SOAK span≥1d).
