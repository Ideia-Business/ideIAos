# SOURCE: IdeiaOS v2

**Data:** 2026-06-12
**Fase:** 08-04 — Síntese v3 (Wave 2)
**Alimentado por:** 08-01 (agents-audit), 08-02 (skills-guide), 08-03 (token-economy-review)

---

## Resumo

O v2 acertou na arquitetura central: `source/` como fonte única de verdade, roteamento via `/idea`, loop de aprendizado (Fase A), e a camada de agents com separação clara de responsabilidades. A maioria dos 15 agents tem model correto, directedness alta e tools bem dimensionadas. As 34 skills cobrem bem os clusters de workflow e o mapa de redundância foi documentado.

Os problemas que v3 precisa resolver são concentrados em quatro áreas: (1) dois agents sem `model:/tools:` declarados expõem o sistema a comportamento imprevisível; (2) o loop de instincts captura automaticamente mas destila manualmente — a "Fase A automática" prometida está incompleta; (3) a suíte de evals existe mas não executa automaticamente, e o CI/CD é zero; (4) a economia de tokens tem otimizações claras e baratas ainda não aplicadas.

**Total de gaps identificados:** 15 (4 P1 · 7 P2 · 4 P3)

**Top P1:** agents sem model/tools declarados (G-01, G-02); instinct-analyze sem scheduler (G-03); evals sem execução automática (G-04).

---

## Síntese das Auditorias

### agents-audit.md — 15 agents, 7 OK / 6 AJUSTAR / 2 RETRABALHAR

Os dois problemas transversais críticos são: `claude-continuation` e `ideiaos-checker` sem `model:` e sem `tools:` no frontmatter, deixando-os rodando no default do harness. O `ideiaos-checker` ainda tem inconsistência filename vs campo `name:` (`ideiaos-checker.md` com `name: setup-checker`), quebrando rastreabilidade no `manifests/modules.json`. Outros gaps menores: passos vagos em `doc-updater` e `performance-optimizer` (directedness Medium), overlap entre `refactor-cleaner` e `code-simplifier` sem critério de separação, e `security-reviewer` sem instrução de checagem de dependências. O Passo 3 do `ideiaos-checker` pede confirmação do usuário, bloqueando execução em modo agentic.

Referência completa: `docs/v3/agents-audit.md`.

### skills-guide.md — 34 skills, 10 candidatos de redundância mapeados

A hierarquia da suíte de design (`design` como orquestrador de `banner-design`, `brand`, `design-system`, `slides`) não está documentada nos SKILL.md individuais, causando dúvida sobre qual usar. `slides` standalone é candidata a aposentadoria em favor do subsistema de slides do `design-system` (mais robusto: CSVs, BM25, contextual decision flow). O `/instinct-analyze` não tem scheduler — gap documentado explicitamente no SKILL.md. `banner-design` referencia skills inexistentes (`ai-artist`, `ai-multimodal`) que não estão em `modules.json`. `frontend-visual-loop` referencia `gsd-ui-review` também ausente do manifesto. O catálogo (`ideiaos-catalog`) referencia 60 módulos mas o real é 66+ (pós-Fase 05 e 07).

Referência completa: `docs/v3/skills-guide.md`.

### token-economy-review.md — roteamento de modelos sólido, 3 otimizações baratas pendentes

O roteamento haiku/sonnet/opus está bem fundamentado para 13/15 agents. Os dois sem `model:` herdando o default do harness é o risco principal. Oportunidades de redução claras: downgrade `silent-failure-hunter` opus→sonnet (~5x economia por invocação, processo é grep patterns fixos), otimizar `strategic-compact` trocando subprocess python3 por bash puro para contador (~900ms economizados em sessão com 200 calls), e adotar `typescript-lsp` com `installStrategy: stack:typescript` (find-references semântico reduz leitura de múltiplos arquivos). `mgrep` adiado sem benchmark IdeiaOS confirmado.

Referência completa: `docs/v3/token-economy-review.md`.

---

## Gaps de Orquestração

Gaps transversais que as auditorias por componente não surfaçam diretamente — avaliados contra o sistema real.

### CI/CD — ausente

Confirmado: não existe diretório `.github/` no repo. Todo o enforcement de qualidade é local: pre-commit hook (`check-readme-sync.sh`), `idea-doctor.sh` (diagnóstico manual), e `run-evals.sh` (runner manual). Nenhuma execução automática em push/PR. Para um sistema como o IdeiaOS (que instala em múltiplas máquinas via autosync), ausência de CI significa que regressões em hooks/agents/scripts só são detectadas se alguém rodar `idea-doctor.sh` manualmente. Gap real.

### Multi-repo / aplicação em lote

O autosync (LaunchAgent a cada 15 min) cobre propagação do repo IdeiaOS para a mesma máquina. Mas não existe mecanismo para aplicar atualizações do IdeiaOS a todos os projetos-alvo (`~/dev/nfideia`, `~/dev/ideiapartner`, etc.) de uma vez. Cada projeto precisa ter o `setup.sh --project-only` rodado separadamente. Em escala (5+ projetos), isso é trabalho manual repetitivo. Gap real.

### Evals sem execução LLM automática

O `run-evals.sh` existe e tem `run_case_with_model()` como ponto de extensão nomeado para execução futura, mas a execução atual é manual e não chama LLM (requer API key separada, decisão 07-02). Isso significa que a suíte de 22+ casos é uma rede de segurança de papel — nunca executada em CI, nunca executada por automação, dependente de invocação humana explícita. Gap real e de alto valor.

### Instinct loop sem scheduler

O hook `observe-session-end.sh` marca `session_end` em `observations.jsonl` automaticamente. O `/instinct-analyze` deveria rodar após isso para destilar as observações em instincts. Mas não há hook `PostToolUse[session_end]` nem scheduler que chame `/instinct-analyze`. O resultado: captura automática, destilação manual. A promessa de "Fase A automática" está parcialmente cumprida. Gap confirmado pelo próprio `skills-guide.md` (seção Gaps de Documentação, item 1).

### Deny rules dependem de ação manual

As 6 deny rules baseline de segurança (Patch 10: `Read(~/.ssh/**)`, `Read(~/.aws/**)`, etc.) são aplicadas via `install-global-patches.sh`. Em máquinas novas, o bootstrap (`setup-dev-machine.sh`) inclui `setup.sh --global-only` que chama `install-global-patches.sh`. Mas em máquinas existentes que não rodaram o bootstrap completo, as deny rules só são aplicadas se o usuário rodar `install-global-patches.sh` explicitamente ou `sync-all.sh`. `idea-doctor.sh` detecta a ausência mas não corrige. Gap de enforcement.

### Contexts não instalados automaticamente em máquinas existentes

O `setup.sh` (passo 5.22) implanta os contexts em `~/.ideiaos/contexts/` e oferece um snippet de shell via output no terminal. O snippet (`claude-dev/claude-review/claude-research`) não é adicionado ao `~/.zshrc` automaticamente (regra T-01-10: IA não modifica config do usuário sem permissão). Em máquinas existentes que já rodaram o setup antes do Passo 5.22 ser adicionado (Fase 07), os contexts estão ausentes sem diagnóstico visível. `idea-doctor.sh` não verifica a presença dos functions no rc. Gap real, afeta usabilidade da Fase 07.

### Docs/ fora do escopo do hook README-sync

O hook pre-commit (`check-readme-sync.sh`) audita `source/`, `scripts/`, `plugins/`, `manifests/`. Arquivos em `docs/` — incluindo `docs/v3/`, `docs/IDEIAOS.md`, `docs/security/` — podem ser editados sem acionar o hook. Drift silencioso entre README e docs/ é possível. Gap de DX menor mas real.

### Falso positivo residual: `nc ` em scan-absorbed.sh

`security/scan-absorbed.sh` usa `r'nc '` como pattern de detecção de netcat. O substring `nc ` aparece em palavras comuns de código TypeScript/JavaScript como `function`, `sync`, `async`, `truncate`. Isso gera WARNs falsos positivos ao absorver código TypeScript normal. Documentado em STATE.md (decisão 03-04) como inspecionado e aprovado, mas não corrigido no script. Gap de DX: cada absorção de código TS requer inspeção manual dos WARNs.

---

## Gaps Priorizados

| ID | Gap | Origem | Prioridade | Esforço | Valor |
|----|-----|--------|------------|---------|-------|
| G-01 | `claude-continuation` e `ideiaos-checker` sem `model:` e `tools:` no frontmatter (corrigido na Fase 09) | agents-audit | P1 | Baixo | Alto |
| G-02 | `ideiaos-checker.md` com `name: setup-checker` — inconsistência filename vs modules.json (corrigido na Fase 09) | agents-audit | P1 | Baixo | Alto |
| G-03 | `/instinct-analyze` sem scheduler automático — captura automática, destilação manual | skills-guide / orquestração | P1 | Médio | Alto |
| G-04 | `run-evals.sh` nunca executa automaticamente — suíte de 22+ casos é rede de papel | orquestração (evals) | P1 | Alto | Alto |
| G-05 | `silent-failure-hunter` em opus, mas processo é grep patterns fixos — candidato a sonnet | token-economy | P2 | Baixo | Alto |
| G-06 | `strategic-compact` usa subprocess python3 a cada tool call — bash puro seria ~10x mais rápido | token-economy | P2 | Baixo | Médio |
| G-07 | `typescript-lsp` não adotado — find-references semântico ainda não instalado com `stack:typescript` | token-economy | P2 | Médio | Alto |
| G-08 | Ausência de CI/CD — regressões em hooks/agents/scripts detectadas só manualmente | orquestração (CI) | P2 | Alto | Alto |
| G-09 | Multi-repo em lote: sem mecanismo para propagar setup a múltiplos projetos-alvo de uma vez | orquestração (multi-repo) | P2 | Médio | Médio |
| G-10 | Deny rules baseline dependem de `install-global-patches.sh` manual em máquinas existentes | orquestração (segurança) | P2 | Médio | Alto |
| G-11 | Contexts (`claude-dev/review/research`) não verificados pelo `idea-doctor.sh` em máquinas existentes | orquestração (07-01) | P2 | Baixo | Médio |
| G-12 | `banner-design` referencia skills inexistentes (`ai-artist`, `ai-multimodal`) fora do modules.json | skills-guide | P3 | Baixo | Médio |
| G-13 | `frontend-visual-loop` referencia `gsd-ui-review` ausente do manifesto — módulo planejado não marcado | skills-guide | P3 | Baixo | Baixo |
| G-14 | `ideiaos-catalog` desatualizado — menciona 60 módulos, real é 66+ (pós-Fase 05 e 07) | skills-guide | P3 | Baixo | Médio |
| G-15 | `nc ` em scan-absorbed.sh gera falsos positivos em código TypeScript (substring em function/sync/async) | orquestração (DX) | P3 | Baixo | Baixo |

---

## Recomendação v3

Os quatro P1s definem o teto mínimo de v3: dois fixes de frontmatter (G-01, G-02) que têm custo zero e eliminam comportamento imprevisível de agents críticos; automação do loop de instincts (G-03) que fecha a promessa da Fase A; e infraestrutura de evals automática (G-04) que transforma a suíte existente em rede de segurança real. Sem G-04, qualquer mudança no sistema é uma aposta.

Os P2s de maior valor são G-05 (downgrade opus→sonnet, economia imediata), G-07 (typescript-lsp, já decidido em 08-03), G-08 (CI mínimo com GitHub Actions) e G-10 (enforce de deny rules sem depender de ação manual). Esses sete gaps (4 P1 + 3 P2 prioritários) devem guiar as fases candidatas de v3.

O detalhamento das fases candidatas está em `docs/v3/v3-roadmap.md`.
