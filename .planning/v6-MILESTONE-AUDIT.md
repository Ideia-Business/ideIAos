# v6 Milestone Audit — IdeiaOS

**Auditor:** integration-audit agent (READ-ONLY)
**Data:** 2026-06-16
**Branch:** work
**Escopo:** Fases 23-31 (9 fases, requisitos R6-01..R6-15)
**Status geral:** `gaps_found` — 14/15 requisitos WIRED, 1 WARNING não-bloqueante; 1 cross-fase GAP real

---

## Resumo Executivo

| Categoria | Resultado |
|-----------|-----------|
| Requisitos verificados | 15/15 |
| WIRED (ponta-a-ponta) | 14/15 |
| PARTIAL / WARNING | 1/15 (R6-07 — ver abaixo) |
| BROKEN / BLOCKER | 0/15 |
| Cross-fase gaps | 1 WARNING (plugins/ideiaos-marketing não commitado) |
| Testes v6-hooks (78 assertions) | 78/78 PASS |
| Testes instinct-recovery (12 cenários) | 12/12 PASS |
| Testes spec-merge (21 asserts) | 21/21 PASS |
| check-readme-sync.sh | 105/105 OK |
| idea-doctor.sh | 51 OK / 11 WARN / 0 FAIL |
| build-adapters --target all --dry-run | exit 0 |
| python3 manifests/modules.json | válido, 87 módulos |

---

## Tabela de Requisitos — Status de Integração

| Req | Fase | Artefato principal | Status | Evidência de wiring |
|-----|------|--------------------|--------|---------------------|
| R6-01 | 23 | `source/lib/gates.sh` | WIRED | EXISTS; 3 funções (11 ocorrências); aplicado em memory-export.sh + observe-session-end.sh (inline test -s) + build-adapters.sh (gate_output); rule `antifragile-gates.md` presente |
| R6-02 | 24 | `source/hooks/instinct-recover.sh` | WIRED | EXISTS; breadcrumb lifecycle em observe-session-end.sh; recovery com claim atômico; IDEIAOS_INSTINCT_SPAWN como barreira #1; 5 barreiras anti-runaway PRESERVADAS; teste 12/12 PASS |
| R6-03 | 25 | `source/skills/forge-agent/SKILL.md` | WIRED | EXISTS; frontmatter `name: forge-agent`; `## Fontes` presente (2 ocorrências); zero `<!--` no corpo; roteável por Deia via /forge-agent |
| R6-04 | 25 | `scripts/build-adapters.sh --validate-parity` | WIRED | Flag `--validate-parity` declarada + `validate_parity()` implementada; wired após `validate_agent_contracts`; bash -n OK; entry `skill-forge-agent` em modules.json |
| R6-05 | 26 | `source/skills/marketing/SKILL.md` | WIRED | EXISTS; pipeline 5 fases (discovery→design→build→review→publish); gates `test -s` entre fases; registrado em marketplace.json como `ideiaos-marketing`; 7 módulos em modules.json |
| R6-06 | 26 | `source/skills/idea/SKILL.md` | WIRED | Matriz da Deia tem 3 novas rotas (marketing, marketing-research, spec); "6 camadas" no SKILL.md; Exemplo 5 com fluxo completo `/idea "cria um carrossel"` → `/marketing`; IDEIAOS.md.tmpl atualizado |
| R6-07 | 26 | `source/rules/marketing/` (22 BPs) | PARTIAL | 22 arquivos em source/rules/marketing/ com header `# SOURCE: OpenSquad MIT`; scan exit 0 (PASS=3 WARN=1 FAIL=0); WARN = AgentShield offline (conforme security/README.md, é WARN não FAIL); zero `<!--` nos 22 arquivos promovidos. **WARNING**: scan-absorbed.sh WARN não foi revertido como gate impeditivo — aceitável por policy, mas pipeline ECC tem 1 check que não é PASS |
| R6-08 | 26 | `source/skills/marketing-research/SKILL.md` | WIRED | EXISTS; usa `mcp__chrome-devtools__*`; modos single_post/profile_1/profile_3; ref `profile-investigation.md` presente; chrome_refs=10; sem nova dependência |
| R6-09 | 26 | `source/agents/mkt-{estrategista,copywriter,designer,revisor}.md` | WIRED | 4 agents com model routing (opus: estrategista; sonnet: copywriter/designer/revisor); zero `<!--`; SOURCE header em cada um; validados por build-adapters frontmatter check |
| R6-10 | 27 | `tests/v6-hooks/` (5 suites) | WIRED | 5 suites, 78 assertions, 0 falhas (PASS local verificado); CI job `structural` em evals.yml referencia `tests/v6-hooks/test-*.sh`; `paths` expandido para `tests/**` |
| R6-11 | 28 | `versions.lock` + guards | WIRED | `gsd=1.1.0` intacto; nota de linhagem 21 linhas com 5 pontos; `is_gsd_pi()` em check-versions-lock.sh (2x) e idea-doctor.sh (2x); `check-versions-lock.sh` exit 0 com mensagem "pin gsd=1.1.0 válido"; STATE.md e handoff atualizados |
| R6-12 | 29 | `source/lib/handoff-packet.sh` | WIRED | EXISTS; 3 conceitos (HANDOFF_TOKEN_BUDGET + anti_injection + input_hash) presentes (10 ocorrências); double-source guard; bash -n OK; `agent-handoff.md` e `handoff-consolidation.md` atualizados com R6-12; rule `context-packet-handoffs.md` presente |
| R6-13 | 30 | `source/skills/spec/` + motor shell | WIRED | SKILL.md, spec-validate.sh, spec-merge.sh existem; 4 templates PT-BR; 21/21 testes PASS; Deia roteada (`/spec` na matriz); 2 entries em modules.json (87 total); rule `delta-spec.md` presente; piloto em produto brownfield classificado como spike/follow-up (decisão documentada) |
| R6-14 | 31 | `docs/decisions/gsd-browser-pilot-evaluation.md` | WIRED | ADR EXISTS; decisão "Adiar" com condição objetiva dupla documentada; 4 critérios cobertos; referência a `frontend-visual-loop/SKILL.md`; nenhum binário instalado |
| R6-15 | 31 | `docs/decisions/agent-inbox-optin.md` | WIRED | Doc EXISTS; 6 ferramentas documentadas; proibições absolutas (NUNCA prod); protocolo opt-in por sessão; referência `mcp-hygiene.md`; nenhum MCP instalado |

---

## Cross-fase — Verificação de Wiring

### Cadeia principal verificada

```
Phase 23 (gates.sh) → sourced por memory-export.sh [WIRED]
                    → sourced por build-adapters.sh [WIRED]
                    → inline em observe-session-end.sh [WIRED]

Phase 24 (instinct-recover.sh) → lê breadcrumb de observe-session-end.sh [WIRED]
                                → respeita IDEIAOS_INSTINCT_SPAWN (Phase 16 anti-runaway) [WIRED]
                                → teste isolado com sandbox HOME [WIRED]

Phase 25 (forge-agent + validate-parity) → skill-forge-agent em modules.json [WIRED]
                                          → build-adapters.sh flag wired antes do case TARGET [WIRED]

Phase 26-01 (22 BPs) → copiadas para source/rules/marketing/ [WIRED]
                      → injetadas em runtime pelo /marketing (pipeline.md) [WIRED]
                      → viajam com o plugin (build_marketing copia rules/marketing/) [WIRED]

Phase 26-02 (agents) → recrutados por /marketing nos passos Design/Build/Review [WIRED]
                     → validados por build-adapters frontmatter check [WIRED]
                     → 4 entries em modules.json plugin=ideiaos-marketing [WIRED]

Phase 26-03 (/marketing) → Deia roteada via ideia/SKILL.md (2 linhas de matriz) [WIRED]
                          → marketplace.json tem ideiaos-marketing [WIRED]
                          → build-plugins.sh build_marketing() copia skills+agents+rules [WIRED]

Phase 27 (tests) → 5 suites cobrem hooks das fases 23/24 + scripts fase 25 [WIRED]
                 → CI evals.yml job structural inclui loop over tests/v6-hooks/ [WIRED]

Phase 28 (GSD lock) → is_gsd_pi() em check-versions-lock.sh E idea-doctor.sh [WIRED]
                    → linhagem em STATE.md e handoff [WIRED]

Phase 29 (handoff-packet) → .claude/rules/agent-handoff.md atualizado [WIRED]
                          → .claude/rules/handoff-consolidation.md Step 1b adicionado [WIRED]

Phase 30 (delta-spec) → /spec roteado pela Deia [WIRED]
                      → modules.json: skill-spec + rule-delta-spec [WIRED]
                      → fronteira /spec × GSD documentada em delta-spec.md [WIRED]

Phase 31 (ADRs) → documentação-only; sem wiring de runtime [WIRED por design]
```

---

## Findings Detalhados

### WARNING — plugins/ideiaos-marketing não commitado

**Severidade:** WARNING (não-bloqueante para uso em Claude Code; bloqueante para distribuição via marketplace add)

**Localização:** `plugins/ideiaos-marketing/` (untracked, ?? em git status)

**Evidência:**
```
git status --porcelain plugins/
 M plugins/ideiaos-core/hooks/observe-session-end.sh
 M plugins/ideiaos-core/skills/idea/SKILL.md
?? plugins/ideiaos-marketing/
```

**Causa:** `build-plugins.sh` gera o diretório em runtime mas o commit 8bdc344 não incluiu `plugins/ideiaos-marketing/`. Os outros plugins versionados (ideiaos-core, ideiaos-design-suite, ideiaos-lovable) são commitados por design (`.gitignore` confirma: "versionado para /plugin marketplace add").

**Impacto:** `/plugin marketplace add ideiaos-marketing` falhará em instalações novas (source `./plugins/ideiaos-marketing` referenciado no marketplace.json mas não está no git). Uso local via build-plugins.sh funciona.

**Resolução sugerida:** Rodar `bash scripts/build-plugins.sh --plugin marketing` e commitar `plugins/ideiaos-marketing/`.

**Também:** Os 2 arquivos modificados em `plugins/ideiaos-core/` (observe-session-end.sh e idea/SKILL.md) refletem as mudanças das fases 24 e 26/30 corretamente — precisam ser commitados junto com o marketing plugin para manter o core plugin sincronizado.

### WARNING — R6-07 scan ECC com WARN (não FAIL)

**Severidade:** WARNING (aceito por policy, não é bloqueante)

**Localização:** `security/quarantine/26-marketing/` → `source/rules/marketing/`

**Evidência:** `scan-absorbed.sh` exit 0 com PASS=3 WARN=1 FAIL=0. O WARN é AgentShield offline.

**Decisão da fase:** conforme `security/README.md`, AgentShield offline é WARN não FAIL e não bloqueia promoção. Aceito.

### NOTA — <!--SOURCE--> em antifragile-gates.md

**Não é violação.** `source/rules/common/antifragile-gates.md` linha 1 usa `<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->` — esse é o header de metadados padrão do sistema de rules (presente na grande maioria dos arquivos em `source/rules/`). O SUMMARY da fase 23 verificou "11 automated checks passed" incluindo "antifragile-gates.md body has no bare HTML comments" — o check passou porque o `<!--SOURCE...-->` é o header de metadados, não conteúdo HTML.

### NOTA — R6-13 piloto em produto brownfield

**Não é bloqueante.** A capability /spec está completa (skill + motor + 21 testes + rule + roteamento Deia). O piloto em produto real foi classificado pelo executor como spike/follow-up com fundamento documentado ("não tem sentido forçar um delta artificial"). R6-13 fecha no nível "estrutura+fluxo+skill" conforme nota no REQUIREMENTS.md ("Pode ficar como spike se o tempo apertar").

### NOTA — README.md em handoff-packet (fase 29, Task 3 skipped)

**Resolvido por cross-fase.** O executor de fase 29 pulou README.md por instrução do orquestrador ("centralizado no final da onda"). check-readme-sync.sh reporta 105/105 OK — `handoff-packet.sh` está mencionado no README.

---

## Anti-Runaway — Verificação Crítica

As 5 barreiras do instinct loop pós-fase 24:

| Barreira | Mecanismo | Status |
|----------|-----------|--------|
| #1 IDEIAOS_INSTINCT_SPAWN | exit 0 cedo em observe-session-end + instinct-recover.sh | PRESERVADO |
| #2 Sentinela .last-analyzed | escrita ANTES do spawn; TS_OBS > TS_LAST | PRESERVADO |
| #3 Cooldown 30min | ELAPSED < 1800; fix timezone time.mktime aplicado | PRESERVADO (melhorado) |
| #4 timeout 120s | `timeout 120 claude ...` no spawn e no re-spawn | PRESERVADO |
| #5 command -v claude | gate em observe-session-end E instinct-recover.sh | PRESERVADO |
| NOVA: anti-corrida | claim atômico mv + kill -0 liveness | ADICIONADO sem enfraquecer as 5 |

A recovery (fase 24) verifica IDEIAOS_INSTINCT_SPAWN como primeira instrução — sessões de análise não executam recovery. Zero possibilidade de spawn loop introduzida.

---

## Requirements com Wiring Exclusivamente Intra-fase

| Req | Justificativa |
|-----|---------------|
| R6-14 | ADR documentação-only; sem runtime wiring por design (objetivo é avaliar/adiar) |
| R6-15 | Doc opt-in documentação-only; MCP não instalado por design |

Esses dois requisitos são self-contained por intenção — não indicam conexão faltando.

---

## Veredicto Final

**Status: `gaps_found`** (1 WARNING cross-fase real, sem BLOCKER)

A integração das 9 fases está substancialmente correta. O único gap real é `plugins/ideiaos-marketing/` não estar commitado, o que quebra `marketplace add ideiaos-marketing` em instalações novas. Todos os outros wires (exports→imports, API routes→consumers, test suites→CI, Deia routing→skills) estão verificados ponta-a-ponta.

**Ação necessária antes de declarar `passed`:**
1. `bash scripts/build-plugins.sh --plugin marketing` + commit de `plugins/ideiaos-marketing/` + `plugins/ideiaos-core/hooks/observe-session-end.sh` + `plugins/ideiaos-core/skills/idea/SKILL.md`

Após esse commit: status sobe para `passed`.


## Adendo — WARNING resolvido (2026-06-16)
- plugins/ regenerado via build-plugins.sh: ideiaos-marketing commitado + ideiaos-core sincronizado (fases 24/26/30). `git status plugins/` = 0. Marketplace add resolve. **Status final: passed.**
