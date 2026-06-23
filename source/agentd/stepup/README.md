# Step-up backend — `ideiaos-cockpit-stepup` (v14.4 · B3)

Scaffold do fator de presença na origem (HYBRID: email-OTP universal + Touch ID atalho). **F0a** (este
diretório) entregou o código + os proof-gates locais por exit-code, **ZERO segredo / ZERO produção /
ZERO chamada a provedor**. **F0b** (abaixo) é a parte do operador — provisionar e fiar o backend real.

> Decisões: `docs/decisions/v14.4-step-up-without-relying-party.md` (HYBRID) ·
> `docs/decisions/v14.4-stepup-comprovante-key-scheme.md` (chave do comprovante) ·
> `docs/decisions/v14.4-origin-auth-signing-mechanism.md` (O2). Contrato: `specs/cockpit/spec.md` (R-WP3).

## O que F0a já provou (local, exit-code)

`scripts/test-writepath-bootstrap.sh` exercita B0–B4 com fixtures efêmeras em `/tmp`:
- **B0–B2** (já existiam): assinatura por-máquina (`ssh-keygen -Y`), lista pinada autoritativa-local,
  revogação-forjada-via-ref recusada.
- **B3** (novo): o agentd VERIFICA o comprovante Ed25519/WebCrypto contra a pubkey **pinada** ANTES do
  binding (sig-inválida→3, não-pinada→4, hash-divergente→7, expirado→8); o token O2 é assinado só então.
- **B4** (novo): verificação do token O2 fail-closed (expirado→8, nonce-reusado-cross-processo→10,
  binding-divergente→7); gate agregado anti-teatro (manifesto fixo + exit-code/REASON específicos +
  canário + gate-negativo de zero-chamada-a-provedor).

## F0b — STATUS (projeto `IdeiaOS - Cockpit` · ref `xdikjgpkiqzgebcjgqmu`)

Provisionamento parcial executado 2026-06-23:

- ✅ **4 edge functions deployadas** (`--no-verify-jwt`) — ACTIVE; conectividade + CORS loopback provados
  (Origin loopback → 500 sem-schema; Origin estranho → 403).
- ✅ **Secrets setados** `STEPUP_SIGNING_KEY` / `STEPUP_SIGNING_KID` (`eb502ee5408cb7c1`) / `STEPUP_ALLOWED_SUBJECTS`
  (privada gerada local, isolada, **nunca exibida**; só o digest no Supabase).
- ✅ **Pubkey do comprovante PINADA** no agentd (`~/.ideiaos/cockpit/stepup-backend-pubkey`, out-of-band, kid `eb502ee5408cb7c1`).
- ✅ **Transporte real** `transport-curl.sh` (este dir) — integração real client→transporte→backend provada (fail-closed).
- ⏳ **FALTA (você):** (1) aplicar `schema.sql`; (2) `RESEND_API_KEY` (p/ o e-mail do OTP chegar). Sem os dois,
  o fluxo OTP end-to-end não fecha (sem schema → 500; sem Resend → código não é enviado, e o DB guarda só o digest).
- 🔒 Pin por-máquina: a **cerimônia N=2** exige re-pin out-of-band num 2º host físico.

## F0b — passos do operador (gated; abre a feature cross-máquina só com N=2 real)

1. **Provisionar projeto Supabase DEDICADO** `ideiaos-cockpit-stepup` (SERVICE_ROLE isolada, **zero dado
   de produto**). Aplicar `schema.sql`.
2. **Gerar a chave de assinatura do comprovante** (Ed25519, dedicada — **≠ SERVICE_ROLE**):
   ```sh
   node tests/writepath/lib/fake-stepup-backend.mjs gen-keypair   # → {kid, spki_b64, pkcs8_b64}
   ```
   - `pkcs8_b64` → secret da edge function por NOME `STEPUP_SIGNING_KEY` (nunca em log/contexto).
   - `kid` → `STEPUP_SIGNING_KID`. `STEPUP_ALLOWED_SUBJECTS=gustavo@…`. `RESEND_API_KEY`, `STEPUP_MAIL_FROM`.
   - (em produção, gere a chave no ambiente do backend; o helper acima é o caminho de teste.)
3. **Enrollment OUT-OF-BAND da pubkey no agentd** (autoritativo-local, nunca pelo ref):
   ```sh
   bash source/agentd/stepup-pin-backend.sh add <kid> <spki_b64>
   ```
4. **Deploy** das 4 edge functions (`send-otp`, `verify-otp`, `register/check-trusted-device`).
5. **Transporte real** (fora de `source/agentd/*.sh`, p/ manter o gate-negativo airtight): um executável
   apontado por `STEPUP_TRANSPORT`, contrato `"<op> <out-file>"` (op ∈ `send`|`verify`), **body JSON via
   STDIN** (o código OTP nunca toca o disco no cliente), exit 0 + resposta gravada em `<out-file>`. Faz o
   POST loopback→backend. O `stepup-otp-client.sh` o injeta; sem ele = fail-closed.
   - Nota: o backend grava o OTP só como **digest salgado** `sha256(salt:code)` (nunca o código recuperável);
     `verify-otp` compara o digest em tempo-constante.
6. **Cerimônia N=2 real** (enrollment num 2º host físico) + decisão **Q5** (ref ao origin) — só então a
   feature cross-máquina destrava. O verde mono-máquina do F0a **não** as dispensa.

## Mineração do ideiapartner (adaptado, não copiado)

Reusado: RLS deny-all de `otp_codes`, lockout/rate-limit, sanitização, padrão CORS.
**NÃO** reusado: `Math.random` (→ CSPRNG, S-06), `verify-otp` booleano (→ comprovante assinado, S-01),
`signInWithPassword`/roles de produto/`admin_emails` (S-09), domínios de produto na CORS (→ loopback, S-08).
