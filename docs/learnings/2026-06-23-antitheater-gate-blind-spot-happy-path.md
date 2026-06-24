---
date: 2026-06-23
session_type: discovery
incident: n/a
commit: ff4c8cc
tags: [testing, anti-theater, fail-closed, bash, security, blind-spot]
applies_to_projects: [global]
promote_to_vault: true
---

# Gate anti-teatro verde pode esconder bypass CRÍTICO quando todo caso negativo só exercita o happy-path do 1º check

## Trigger (quando reler isso)

Você tem um gate de testes "anti-teatro" (manifesto fixo, REASON por veneno, canário) **verde**, sobre
uma cadeia de verificação **fail-closed** (assinatura → expiry → binding → nonce → …), e quer confiar que
o sistema está provado. Especialmente: cadeias onde cada caso negativo varia só os campos *posteriores*.

## O padrão (abstrato)

Um gate de exit-code só prova o que cada caso **realmente exercita**. Numa cadeia fail-closed de N checks,
se **todo** caso negativo alimenta input *válido* ao check k (ex.: assinatura genuína) e só dispara em
checks downstream (expiry/binding/nonce), então o check k **nunca é exercido com input inválido** — e pode
estar completamente bypassado sem nenhum caso vermelho. O verde é real, mas há um **ponto-cego estrutural**.
Verde de gate ≠ ausência de bug; é ausência de bug *no que foi exercitado*.

Caso concreto desta sessão: um verificador de token aceitava **qualquer token forjado** (`exit 0`) por causa
do trap bash `if ! cmd; then rc=$?` (após `!`-negado, `$?` é sempre 0). O gate estava 34/34 verde porque
todos os casos B4 alimentavam um token *legitimamente assinado*, tripando só em expiry/binding/nonce — a
verificação de assinatura quebrada nunca foi exercida com assinatura inválida.

## Evidência (concreta — desta sessão)

- Feature: v14.4 F0a (scaffold step-up). Commit `ff4c8cc`.
- Bug: `source/agentd/stepup-verify-token.sh:37-39` — `if ! bash "$VERIFY_PAYLOAD" ...; then rc=$?; exit "$rc"`
  → `rc=0` em toda falha de assinatura → aceita token forjado.
- Achado por: verificação adversarial independente (workflow 4-lentes), NÃO pelo gate verde nem self-review.
- Fix: `bash "$VERIFY_PAYLOAD" ...; rc=$?; if [ "$rc" -ne 0 ]; then exit "$rc"; fi` + 3 casos B4 negativos
  (sig-forjada→3 / não-pinada→4 / sem-sig→6) que fecham o ponto-cego. Mutação-provado.
- `scripts/test-writepath-bootstrap.sh` — gate passou de 34 a 47 casos; mutação-teste mata 8 sabotagens.

## Regra prática derivada

1. Para **cada** check de uma cadeia fail-closed, escreva um caso que alimente input **inválido àquele check
   específico** (não só downstream), e exija o **exit-code específico** (não um `!=0` genérico — 127/file-not-found
   reprova).
2. **Mutação-teste o gate:** sabote cada check (always-pass / neutralize) e prove que o gate **vira vermelho**.
   Se uma sabotagem sobrevive verde, o gate é teatro naquele eixo. Restaure com garantia (backup + trap).
3. **Nunca leia `$?` depois de `! cmd`** (nem depois de pipeline/compound); capture o rc do comando plano primeiro.
4. Rode uma **verificação adversarial independente** (contexto fresco, lente que tenta *refutar*) antes de
   confiar num gate verde — ela pega o ponto-cego que self-review e verde não pegam.

## Falsos positivos

- Nem todo gate verde tem ponto-cego — a heurística é: *os casos negativos variam só os campos tardios?* Se a
  cobertura já alimenta input inválido a cada check, o verde é confiável. O risco mora em cadeias onde o setup
  do caso sempre produz um artefato válido até o ponto de falha desejado.

## Cross-references

- Memória global: `learning_antitheater-gate-blind-spot-happy-path.md`
- `source/rules/...antifragile-gates` (exit-code é lei) · learnings `dogfood-review-tool-catches-own-defect`,
  `review-own-design-before-build-with-refutation`.
