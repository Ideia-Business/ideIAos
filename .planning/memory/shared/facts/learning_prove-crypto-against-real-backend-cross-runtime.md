---
name: prove-crypto-against-real-backend-cross-runtime
description: "Assinatura cross-runtime (Deno↔Node etc.) — prove a cadeia contra o backend REAL deployado, não contra um fixture da sua própria stack; o risco é a canonicalização divergir 1 byte, não a primitiva"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a6ecbb78-45bd-4705-807c-27b430912bf8
---

Quando uma assinatura é **produzida numa runtime** (ex.: Deno/edge) e **verificada em outra** (ex.: Node/bash),
e ambas precisam concordar numa **serialização canônica** (JSON ordenado, encoding) sobre a qual a assinatura
é computada, o risco real **não** é a primitiva (Ed25519 é Ed25519) — é a **canonicalização divergir 1 byte**
entre as duas implementações.

**Why:** um gate que assina com um fixture **da mesma stack do verificador** (Node↔Node) prova só que o
verificador é consistente consigo mesmo; **não** prova interoperabilidade com o assinante REAL (Deno). Esse é
o byte-idêntico fora do gate — passa verde, pode falhar (ou mascarar drift) em produção.

**How to apply:**
- Um caso de prova de aceitação **DEVE usar o assinante real deployado**, não um fixture da stack do
  verificador. O fixture serve ao loop rápido; o critério de "feito" é o ciclo `assina(runtime A) →
  verifica(runtime B)` contra o backend real.
- Toda reimplementação de `canonicalize` (por runtime) é a MESMA especificação — teste-as **uma contra a
  outra**, nunca cada uma consigo mesma.
- Falso-positivo: se assinante e verificador compartilham a mesma implementação/runtime, o fixture já é
  representativo e a prova cross-real é redundante. O risco só existe com **duas** implementações que precisam
  concordar.

Origem: v14.4 F0b (step-up) — gate 47/47 Node↔Node verde, mas a interoperabilidade Deno→Node só foi provada
ao chamar o `verify-otp` real e verificar o comprovante contra a pubkey pinada (exit 0). Cross-link
[[antitheater-gate-blind-spot-happy-path]] (mesmo eixo: gate verde ≠ provado), [[stepup-backend-provisioned]].
