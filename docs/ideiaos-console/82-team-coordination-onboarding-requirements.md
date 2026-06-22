# 82 — Camada de Coordenação & Experiência do Time (requisitos capturados)

**Status:** **REQUISITOS CAPTURADOS** (2026-06-22) — a serem tecidos em `81-team-platform-control-DESIGN.md` e no ADR `v15-cockpit-split-plane-control-plane.md` quando o workflow de re-escopo cair. Aditivo à plataforma de time; não revoga nada.
**Origem:** sessão de design 2026-06-22 — o operador (CTO) detalhou a camada de coordenação que evita duplicação e colisão entre devs.
**Princípio-âncora:** *delegar o TRABALHO sem delegar o CONTROLE* — e, agora, **sem os trabalhos colidirem entre si**.

---

## A camada (acima da plataforma de time — P3/P5)

A plataforma (planos P0..P5) dá acesso controlado e visão. Esta camada dá **experiência do dev** + **coordenação de trabalho** para que N devs nos mesmos projetos não dupliquem nem colidam.

### R-COORD1 — Guia de onboarding DINÂMICO (vivo, por dev)
Ao primeiro login, o dev vê um **guia dinâmico** (não estático) que mostra, fase a fase, **o que está sendo conectado** e o estado de cada conexão:
- o que rodar para instalar todas as dependências do IdeiaOS na máquina dele (o "canivete suíço");
- o registro da estação (hash único) → **PENDENTE** → aprovação do admin (a alavanca de **Admissão**);
- o vínculo de cada ferramenta: GitHub (conta compartilhada), Cursor, Claude, Lovable — cada um com status ✅/⏳/❌ **ao vivo** (Pilar B: o vínculo é registrado no cockpit; o valor do token fica local).
O guia é **idempotente e re-entrante**: se o dev volta, ele mostra só o que falta. É a materialização, em produto, do ciclo de vida do usuário.

### R-COORD2 — Visão de saúde por-operador (cockpit do dev)
Cada dev tem sua **versão-operador** do cockpit com o "OK" de saúde:
- saúde do **IdeiaOS** e das **ferramentas (canivete suíço)** na máquina dele (idea-doctor, agentd, autosync, gates);
- distinto do read-model global do CTO — é a saúde **da estação dele**, honesta (frescor "verificado há Xs").

### R-COORD3 — Quadro de status dos projetos + planos futuros + "eu pego isto"
O dev vê o **status de cada projeto que participa** + os **planos futuros**, e **marca o que quer seguir/fazer**:
- ao marcar, os **demais veem onde cada um está trabalhando** → evita duplicação;
- o que ele pega é **anotado e entra no "plano maior"** (GSD `.planning/` + STATE/handoff do projeto-alvo).

### R-COORD4 — Marcação de itens de handoff/plano (anti-duplicação)
Os **handoffs e planos** ganham **marcação de claim**: o operador marca os itens que está trabalhando.
- item marcado por A fica visível como "em andamento por A" para B, C…;
- evita duas pessoas pegarem o mesmo item do handoff/plano.

### R-COORD5 — Controle de tarefas NÃO-conflitantes (anti-colisão de arquivo) ⚠️ a peça afiada
Planos e handoffs precisam de **controle de atividades que não conflitam** — em especial **evitar dois operadores no mesmo arquivo** (editar/commitar o mesmo arquivo).
- **Insight de design (cravar):** **branch isola, mas NÃO previne** — duas branches podem ambas editar `foo.ts` e só colidir no merge. Logo a prevenção exige uma **camada de coordenação ACIMA do git**: um **claim/soft-lock por arquivo/área**, visível no cockpit, que **alerta quando duas reivindicações se sobrepõem**.
- **Soft-lock, não hard-lock:** advisory (o dev pode sobrepor conscientemente), mas a **visibilidade** mata a maioria das colisões antes do commit. Granularidade: arquivo e/ou área/módulo (a definir — fork).
- Liga-se ao concern #1 (branches concorrentes) e ao R-COORD4 (o claim de tarefa carrega o claim de arquivo).

---

## Integração com o "plano maior" e o futuro

- **Plano maior:** tudo que o dev marca/pega alimenta o GSD (`.planning/`) e os handoffs do projeto-alvo — a coordenação **não** é um silo novo, é uma superfície sobre o que o IdeiaOS já registra (STATE.md, CONTINUATION_HANDOFF.md, `.planning/`).
- **Vault Obsidian (segundo cérebro):** claims, status, atribuições e relatórios por-usuário fluem ao Vault (a alavanca **Visão** + concern #2) — "entendendo e conectando todos os pontos, não deixando nada passar".
- **DEV Tasks (futuro):** o orquestrador IA (super skill DEV) **consome** este modelo de tasks/claims — ele pega tarefas não-conflitantes, executa, e deixa pronto para o dev humano revisar e subir. O claim-por-arquivo de R-COORD5 é o que permite ao orquestrador paralelizar sem colidir.

---

## Forks abertos (do operador) — para o /grelha

1. **Granularidade do soft-lock** (R-COORD5): por arquivo · por módulo/área · por ambos (recomendado: ambos, com alerta).
2. **Hard-lock vs soft-lock**: bloquear de fato vs só alertar (recomendado: soft/advisory — visibilidade, não burocracia).
3. **Onde mora o quadro de claims**: tabela no Plano de View (P3) vs no próprio handoff/`.planning` do projeto-alvo, espelhado em P3 (recomendado: fonte no projeto-alvo, espelho em P3 — coerente com "git-as-bus espinha, P3 cache").

## Cross-links
- `81-team-platform-control-DESIGN.md` (a plataforma que esta camada estende).
- `v15-cockpit-split-plane-control-plane.md` (ADR — Pilar A/B, as 5 alavancas).
- `40-data-model-telemetry-mesh.md` (read-model), `30-security-credential-isolation.md` (RLS/RBAC).
- Rules: `operating-discipline` (anti-duplicação = anti-retrabalho), `agent-authority`, `credential-isolation`.
