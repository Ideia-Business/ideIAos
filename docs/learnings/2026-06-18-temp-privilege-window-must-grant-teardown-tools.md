---
date: 2026-06-18
session_type: discovery
incident: n/a
commit: n/a
tags: [least-privilege, rollback, irreversible-ops, mcp-containment, adversarial-review]
applies_to_projects: [global]
promote_to_vault: true
---

# Janela de privilégio temporário deve conceder as tools do TEARDOWN, não só as do trabalho

> Bom título: descreve o padrão (a janela esquece o cleanup). Mau título: "bug do plano da Fase B".

## Trigger (quando reler isso)

Sempre que você desenhar uma **elevação de privilégio temporária** (lift de `deny`->`ask`, janela `sudo`, role IAM temporária, feature-flag que destrava uma operação perigosa, allowlist por janela) para executar uma ação **difícil ou impossível de reverter** — especialmente quando a operação cria um artefato outward-facing (recurso na nuvem, deploy público, registro externo) e **não existe um "delete" idempotente**.

## O padrão (abstrato)

Ao escopar uma janela de permissão mínima, é natural enumerar as tools a partir do **trabalho** ("o que preciso para FAZER a coisa"). Mas a janela também precisa das tools do **teardown** ("o que preciso para DESFAZER/CONTER a coisa"). Se você concede só as primeiras, o caminho de rollback fica bloqueado pela mesma fronteira de segurança que você levantou — e o bloqueio só se manifesta **depois** de a ação irreversível já ter acontecido (pior momento possível). O least-privilege correto é derivado **de trás para frente**, a partir dos passos de contenção/rollback, não só dos passos de execução.

Corolário: a garantia de "fechamento confirmado" só é verdadeira no happy-path. Sem um **fail-safe idempotente** (panic-close) que rode em qualquer caminho de abort, e sem **persistir o estado da janela** num arquivo fora da memória da sessão, um crash no meio deixa a janela aberta e o artefato órfão.

## Evidência (concreta — desta sessão)

- Artefato: `.planning/milestones/v10-phases/B-sandbox/B-01-PLAN.md` (experimento sandbox `remix_project` da v10 Lovable MCP).
- Verificação adversarial: workflow `wf_ad9c6be1-327` (3 lentes: contenção/medição/custo).
- Achado **CRÍTICO** (2 das 3 lentes, independentes): a Task 0 promovia `remix_project`/`send_message`/`deploy_project` (o trabalho) mas **não** `set_project_visibility`/`move_projects_to_folder` (o cleanup da Task 6) — ambas seguiam em `deny`. Como **não há `delete_project` no MCP** da Lovable, o fork outward-facing ficaria sem nenhum caminho de contenção via MCP após queimar crédito.
- Achados HIGH correlatos: sem fail-safe em abort; sem teto/saldo de crédito antes de queimar; fork podia compartilhar DB de prod.
- Correção (v2 do plano): janela passa a incluir as 2 tools de contenção; bloco `<recovery>` + `B-01-WINDOW-STATE.json` persistido; assert de fechamento endurecido (`deny==19 E ask==0 E allow==0 E disabled`).

## Regra prática derivada

Ao desenhar uma janela de privilégio temporário para uma operação irreversível:
1. **Enumere as tools do teardown de trás para frente** (a partir dos passos de contenção/rollback) e inclua-as na MESMA janela que as tools do trabalho.
2. **Persista o estado da janela** (conjunto de privilégios concedidos + ids dos artefatos criados) num arquivo durável **no momento de abrir** — não confie na memória da sessão.
3. **Escreva um fail-safe idempotente** (panic-close) que feche a janela e contenha o artefato, e que rode em QUALQUER caminho de saída (sucesso E abort). Invariante: nenhuma sessão termina com a janela aberta.
4. **Verifique o fechamento com assert binário positivo-E-negativo:** não só "N privilégios em deny", mas também "0 em ask E 0 em allow" — uma reaplicação malfeita pode ter o count certo e uma duplicata destravada.
5. Se a operação cria artefato outward-facing sem delete idempotente, **registre o id do artefato como pendência durável de limpeza manual** (sobrevive entre sessões).

## Falsos positivos / armadilhas

- Operações **reversíveis por `git`/transação local** não precisam disso — o rollback já é barato e não passa pela fronteira de privilégio. Aplica-se a artefatos **externos/irreversíveis**.
- Não confundir com "conceda tudo por garantia": a janela continua mínima — apenas o conjunto mínimo agora inclui o teardown, não só o trabalho.

## Cross-references

- `[[learning-dogfood-review-tool-catches-own-defect]]` — rodar a ferramenta adversarial sobre o próprio artefato pega defeitos nele mesmo (aqui: a verificação pegou o furo no próprio plano).
- `[[project-lovable-mcp-v10-candidate]]` — milestone v10; Fase B é o gate de toda escrita.
- `.planning/milestones/v10-phases/B-sandbox/B-01-PLAN.md` — plano corrigido (v2).
- Rule `ideiaos-common-antifragile-gates.md` — fail-safe em hooks (exit 0) é o mesmo princípio aplicado a I/O.

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-18 — motivo: padrão `[global]` (qualquer elevação de privilégio temporário).
- [x] Promovido para Obsidian vault em 2026-06-18 — motivo: síntese cross-projeto.
- [ ] Aplicado retroativamente em outros learnings.
