---
name: lovable-mcp
description: Camada de verificação read-only sobre o MCP server da Lovable — verify-deploy (detecta deploy-drift cruzando o commit da Cloud com origin/main) e detect-hotfix (acha edições feitas no chat da Lovable que não passaram pelo Git). Aditiva ao /lovable-handoff, 0 crédito, 0 escrita; mutações são bloqueadas no harness e ficam com @devops.
---

# SOURCE: IdeiaOS v10 | adapted: — (skill nativa)
# Skill: lovable-mcp

**Idioma:** Português brasileiro.

> O `/lovable-handoff` é o **playbook de implantação** (plano-GitHub maduro). O `/lovable-mcp`
> **soma** a ele uma camada de **verificação programática** via o MCP server da Lovable: o que hoje
> é manual e cego (comparar "o que está no ar" vs `main`, achar correção feita no chat que não foi
> pro Git) vira um **verdict binário, não-alucinável**. Esta é a **v1 read-only** (Fase A do
> milestone v10): só lê. Nada que escreve, dirige o agente Cloud ou toca o DB roda aqui — essas
> tools estão **bloqueadas no harness** e são fluxo `@devops` (ver `mcp-protocol.md`).

Postura formal: `docs/decisions/v10-lovable-mcp-readfirst-containment.md` (ADR).

---

## O que é — e o que NÃO é

### O que é
A **camada de verificação read-only** do plano Lovable. Dois verbos, ambos 100% git-read + leitura
de metadados via MCP (zero crédito, zero escrita):

- **`verify-deploy`** — o que está deployado bate com `origin/main`? (mata o **incidente nº1**, deploy-drift)
- **`detect-hotfix`** — alguma edição foi feita no chat da Lovable e nunca virou commit no Git? (mata o **incidente nº3**, hotfix inline)

### O que NÃO é

| Confusão comum | Camada correta |
|----------------|----------------|
| Executar o playbook de deploy (typecheck → commit → push → merge → handoff) | `/lovable-handoff` |
| Aplicar migration / rodar SQL em prod | `query_database` é **opt-in por projeto** (denied por padrão; habilitado onde o projeto usa DB de prod — ex.: ideiapartner). **Write gated por aprovação humana do SQL.** Esta skill não o chama — é read-only. |
| Dirigir o agente Cloud (`send_message`) / publicar (`deploy_project`) | **@devops**, gated, Fase D (v3) — nunca a partir desta skill |
| Reconciliar um hotfix detectado de volta ao Git | trabalho de `/lovable-handoff` + decisão humana; esta skill **só reporta** |

`/lovable-mcp` **não substitui** o `/lovable-handoff` — é aditiva. O handoff continua sendo o
playbook; o MCP só dá olhos programáticos sobre o estado real da Cloud.

---

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/lovable-mcp verify-deploy` · `/lovable-mcp detect-hotfix` |
| Pela Deia | `Deia, confere se o que está no ar bate com a main` |
| Linguagem natural | `o deploy da Lovable está atualizado?` · `tem hotfix feito no chat que não veio pro git?` |
| Encadeado no handoff | passo "checar deploy" do `/lovable-handoff` → `/lovable-mcp verify-deploy` |

---

## Pré-condições (nesta ordem, antes de qualquer verbo)

### 1. MCP on-demand (off-by-default)
O Lovable MCP é classificado **High/Critical** (`mcp-hygiene`) e fica **desligado por default**
(`disabledMcpServers`). Habilite-o só na janela de trabalho. As ~18 tools mutantes continuam em
`permissions.deny` mesmo com o servidor ligado — ver `references/mcp-protocol.md`.

### 2. Gate de projeto Lovable
Mesmo gate do `/lovable-handoff`: confirme que o repo atual é Lovable (marker forte:
`lovable.config.*`, seção `lovable-deploy-section` no `AGENTS.md`, ou `.aiox-ai-config.yaml`).
Se não for, **recuse** — esta skill não faz sentido fora de projeto Lovable.

### 3. Resolver de escopo (R10-02) — identity-aware, operacional, 2 tiers
> É **escopo/foco** do IdeiaOS, **não** privacidade dura. Privacidade real = `visibility: draft`
> manual no painel, fora deste modelo. Confia-se no time.

Determine se o projeto-alvo está **in-scope** antes de ler seus dados:

```bash
IDEIAOS_DIR="${IDEIAOS_DIR:-$HOME/.ideiaos}"
. "$IDEIAOS_DIR/source/lib/lovable-mcp.sh" 2>/dev/null \
  || { echo "helper lovable-mcp ausente — opere em modo manual"; }
```

1. `get_me` → guarde `MY_ID` (a conta Lovable conectada; **≠** o e-mail git).
2. Descubra a associação à pasta canônica **"Grupo Ideia"**:
   - workspace: `2NHPnABxF0jdSX3qVLCw` · folder: `fold_01kvdc18tgf86ts7s0tdx6hges`
   - `list_projects(workspace_id="2NHPnABxF0jdSX3qVLCw", folder_id="fold_01kvdc18tgf86ts7s0tdx6hges")`
     → o projeto-alvo está nessa lista? `IN_FOLDER=1`, senão `0`.
3. `get_project(project_id)` → `CREATED_BY` (dono).
4. Resolva e respeite o veredito:
   ```bash
   lovable_resolve_scope "$PROJECT_ID" "$CREATED_BY" "$IN_FOLDER" "$MY_ID"
   #  in:todos | in:pessoal | in:override | out:override | out
   ```
   - `in:*` → prossiga. `out`/`out:override` → **recuse com mensagem clara** (não silenciosamente):
     _"projeto fora do escopo IdeiaOS deste resolver (tier `out`); ajuste `lovable-scope.yaml` se for intencional."_
   - Exceções: `lovable-scope.yaml` na raiz do produto (`force_in:` / `force_out:` por `project_id`).
     Não crie o arquivo se não houver exceção (criação preguiçosa).

---

## Verbo `verify-deploy` — deploy-drift (incidente nº1)

**Pergunta:** o que a Lovable tem como último estado deployado bate com `origin/main`?

1. Garanta `git fetch origin` recente (a comparação é contra `origin/main`, não o working tree).
2. `get_project(project_id)` → extraia o SHA do último estado (campo de commit/deploy reportado;
   na doc varia entre `latest_commit_sha`/`commit_sha`/`head`). Guarde como `CLOUD_SHA`.
3. Classifique com verdict binário (não confie em ler o git "de olho"):
   ```bash
   VERDICT="$(lovable_classify_deploy "$CLOUD_SHA")"   # IN_SYNC|CLOUD_BEHIND|CLOUD_AHEAD|SHA_ABSENT|NO_REPO
   ```
4. Se divergente (qualquer coisa ≠ `IN_SYNC`), traga o detalhe com `get_diff` (read-only) e/ou
   `git log CLOUD_SHA..origin/main --oneline`.
5. Reporte conforme a tabela:

| Verdict | Significado | Ação sugerida (read-only) |
|---------|-------------|---------------------------|
| `IN_SYNC` | deploy == `main` | ✅ nada a fazer |
| `CLOUD_BEHIND` | fix está na `main`, **não no ar** → deploy-drift | sugerir "Lovable → Update" (humano/@devops); listar `git log CLOUD_SHA..origin/main` |
| `CLOUD_AHEAD` | Cloud tem commit à frente da `main` | investigar: provável hotfix-in-cloud → rodar `detect-hotfix` |
| `SHA_ABSENT` | SHA da Cloud não existe no git local | **candidato** a hotfix OU mismatch de namespace (ver Limitações) — **não afirmar drift** |
| `NO_REPO` | sem repo / `origin/main` ausente | abortar com mensagem; rodar `git fetch` |

6. Escreva o relatório e **gateie** (antifrágil):
   ```bash
   lovable_gate_report "$REPORT_PATH" "verify-deploy" || echo "relatório vazio — não confiar" >&2
   ```

## Verbo `detect-hotfix` — correção no chat fora do Git (incidente nº3)

**Pergunta:** alguma edição feita pelo agente Cloud (chat da Lovable) nunca virou commit no `main`?

1. `list_edits(project_id)` → lista de edições com `commit_sha` + prompt. Guarde os SHAs.
2. Para cada `commit_sha`, verdict binário de presença no git local:
   ```bash
   if lovable_sha_present "$EDIT_SHA"; then echo "synced"; else echo "candidato"; fi
   ```
3. Reporte cada SHA **ausente** como **candidato a hotfix não-sincronizado** — com o prompt
   associado (o que foi pedido no chat) para dar contexto. **Não reconcilie sozinho.**
4. Gate do relatório (`lovable_gate_report`).

> Reconciliação (trazer o hotfix pro Git) é decisão humana + trabalho do `/lovable-handoff`.
> Esta skill **só acende a luz**.

---

## Contenção (resumo — detalhe em `references/mcp-protocol.md`)

- **Read-only de verdade:** nenhum verbo chama `send_message`, `deploy_project`, `query_database`,
  `set_*_knowledge`, `remix_project` ou qualquer tool mutante. Se algum passo "precisar" escrever,
  **pare e delegue a @devops** — não há caminho de escrita na v1.
- **Harness-deny:** as 18 tools mutantes (crédito/deploy/estrutura) estão em `permissions.deny`.
  `query_database` é **opt-in por projeto** — denied por padrão, permitido onde o projeto habilitou DB
  de prod (ex.: ideiapartner); como roda SQL arbitrário, o write fica gated por **aprovação humana do
  SQL**. Só `@devops` promove um tool ID mutante a `ask` (prompt humano sempre, nunca `allow` silencioso).
- **Escopo (operacional) ≠ contenção (dura):** o resolver de escopo é foco-do-IdeiaOS; o harness-deny
  e o toggle de workspace são a fronteira de capability. Um não substitui o outro.

## Limitações

- **`SHA_ABSENT` / `CLOUD_AHEAD` não são prova de hotfix.** O namespace do `commit_sha` da Cloud
  (mirror GitHub vs repo Lovable interno) **ainda não foi medido** — é o objeto da **Fase B**
  (sandbox `remix_project`). Até lá, reporte como **candidato**, nunca como certeza.
- **Shallow clone falseia `SHA_ABSENT`.** Num clone raso, um SHA real pode parecer ausente. O helper
  detecta (`lovable_is_shallow`) e avisa no stderr; rode `git fetch --unshallow` (ou trate o veredito
  como inconclusivo) antes de concluir hotfix.
- **Não escreve nada.** Não aplica migration, não dá Update/Publish, não dirige o agente Cloud,
  não reconcilia hotfix. Tudo isso é fase posterior e/ou `@devops`.
- **Não substitui o `/lovable-handoff`.** É a camada de verificação, não o playbook de deploy.
- **Sem schema-check na v1.** Ler o schema real de prod (`query_database`/`information_schema`) é
  **v2 (Fase C)**, ask-gated sob @devops.

## Exemplos de invocação

- `/lovable-mcp verify-deploy` — "o que está no ar bate com a main?" no projeto atual
- `/lovable-mcp detect-hotfix` — "tem correção feita no chat que não veio pro git?"
- "confere se o deploy da Lovable está atualizado antes de eu mandar o cliente testar" — implícito → `verify-deploy`

## Memórias relacionadas

- `project_lovable_mcp_v10_candidate.md` — milestone v10, forks fechados, modelo de escopo
- `feedback_lovable_projects_branch_commit.md` — projetos Lovable não auto-commitam em main
- `reference_lovable_projects.md` — índice de projetos Lovable conhecidos

## Verificação

- [ ] Gate de projeto Lovable passou (senão recusou)
- [ ] `get_me` + resolver de escopo rodaram **antes** de ler dados do projeto; `out` foi recusado com mensagem
- [ ] Nenhuma tool mutante foi chamada (verify-deploy/detect-hotfix são read-only)
- [ ] Verdicts vieram do helper (`lovable_classify_deploy` / `lovable_sha_present`), não de leitura "a olho" do git
- [ ] `SHA_ABSENT`/`CLOUD_AHEAD` reportados como **candidato**, com o caveat de namespace (Fase B)
- [ ] Relatório final gateado por `lovable_gate_report` (test -s), não pelo Read tool
