---
phase: A-quarentena-absorcao
plan: A-01
type: execute
status: PARTIAL
executed_at: "2026-06-17"
result: "Quarentena completa e vereditos congelados; scan tem 1 FAIL = falso-positivo documentado (decisão pendente do orquestrador)"
---

# A-01 — SUMMARY: Quarentena & atribuição (mattpocock/skills)

## Resultado: PARCIAL

As 3 tasks foram executadas integralmente. O único item que **não** atinge o
critério literal do PLAN é o `must_have` "scan exit 0": a captura verbatim do
`HTML-REPORT.md` (exigida pela Task 1) introduz 1 FAIL no Check-2 do scanner —
um **falso-positivo conhecido e documentado**, não payload ativo. Os dois
critérios ("capturar verbatim" + "scan exit 0") são mutuamente exclusivos com o
scanner atual; a resolução é uma decisão de design do scanner que pertence ao
orquestrador (ver Pendência abaixo). Tudo o mais está completo e verificado por
gate binário.

## O que foi entregue

### Task 1 — Resources de apoio capturados (verbatim, commit 694fa30)
Path upstream confirmado e usado: `skills/engineering/<skill>/<RESOURCE>.md`
(confirmado abrindo os SKILL.md já estagiados: `grill-with-docs.md` cita
`./CONTEXT-FORMAT.md` e `./ADR-FORMAT.md`; `improve-codebase-architecture.md`
cita `LANGUAGE.md`, `HTML-REPORT.md` e `../grill-with-docs/CONTEXT-FORMAT.md`).
Salvos em subdiretórios `skills/<skill>/` para preservar o caminho relativo que
os SKILL.md citam (estrutura coerente com as referências internas).

- `security/quarantine/mattpocock-skills/skills/grill-with-docs/CONTEXT-FORMAT.md` (2299 bytes) → Fase B / R9-02
- `security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md` (2766 bytes) → Fase C / R9-03
- `security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/LANGUAGE.md` (3804 bytes) → Fase E / R9-05
- `security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/HTML-REPORT.md` (6671 bytes) → Fase E / R9-05

Captura via `curl -fsSL https://raw.githubusercontent.com/mattpocock/skills/694fa30/<path>`
(rede disponível; WebFetch não foi necessário). Revisão manual de injection inline:
são docs de formato (templates Markdown, glossário, scaffold HTML). Gate binário
`test -s`: 4/4 PASS, não-vazios.

### Task 2 — Re-scan + inspeção dos sinais
Comando: `bash security/scan-absorbed.sh security/quarantine/mattpocock-skills`
**Exit code: 1** · **Counts: PASS 1 / WARN 2 / FAIL 1**

- **Check-1 (unicode invisível):** ✓ limpo.
- **Check-2 (HTML/JS/base64):** ✗ FAIL — 2 ocorrências, AMBAS em
  `skills/improve-codebase-architecture/HTML-REPORT.md:13-14`
  (`<script src="https://cdn.tailwindcss.com">` e `<script type="module">`),
  dentro de um bloco de código markdown ```` ```html ````. É o **scaffold
  documental** de como a skill gera o relatório HTML — não payload injetado.
  **Falso-positivo:** o Check-2 é binário e não tem allowlist para fenced code
  blocks. Antes da captura (baseline do PLAN, só os SKILL.md flat), este Check
  passava → exit 0; o HTML-REPORT.md é justamente o arquivo que estava em
  `not_captured`.
- **Check-3 (curl/ssh/wget):** ⚠ WARN benigno — matches em `README.md` e
  `_catalog.yaml` (que *mencionam* os comandos ao descrever os WARNs) +
  `diagnose.md`/`setup-matt-pocock-skills.md`/`handoff.md` (docs legítimas,
  nenhuma será absorvida). Os 4 resources novos NÃO adicionam matches.
- **Check-4 (AgentShield):** ⚠ WARN benigno — scanner externo offline; scan parcial.

Bloco `security_scan` do `_catalog.yaml` atualizado: `ran_at: 2026-06-17`, counts
revalidados, sub-bloco `manual_review` com a inspeção dos 3 sinais.

### Task 3 — Vereditos congelados (zero `verdict: pending`)
Alinhados ao relatório `docs/research/2026-06-16-mattpocock-skills-analise.md`
(§3 tabela, §8 priorização). Cada veredito ganhou comentário apontando a fonte.

| Skill | Veredito final |
|-------|----------------|
| grill-with-docs | **absorber** (núcleo Fase B / R9-01) |
| grill-me | **absorber** (modo `--rapido` do /grelha) |
| improve-codebase-architecture | **adaptar** (ritual deepening — Fase E / R9-05) |
| to-prd | **adaptar** (delta fino @pm — Fase F/G) |
| diagnose | **overlaps-existing** (gsd-debug; absorver 1 nota) |
| prototype | overlaps-existing | tdd | overlaps-existing |
| handoff | overlaps-existing | write-a-skill | overlaps-existing |
| to-issues | **ignore** | triage | ignore |
| setup-matt-pocock-skills | ignore | zoom-out | ignore (rebaixado de candidate) |
| caveman | ignore (rebaixado de candidate) | | |

Também: `not_captured` atualizado (removidos os 2 itens capturados; mantidos
DEEPENING/INTERFACE-DESIGN e demais não-capturados) + novo bloco
`captured_resources` documentando os 4 resources; nota de `origin` atualizada.

## Verificação (gate binário)
- `test -s` nos 4 resources: 4/4 PASS.
- `grep -q 'verdict: pending'`: rc=1 (zero pending).
- `ruby -ryaml`: `_catalog.yaml` parseia OK (YAML válido).
- scan-absorbed.sh: exit 1 (FAIL 1 = falso-positivo documentado; 0 payload ativo).

## Pendência crítica para o orquestrador
O critério "scan exit 0" do PLAN não é alcançável mantendo o `HTML-REPORT.md`
verbatim na árvore escaneada — o PLAN assumiu (linha 62) que os 4 resources
seriam limpos, mas o HTML-REPORT.md contém um scaffold HTML legítimo com
`<script>` que o Check-2 marca como FAIL. **Decidir antes de promover a `source/`
(Fase B), por uma de:**
- (a) adicionar allowlist de fenced-code-blocks ```` ```html ```` ao Check-2 de
  `security/scan-absorbed.sh` (toca arquivo fora do escopo da Fase A → @devops/orquestrador);
- (b) aceitar este FAIL benigno como baseline registrada da quarentena (já está
  documentado em `_catalog.yaml › security_scan › manual_review`).

Não tomei essa decisão sozinho porque toca `scan-absorbed.sh`, fora do escopo
declarado da Fase A ("toque SÓ os 4 resources + _catalog.yaml").

## NOTA OBRIGATÓRIA — Reset de sessão antes da Fase B (higiene de memória)
Conforme `docs/security/memory-hygiene.md` (Regra 3) e o AGENTS.md: após
capturar/interagir com conteúdo de terceiro em quarentena, **iniciar nova sessão
do Claude Code antes de prosseguir para a Fase B** (autoria/absorção em `source/`).
Esta fase A→B é o gate de transição que materializa essa regra:
1. Encerrar a sessão atual.
2. Abrir nova sessão (memória de projeto persiste; contexto da conversa é zerado).
3. Opcional: revisar `~/.claude/projects/<projeto>/` para remover observações
   geradas durante o run de quarentena.
Motivo: conteúdo de quarentena pode ter tentado injetar instruções no contexto;
sessão nova previne contaminação do trabalho confiável da Fase B.

## Arquivos modificados
- `security/quarantine/mattpocock-skills/skills/grill-with-docs/CONTEXT-FORMAT.md` (criado)
- `security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md` (criado)
- `security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/LANGUAGE.md` (criado)
- `security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/HTML-REPORT.md` (criado)
- `security/quarantine/mattpocock-skills/_catalog.yaml` (vereditos finais + security_scan + captured_resources + not_captured + origin note)
- `.planning/milestones/v9-phases/A-quarentena-absorcao/A-01-SUMMARY.md` (este arquivo)
