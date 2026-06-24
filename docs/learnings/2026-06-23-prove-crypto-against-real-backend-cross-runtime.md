---
date: 2026-06-23
session_type: feature
incident: n/a
commit: aab9a12
tags: [crypto, canonicalization, cross-runtime, signing, verification, fixtures, e2e]
applies_to_projects: [global]
promote_to_vault: true
---

# Assinatura cross-runtime: prove a cadeia contra o backend REAL, não contra um fixture da sua própria stack

## Trigger (quando reler isso)

Há uma assinatura/verificação onde o **assinante** roda numa runtime (ex.: Deno/edge) e o **verificador**
em outra (ex.: Node/bash), e seu gate de testes usa um **assinante-fixture na mesma stack do verificador**.
Antes de declarar "provado".

## O padrão (abstrato)

Quando assinante e verificador rodam em runtimes/linguagens diferentes mas precisam concordar numa
**serialização canônica** (JSON ordenado, encoding, normalização) sobre a qual a assinatura é computada,
o risco real **não** é a primitiva criptográfica (Ed25519 é Ed25519) — é a canonicalização divergir 1 byte
entre as duas implementações. Um gate que assina com um fixture **da mesma stack do verificador** prova que
o verificador é consistente *consigo mesmo*, mas **não** prova interoperabilidade com o assinante real. Esse
é o byte-idêntico não-coberto: passa no gate, falha em produção (ou pior, passa por acidente e mascara drift).

## Evidência (concreta — desta sessão)

- Feature: v14.4 F0b (backend step-up). Commit `aab9a12`.
- Gate (F0a) assinava o comprovante com um fixture **Node** (`tests/writepath/lib/fake-stepup-backend.mjs`),
  verificado por `source/agentd/stepup-verify-comprovante.mjs` (Node) — Node↔Node, 47/47 verde.
- Backend real é **Deno** (`source/agentd/stepup/supabase/functions/verify-otp/index.ts`), com canonicalize
  reimplementado. A interoperabilidade Deno→Node era o risco fora do gate.
- Prova real: deploy do backend → `verify-otp` real devolveu comprovante assinado → `stepup-verify-comprovante.mjs`
  verificou contra a pubkey pinada → **exit 0** (jti emitido). Binding A≠B→exit 7, single-use→400. Provado 2×:
  via INSERT de OTP de teste e via OTP entregue por e-mail real.

## Regra prática derivada

1. Quando a cadeia de assinatura cruza runtimes, **um caso de prova DEVE usar o assinante real** (deployado),
   não um fixture da stack do verificador. O fixture serve para o loop rápido; a prova de aceitação é contra o real.
2. Mantenha a função de canonicalização **byte-idêntica e centralizada conceitualmente**; documente que cada
   reimplementação (por runtime) é a mesma especificação, e teste-as **uma contra a outra**, não cada uma consigo.
3. Trate o ciclo `assina(runtime A) → verifica(runtime B)` como o critério de "feito", mesmo que o gate de
   unidade já esteja verde com fixtures.

## Falsos positivos

- Se assinante e verificador compartilham a **mesma** implementação de canonicalização (mesmo módulo, mesma
  runtime), o fixture já é representativo e o teste cross-real é redundante. O risco só existe quando há
  **duas** implementações que precisam concordar.

## Cross-references

- Memória de projeto: `project_stepup-backend-provisioned.md`
- Doutrina: `credential-isolation` (a signing key privada foi gerada local, isolada em `/tmp` 0600 e setada por
  referência — nunca no contexto), `antifragile-gates`.
