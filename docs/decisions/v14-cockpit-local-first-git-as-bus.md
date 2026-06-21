# ADR — v14: IdeiaOS Cockpit (local-first, git-as-bus por ref, teto de poder gated)

**Status:** **Aceito** (2026-06-20) · aprovado pelo usuário via 3 decisões (AskUserQuestion); contrato `/spec` + plano GSD formalizados; build PROPOSTO (zero código)
**Contexto-fonte:** sessão de design 2026-06-20 — orquestração multi-agente (13 agentes / 5 fases; recon → painel de 6 especialistas → síntese → crítica adversarial → blueprint). Design em `docs/ideiaos-console/`.
**Sucede:** reusa o substrato auto-telemetrado de v2…v13 (SOAK `.planning/soak/` + `check-soak.sh`, security-freshness, idea-doctor, git-autosync) e a disciplina `antifragile-gates` + `credential-isolation`.
**Proveniência:** **nativo IdeiaOS** — surfacing sobre peças existentes; única dependência nova prevista é `better-sqlite3` (read-model descartável).

## Contexto

Pedido do usuário: transformar a experiência de instalação/ativação/gestão dos projetos numa
**página web com visão de CTO/Tech-Lead** sobre o todo — máquinas conectadas, contas/IAs,
projetos+usuários, gestão de chaves (API/GitHub/Vercel), conexões MCP e produtividade — numa
central única de comando.

Tensão de fundo: um console que centraliza chaves e conexões é a **maior superfície de ataque
imaginável**. A regra-piso `credential-isolation` exige que o **valor** de um segredo nunca
transite pelo contexto do LLM nem do browser. E o git-autosync da casa faz `git add -A` cego em
branch não-`main` — qualquer arquivo de comando/estado no working tree seria capturado e
propagado sem autorização.

## Princípio (a espinha)

O IdeiaOS **já se auto-telemetra cross-máquina via git**. O Cockpit é **camada de surfacing +
controle**, não coleta nova. Lê por **referência** (nome/idade/escopo), comanda só o **local e
reversível**; poder destrutivo (mutação de produção, ação cross-máquina) fica atrás de um
threat-model. **Defesa estrutural, não disciplinar:** as brechas se fecham eliminando a
*necessidade* (não há arquivo de comando → não há o que sequestrar), não gerenciando-a.

## Decisão

| Eixo | Decisão | Efeito |
|---|---|---|
| **Nome** | **IdeiaOS Cockpit** (metáfora glass-cockpit) | ref de federação git = `cockpit`; daemon = `ideiaos-agentd` |
| **Topologia** | **Local-first**, zero backend cloud novo | reusa o substrato; SPA em `http://127.0.0.1`, sem login na v14.1 |
| **Federação** | **git-as-bus por REF** (`cockpit`), via `commit-tree`/`update-ref` | snapshot **nunca** existe no working tree → o `git add -A` do autosync não captura; autosync só dá push do ref `cockpit`, nunca de `main` |
| **Coleta** | `ideiaos-agentd` (4º LaunchAgent, 900s), **read-only** | deriva metadata de ledgers/git/launchctl; `git status` dos repos permanece limpo |
| **Segredo** | **Zero-Leak=0** — valor nunca no browser/LLM | `ApiKey` sem coluna `value`; Cofre-Espelho é metadata-only; invariante = gate de release (P0) |
| **Comando (v14.1)** | allowlist **fixo** de verbos locais reversíveis | pausar/retomar autosync, idea-doctor, re-selo de segurança; mutação de produção/cross-máquina **fora** |
| **Teto de poder** | comando cross-máquina + rotate/revoke/deploy = **v14.4, GATED** | só com `/spec` de segurança + threat-model STRIDE/OWASP-LLM aprovado; RBAC nasce junto |
| **Frescor** | local-vivo (file-watch) vs cross-máquina-eventual (~15min) **distintos** | nunca animar fluxo contínuo sobre dado em lote |

## Alternativas consideradas (e por que não)

- **SaaS multi-tenant cloud** — rejeitada: contraria o local-first do IdeiaOS, exigiria custódia
  central de credenciais (anátema à `credential-isolation`) e introduziria backend + auth pesados
  para uma audiência de 1 operador.
- **Piggyback no SOAK `--record` como coletor** — rejeitada (a **crítica adversarial pegou**):
  `check-soak.sh --record` é **manual** (nenhum LaunchAgent o invoca), o que quebraria a promessa
  de "heartbeat vivo". Daí o 4º LaunchAgent dedicado.
- **Fila de comandos como arquivo no working tree, assinada por backend** — rejeitada: exigiria um
  signer server-side que a arquitetura nega, e o autosync capturaria o arquivo antes da assinatura.
  Resolvido eliminando o arquivo de comando (IPC de processo local; cross-máquina só na v14.4).

## Consequências

**Positivas:** reaproveita 100% do substrato existente; superfície de ataque minimizada por
construção; aditivo e reversível; coerente com a identidade black-gold OKLCH da camada OS.

**Aceitas (trade-offs):** frescor cross-máquina é eventual (~15min, 1 ciclo de autosync), não
tempo-real; P1/P2 (multi-usuário) são vaporware até haver segundo ator; idea-doctor não roda nos
produtos Lovable → health-score com sub-sinal `n/a` honesto; todo o recon foi numa máquina
(assimetria assumida, não quebra o collector).

**Irreversível-ish:** a escolha git-as-bus por ref e a existência do `agentd` com (futuro) acesso
a ações privilegiadas são decisões de arquitetura difíceis de desfazer — daí este ADR. O teto de
poder (v14.4) é aprovado **em princípio**, mas **não habilitado** sem o threat-model dedicado.

## Rastreabilidade

- Contrato vivo: `specs/cockpit/spec.md` (9 requisitos; change arquivada em `specs/_archive/2026-06-20-v14-cockpit-foundation/`).
- Plano GSD: `.planning/milestones/v14-cockpit-PLAN.md` (R14-00..09; v14.0→v14.4).
- Blueprint + docs de design: `docs/ideiaos-console/`.
- Cross-link: `credential-isolation`, `agent-authority`, `security-freshness`, `antifragile-gates`, `mcp-hygiene`.
