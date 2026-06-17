# Quarentena — `mattpocock/skills`

> **Status: ESTAGIADO, PENDENTE de análise/absorção.** Nada aqui foi absorvido em
> `source/`. Nenhum arquivo foi modificado. Este é material-fonte de terceiros em
> quarentena, seguindo o mesmo padrão usado no milestone **v8** (absorção de
> `addyosmani/agent-skills`).

## O que é

Material-fonte bruto (sem modificação) das skills priorizadas do repositório de
agent skills do **Matt Pocock**, estagiado para que uma futura etapa de absorção
possa proceder com revisão humana + de IA.

## De onde veio

- **Repo:** https://github.com/mattpocock/skills
- **Autor:** Matt Pocock
- **Licença:** **MIT** (preservada em [`LICENSE`](./LICENSE) — Copyright (c) 2026 Matt Pocock)
- **Commit capturado:** `694fa30311e02c2639942308513555e61ee84a6f` (2026-06-10)
- **Capturado em:** 2026-06-16 via `raw.githubusercontent.com` (bytes idênticos aos tamanhos reportados pela tree API do GitHub).

> **Atribuição obrigatória:** qualquer absorção em `source/` DEVE preservar o crédito
> a Matt Pocock e o texto da licença MIT (igual ao que o v8 fez com `agent-skills`).

## Organização (espelha o padrão do v8)

```
security/quarantine/mattpocock-skills/
├── _catalog.yaml          # catálogo no formato dos demais (origem + status + veredito preliminar)
├── LICENSE                # licença MIT original (atribuição)
├── README.md              # este arquivo
├── CONTEXT.md             # glossário de domínio do repo de origem
├── CLAUDE.md              # instruções de projeto do repo de origem
├── (README do repo)       # NÃO renomeado — o README.md acima é o desta quarentena
└── skills/                # um <nome>.md por SKILL.md baixado (conteúdo bruto)
    ├── grill-with-docs.md  (PRIORIDADE MÁXIMA)
    ├── grill-me.md
    ├── diagnose.md
    ├── to-prd.md
    ├── to-issues.md
    ├── improve-codebase-architecture.md
    ├── zoom-out.md
    ├── prototype.md
    ├── tdd.md
    ├── triage.md
    ├── setup-matt-pocock-skills.md
    ├── caveman.md
    ├── handoff.md
    └── write-a-skill.md
```

> **Nota sobre o README do repo de origem:** para não sobrescrever este `README.md`
> de quarentena, o README original do `mattpocock/skills` foi salvo como
> [`UPSTREAM-README.md`](./UPSTREAM-README.md).

## Conteúdo estagiado

- **14/14** SKILL.md priorizados → `status: fetched`.
- **4/4** arquivos de raiz (LICENSE, README, CONTEXT, CLAUDE) → `status: fetched`.
- Arquivos de apoio de cada skill e buckets não priorizados → `status: not_fetched`
  (listados em `_catalog.yaml` › `not_captured`; registrados, não inventados).

## Resultado do scan de segurança

Rodado com `security/scan-absorbed.sh` apontando para esta pasta (PASSO 4).
Resultado: **APROVADO COM RESSALVA** — `FAIL=0` (nenhum payload ativo). Os WARNs são
esperados e exigem inspeção manual antes de promover:

- **Comandos suspeitos** — `curl`/`ssh`/`wget` aparecem em documentação legítima
  (ex.: `diagnose` sugere scripts curl/HTTP e browser headless; `setup-matt-pocock-skills`
  menciona `gh`/`glab`). Nenhum é payload executável embutido.
- **AgentShield offline** — scanner externo indisponível no ambiente (scan parcial).

O detalhe numérico (`PASS/WARN/FAIL`) está registrado em `_catalog.yaml` › `security_scan`.

## Achados relevantes (para a etapa de absorção)

- **Tensão anti-framework:** o README do repo de origem se posiciona **explicitamente
  contra GSD, BMAD e Spec-Kit** ("they take away your control"). Relevante para a
  camada GSD/AIOX do IdeiaOS — avaliar como conciliar.
- **Dependências externas:** `diagnose` (browser headless / curl), e o quarteto
  `triage`/`to-issues`/`to-prd`/`setup-matt-pocock-skills` (issue tracker via `gh`/`glab`).
- **Sobreposições prováveis** com skills já existentes no IdeiaOS: `tdd`, `handoff`
  (continuation), `write-a-skill` (skill-creator/create-skill).

## Próximo passo

A **análise comparativa detalhada** (veredito final por skill, recomendação de
absorver/adaptar/ignorar) é produzida em paralelo por outro agente em:

```
docs/research/2026-06-16-mattpocock-skills-analise.md
```

Este diretório de quarentena permanece **somente-leitura** até essa decisão.
