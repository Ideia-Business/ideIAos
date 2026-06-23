---
name: antitheater-gate-blind-spot-happy-path
description: Um gate anti-teatro verde pode esconder bypass CRÍTICO se todo caso negativo alimenta input VÁLIDO ao 1º check e só trip downstream — exercite input INVÁLIDO em CADA check + mutação-teste
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a6ecbb78-45bd-4705-807c-27b430912bf8
---

Um **gate anti-teatro** (manifesto fixo + REASON por veneno + canário + gate-negativo) estava
**verde 34/34** e MESMO ASSIM um bypass **CRÍTICO** sobreviveu: `stepup-verify-token.sh` (v14.4 F0a)
aceitava QUALQUER token forjado com `exit 0`. Achado só na verificação adversarial independente
(workflow 4-lentes), não pelo gate verde nem por self-review.

**Duas causas que se compõem:**

1. **Blind-spot estrutural do gate:** TODO caso negativo do B4 alimentava um token com **assinatura
   VÁLIDA** e tripava só em checks DOWNSTREAM (expiry/binding/nonce). O 1º check (assinatura-de-máquina)
   **nunca foi exercido com input INVÁLIDO** → o caminho quebrado era invisível. Um gate que varia só os
   campos POSTERIORES, sempre passando input feliz ao check de segurança, **não consegue** detectar que
   o próprio check está bypassado. O canário testa o COMPARADOR, não cada mecanismo.

2. **A armadilha bash `! cmd` + `$?`:** `if ! bash verify ...; then rc=$?; exit "$rc"; fi` — após um
   `!`-negado, `$?` é **SEMPRE 0**. Então toda falha de assinatura virava `exit 0` (aceita). O fix é
   capturar o rc do comando PLANO antes de ramificar: `bash verify ...; rc=$?; if [ "$rc" -ne 0 ]; then
   exit "$rc"; fi`.

**Why:** verde de gate ≠ ausência de bug. Cobertura por exit-code é forte, mas só do que o caso
realmente EXERCITA. Um fail-closed chain tem N checks; se o teste sempre passa pelo check k com input
bom, o check k pode estar quebrado sem nenhum caso vermelho.

**How to apply:**
- Para CADA check de uma cadeia fail-closed, adicione um caso que alimente input INVÁLIDO **àquele
  check específico** (não só downstream). Ex.: feed sig-forjada / chave-não-pinada / sig-vazia ao
  verificador e exija o exit-code específico (3/4/6), não um `!=0` genérico.
- **Mutação-teste o gate:** sabote cada check (always-pass / neutralize) e prove que o gate VIRA
  VERMELHO. Se uma sabotagem sobrevive verde → o gate é teatro naquele eixo. Restaure com garantia.
- Nunca leia `$?` depois de `! cmd` (nem depois de pipeline/compound). Ver [[learning-dogfood-review-tool-catches-own-defect]],
  [[learning-review-own-design-before-build-with-refutation]], rule `antifragile-gates`.
- Rode a verificação adversarial **independente** (contexto fresco, lente que tenta REFUTAR) — ela
  pega o que self-review e gate-verde perdem.
