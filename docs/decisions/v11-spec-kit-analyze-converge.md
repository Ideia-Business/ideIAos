# ADR v11 — /spec --analyze + --converge: minerar prompts, não importar premissa greenfield

**Status:** Aceito (2026-06-19)
**Contexto:** milestone v11 W4 (análise `docs/research/2026-06-19-arsenal-analysis/`; design-panel `wf_449a5952`; verificação adversarial `wf_99173505`).
**Relacionado:** rule `delta-spec.md` · skill `/spec` · [[v11-license-provenance-quarantine]].

## Contexto

`github/spec-kit` (MIT) propõe spec-driven development com gates de qualidade de spec.
A tentação seria importá-lo como camada. Mas spec-kit assume **greenfield** (spec
PRECEDE o código, projeto novo), enquanto o `/spec` do IdeiaOS é **delta-spec brownfield**
(o produto já existe; a spec é um contrato VIVO que evolui por delta). Importar a
premissa greenfield colidiria com a fronteira /spec×GSD já estabelecida (R6-13).

## Decisão

**Minerar os PADRÕES de spec-kit, não a premissa.** O delta de valor real do spec-kit
para o IdeiaOS é a ideia de **gatear a qualidade da spec de forma determinística** — não
o seu fluxo greenfield. Realizamos isso como **dois subcomandos da skill `/spec`
existente** (NÃO skills novas — disciplina da revisão NASA):

- **`--analyze`**: gate determinístico da spec VIVA (pós-merge), complementando — não
  duplicando — o `spec-validate.sh` (que só vê o delta pré-merge). Núcleo HARD (A1 req
  sem cenário, A2 cenário em nível errado, A3 header duplicado, A4 token de delta vazado)
  + camada ADVISORY (A5 cross-ref de path + passes LLM). **Determinístico pode bloquear;
  LLM/heurística só aconselha** (guard-rail NASA).
- **`--converge`**: ponte **append-only** spec↔código — gera delta-candidato numa
  quarentena que reentra no fluxo normal `/spec`, sem nunca mutar a source-of-truth
  (garantia sha256 before/after + rollback).

**Reuso sem deriva:** a gramática das specs foi extraída para `spec-grammar.sh` (ponto
único de verdade), consumida pelos clientes novos — sem duplicar a convenção que já vivia
em validate/merge (learning declarative-vs-imperative-drift). Os gates existentes NÃO
foram refatorados (escopo/risco); a lib nasce desenhada para unificação trivial futura.

## Alternativas rejeitadas

- **Importar spec-kit como camada/skill nova.** Rejeitado: traz premissa greenfield que
  colide com o brownfield delta-spec; viola a disciplina "subcomandos/edições, não skills novas".
- **Fazer `--analyze` reusar o LLM como gate.** Rejeitado: passes LLM são falíveis; gatear
  bloquearia specs válidas por estilo. LLM = ADVISORY (guard-rail NASA #).
- **`--converge` aplicar o delta automaticamente.** Rejeitado: mutar a source-of-truth por
  inferência é irreversível e arriscado; append-only + revisão humana + `spec-validate` (o
  gate real) preservam a integridade do contrato.
- **Cross-ref de path (A5) como HARD.** Rejeitado: specs brownfield citam paths legitimamente
  ausentes (planejados, monorepo, ilustrativos) — gatear daria falso-positivo em massa. ADVISORY.

## Consequências

- **Positivo:** o IdeiaOS ganha um gate de integridade de contrato sem inchar o arsenal
  (2 subcomandos, não skills novas); a spec viva tem auditoria determinística; o `--converge`
  fecha o loop spec↔código com segurança append-only provada por teste.
- **Custo:** mais uma lib de gramática a manter (mitigado: é o ponto único de verdade, reduz
  duplicação líquida). Fixture-regression `tests/spec-analyze.bats` (18 asserts) protege contra
  regressão; agora roda no CI + SOAK (e fechou o órfão `spec-merge.bats`).
- **Verificação:** design por painel de 3 + juiz; implementação verificada adversarialmente
  por 5 lentes (parser-fidelity, FP, FN, append-only, exit/CI) — ver `wf_99173505`.
