# Fase A — "Destravar & Estancar" (Onda 1 do v15) · INDEX

**Milestone:** v15 (DX & Frota) · **Fase:** A · **Status:** 🟢 Wave 1 EXECUTADA 2026-06-25 (A-01..A-06 commitados, verdes por exit-code) · Wave 2 (A-07/A-08) PENDENTE
**Origem:** método-espelho GSD (CLI não resolve fases v15 — mesma razão do v14). Planejado por workflow Ultracode `wf_4e17292d-71b` (8 planners + checker adversarial) + round de revisão `wf_ad95edf7-a07` (5 revisers + re-check). 6/8 `pass` na 1ª passada após revisão; A-04/A-07 fechados por 2 fixes cirúrgicos pós-revisão (checksum `| sort` determinístico; string real do grep — No-Invention).

## Objetivo da fase (goal-backward)

Um dev novo (inclusive Windows nativo) instala, vê por **exit-code** que funcionou, e o painel para de mentir: hooks registrados (não copiados-mortos), `/usr/bin/python3` erradicado, Frota com nomes (não hashes), e o FAIL crônico do cfoai fechado.

## Planos

| Plano | Req | Wave | depends_on | Veredito final | Arquivo |
|-------|-----|------|-----------|----------------|---------|
| A-01 | R15-01 | 1 | — | ✅ pass | `A-01-fix-python3-hooks-PLAN.md` |
| A-02 | R15-03 | 1 | — | ✅ pass | `A-02-smoke-test-PLAN.md` |
| A-03 | R15-04 | 1 | — | ✅ pass | `A-03-setup-resiliente-PLAN.md` |
| A-04 | R15-05 | 1 | — | ✅ pass* | `A-04-corrigir-fatos-PLAN.md` |
| A-05 | R15-07 | 1 | — | ✅ pass | `A-05-alias-map-frota-PLAN.md` |
| A-06 | R15-08 | 1 | — | ✅ pass | `A-06-botao-verificar-PLAN.md` |
| A-07 | R15-02 | 2 | A-01, A-02 | ✅ pass* | `A-07-registro-hooks-bootstrap-PLAN.md` |
| A-08 | R15-06 | 2 | — (decisão dono = **A**) | ✅ pass | `A-08-resolver-fail-cfoai-PLAN.md` |

`*` A-04 e A-07 fecharam após fix cirúrgico pós-revisão (verificado por exit-code).

## Grafo de execução

- **Wave 1 (paralelo, independentes):** A-01, A-02, A-03, A-04, A-05, A-06.
- **Wave 2:** A-07 (depende de A-01 hooks corrigidos + A-02 smoke confirma o registro por exit-code).
- **A-08** (cfoai) — **decisão do dono = A (remediar os 19 deny no prefixo correto), 2026-06-25.** Branch B descartada. O fix prefix-aware do §7e (instrumento de medição) é **incondicional** nos 4 produtos. Pode rodar em qualquer wave.

## Movimento-âncora

**A-01 (R15-01)** — fix `/usr/bin/python3` + re-build. Cirúrgico, validável no macOS por exit-code, **independe do teste do Lucas**. Destrava o resto da fase.

## Resíduos advisory (não-bloqueantes — o executor trata)

- **A-04 (menor):** o texto novo do README sobre o `.aiox-core` NÃO pode introduzir "tracked/versionad" a ≤80 chars de "aiox-core" (o gate de Task 5 reprova) — a redação proposta já usa "PRISTINE"/"ignorado pelo .gitignore", então está coberto; atenção ao redigir.
- **A-07 (advisory):** o backup do `settings.json` feito pelo plano deve usar nome **distinto** do `.bak-hooks` que o próprio registrador (`ideiaos-update.sh:214`) escreve, senão a restauração pode pegar um backup já mutado.

## Invariantes provados nos planos (não-negociáveis na execução)

- **Guard diferenciado (A-01):** hooks de proteção (typecheck-on-edit, console-log-guard) avisam quando python3 ausente E o arquivo é relevante (.ts/.tsx[/.js/.jsx]); para arquivo não-relevante saem 0 em silêncio — **nunca** `exit 0` mudo cego. Gates **negativos** (edit de `.md` sob python3-ausente NÃO avisa) fecham o blind-spot `antitheater-gate-blind-spot-happy-path`.
- **autosync-race:** todo plano com cirurgia multi-arquivo pausa o autosync ANTES (PATH real `$HOME/.local/state/git-autosync.pause`) e verifica o binário DEPLOYADO por grep.
- **No-Invention (Article IV):** cada fato afirmado bate com o código real (verificado por grep — ex.: `.aiox-core` é GITIGNORED/untracked, não "tracked"; a string do registrador é `["command"].rstrip`).
- **Anti-teatro-verde:** cada gate exercita também INPUT INVÁLIDO (checksum-FS determinístico com `| sort`; grep escopado ao bloco novo, não ao arquivo inteiro).

## Próximo passo

`/gsd-execute-phase v15-A` (método-espelho) OU executar plano-a-plano começando por A-01 (Wave 1). **A-08: decisão do dono = A** (remediar os 19 deny) — sem blocker pendente.
