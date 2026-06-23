---
name: stepup-backend-provisioned
description: Backend step-up v14.4 (Cockpit) PROVISIONADO no Supabase ref xdikjgpkiqzgebcjgqmu — fatos duráveis p/ retomar N=2/feature + gotcha do domínio Resend
metadata: 
  node_type: memory
  type: project
  originSessionId: a6ecbb78-45bd-4705-807c-27b430912bf8
---

O backend dedicado de step-up do Cockpit (v14.4 F0b) está **provisionado e provado end-to-end**
(2026-06-23). Fatos duráveis:

- **Projeto Supabase:** "IdeiaOS - Cockpit", ref **`xdikjgpkiqzgebcjgqmu`** (sa-east-1; dedicado, ≠ NFIdeia).
- **4 edge functions** ACTIVE (`--no-verify-jwt`): `send-otp`, `verify-otp`, `register/check-trusted-device`
  (fonte em `source/agentd/stepup/supabase/functions/`).
- **Secrets:** `STEPUP_SIGNING_KEY` (Ed25519 privada, **kid `eb502ee5408cb7c1`**), `STEPUP_SIGNING_KID`,
  `STEPUP_ALLOWED_SUBJECTS=gustavo@redeideia.com.br`, `RESEND_API_KEY`, `STEPUP_MAIL_FROM`.
- **Pubkey do comprovante PINADA** no agentd: `~/.ideiaos/cockpit/stepup-backend-pubkey` (kid `eb502ee5408cb7c1`),
  out-of-band, **por-máquina** (a Mac mini está pinada; N=2 exige re-pin num 2º host).
- **Remetente Resend:** `cockpit@updates.ideiabusiness.com.br`. **GOTCHA:** o domínio verificado é
  **`updates.`** (inglês), NÃO `atualizações.` (o operador lembra pelo sentido). Resend **rejeita From Unicode**
  (422 non-ASCII); use ASCII/Punycode. Uma key **sending-only NÃO lista domínios** (`GET /domains` exige
  Full-access) — para descobrir o nome canônico, use uma key Full-access temporária. _Lição: verifique o nome
  canônico de recurso externo via API, não confie na memória do usuário (custou várias idas-e-vindas)._
- **Transporte real:** `source/agentd/stepup/transport-curl.sh` (fora de `source/agentd/*.sh`); envs
  `STEPUP_BACKEND_URL=https://xdikjgpkiqzgebcjgqmu.supabase.co/functions/v1`, `STEPUP_ORIGIN`, `STEPUP_ANON_KEY`.

**Pendências (gated, owner):** (1) hardening — a `RESEND_API_KEY` setada é **Full-access** (usada p/ destravar);
trocar por **Sending-only** restrita a `updates.ideiabusiness.com.br` + revogar a Full-access. (2) **cerimônia
N=2** (re-pin out-of-band 2º host) + **Q5** (ref ao origin). **R-WP10 segue FECHADO** até N=2 (mono-máquina não
discharge). Cross-link [[project-milestone-v14-cockpit]], [[learning-credential-isolation]] não-aplicável (signing
key foi gerada local, isolada em /tmp 0600, setada por referência — nunca no contexto).
