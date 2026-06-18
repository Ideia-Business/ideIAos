---
date: 2026-06-18
session_type: discovery
incident: n/a
commit: 2a87a5c
tags: [mcp, integration-surface, vendor-abstraction, experiment-design, git-coupling]
applies_to_projects: [global]
promote_to_vault: true
---

# Um MCP/wrapper pode abstrair justamente a camada que sua verificação precisa — sonde a superfície antes de desenhar o experimento

## Trigger (quando reler isso)

Quando for desenhar um experimento (ou uma feature) cuja **medição/governança depende de manipular uma camada subjacente** (Git, DB, filesystem, fila) através de um wrapper/integração (MCP, SDK, plataforma no-code) — e você ainda **não confirmou** que o wrapper expõe essa camada.

## O padrão (abstrato)

Um wrapper que **acopla** duas camadas (ex.: uma plataforma que espelha seu estado interno para um repositório Git) não necessariamente **expõe ou permite manipular** a camada acoplada. O acoplamento ser real (observável read-only) não implica que ele seja **endereçável** pela API do wrapper. Se o seu teste depende de criar uma **divergência controlada** na camada subjacente (ex.: `git push` de algo que o wrapper não originou) e o wrapper não te dá um identificador/handle para essa camada, o experimento é **estruturalmente impossível** por aquele caminho — não importa quantas tentativas você faça.

O erro caro é desenhar o experimento inteiro assumindo que "se as duas camadas estão acopladas, eu consigo mexer em ambas". A pergunta de viabilidade — *"a API me dá um handle para a camada subjacente?"* — tem que vir **antes** de planejar a manipulação, não ser descoberta no meio da execução (depois de gastar crédito/recursos).

## Evidência (concreta — desta sessão)

- Milestone v10 (Lovable MCP), Fase B sandbox. Plano: `B-01-PLAN.md`; resultado: `B-01-SUMMARY.md`.
- Read-only **provou o acoplamento**: `commit_sha` do `list_edits` == SHA do `git log origin/main` (A1-namespace=ACOPLADO; A3=PASS).
- Mas a manipulação era **inviável**: o MCP **não expõe nem gerencia o gitsync GitHub**:
  - `list_connectors(workspace)` — 50+ integrações, **nenhuma "github"**.
  - `list_connections(workspace)` — zero conexão GitHub.
  - `get_project` — retorna `latest_commit_sha` mas **nenhuma URL de repo**.
  - Fork remixado: `gh search commits --hash <sha_0>` = `[]`; nenhum repo auto-criado; a fonte sem repo → gitsync é manual-por-projeto na UI do editor.
- Consequência: A2 (`deploy` lê de main vs interno) e A1-lag ficaram **inmensuráveis no sandbox MCP** → veredito conservador BLOQUEAR, porque o teste de divergência precisava de um `origin/main` endereçável no fork, que não existe.

## Regra prática derivada

Antes de planejar um experimento que **manipula** uma camada subjacente via wrapper, rode uma **sonda de viabilidade read-only**: *"a API me devolve um handle endereçável para essa camada (URL de repo, connection id, path, endpoint)?"* Se a resposta for não, o experimento de manipulação é inviável por esse caminho — re-desenhe (medir por fora do wrapper) ou declare o item **indeterminado** (e, em decisão de segurança, indeterminado vota **bloquear**). Distinga sempre **acoplamento observável** (read-only confirma) de **acoplamento endereçável** (a API te dá o handle para mexer) — provar o primeiro não garante o segundo.

## Falsos positivos / armadilhas

- "A integração tem o feature flag ligado" (ex.: `gitsync_github: true` no workspace) **não** significa que a API exponha o handle — o flag pode ser configurado só na UI do produto.
- Conseguir **ler** o estado acoplado (SHAs batem) seduz a achar que dá pra **escrever**/divergir — são capacidades diferentes.
- Tentar "mais uma fonte/projeto" quando o muro é **estrutural** (a superfície inteira não tem o handle) só queima recurso — o limite não é o projeto-alvo, é a API.
- **Instrumento ≠ interface** (refinamento da auditoria de fechamento `wf_4fec3ed7-fc0`, 2026-06-18): distinga "impossível pela **interface inteira** (o MCP)" de "impossível pelo **instrumento escolhido** (o fork sem gitsync)". O segundo é quase sempre o verdadeiro; o primeiro é uma **superafirmação** que fecha caminhos válidos. Ex.: A2 não era "inmensurável via MCP" — era inmensurável **no fork**; É mensurável via MCP num **produto real com gitsync**. Ao declarar uma impossibilidade, prefira a versão mais estreita que a evidência sustenta.

## Cross-references

- `.planning/milestones/v10-phases/B-sandbox/B-01-SUMMARY.md` — veredito + tabela-verdade
- `docs/research/2026-06-17-lovable-mcp-integration-plan.md` §2.5b
- `[[learning-temp-privilege-window-teardown-grants]]` — outro learning da mesma trilha v10
- Memória global: `learning_mcp-wrapper-hides-underlying-layer.md`

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-18 — motivo: padrão `[global]`, stack-agnóstico
- [x] Promovido para Obsidian vault em 2026-06-18 — motivo: síntese cross-projeto
- [ ] Aplicado retroativamente em outros learnings
