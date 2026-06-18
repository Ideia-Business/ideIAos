---
name: learning-temp-privilege-window-teardown-grants
description: "Janela de privilégio temporário p/ operação irreversível deve conceder as tools do TEARDOWN/cleanup, não só as do trabalho — senão o rollback fica bloqueado pela própria fronteira de segurança, e só falha DEPOIS da ação irreversível"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Ao escopar uma **elevação de privilégio temporária** (lift `deny`->`ask`, janela `sudo`, role IAM temporária, feature-flag que destrava operação perigosa) para uma ação **difícil/impossível de reverter** — sobretudo quando cria artefato outward-facing sem "delete" idempotente:

- O least-privilege correto é derivado **de trás para frente**, a partir dos passos de **contenção/rollback**, não só dos de execução. Conceder só as tools do trabalho deixa o cleanup bloqueado pela mesma fronteira que você levantou — e o bloqueio só aparece **depois** da ação irreversível (pior momento).

**Why:** descoberto na verificação adversarial (workflow `wf_ad9c6be1-327`, 2 de 3 lentes independentes) do plano da Fase B do v10 Lovable MCP: a janela promovia `remix_project`/`send_message`/`deploy_project` mas esquecia `set_project_visibility`/`move_projects_to_folder` (o cleanup). Como o MCP Lovable **não tem `delete_project`**, o fork ficaria órfão/público sem caminho de contenção. Eco de [[learning-dogfood-review-tool-catches-own-defect]] (a ferramenta adversarial pega o defeito no próprio artefato).

**How to apply:**
1. Enumere as tools do teardown e inclua-as na MESMA janela das do trabalho.
2. Persista o estado da janela (privilégios + ids de artefatos) num arquivo durável AO ABRIR — não confie na memória da sessão.
3. Escreva um fail-safe idempotente (panic-close) que rode em QUALQUER saída (sucesso E abort). Invariante: nenhuma sessão termina com a janela aberta.
4. Verifique o fechamento com assert binário positivo-E-negativo (deny==N E ask==0 E allow==0), não só o count.
5. Artefato outward-facing sem delete idempotente -> registre o id como pendência durável de limpeza manual.

Reversível por git/transação local NÃO precisa disso (rollback barato, não passa pela fronteira). Relaciona-se a [[project-lovable-mcp-v10-candidate]] e à rule antifragile-gates (fail-safe). Learning de repo: `docs/learnings/2026-06-18-temp-privilege-window-must-grant-teardown-tools.md`.
