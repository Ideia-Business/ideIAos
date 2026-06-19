---
name: project-ideia-chat-test-secret-acceptable
description: Ideia Chat (feature gated por FEATURE_IDEIA_CHAT_PROVISIONING_ENABLED no ideiapartner) é um TESTE que NÃO vai a produção — logo o IDEIA_CHAT_SYSADMIN_PASSWORD live no histórico de origin/main é inócuo e a rotação foi DISPENSADA (decisão do usuário 2026-06-18). NÃO re-flagar como pendência de segurança.
metadata: 
  node_type: memory
  type: project
  originSessionId: 42c36737-b3a2-418a-95f3-f4ec2664e30c
---

A auditoria de segurança (`wf_247740a6`, 2026-06-18) sinalizou **ENV-06**: `IDEIA_CHAT_SYSADMIN_PASSWORD` ainda LIVE no histórico de `origin/main` do **ideiapartner**.

**Decisão do usuário (2026-06-18): DESCONSIDERAR.** O Ideia Chat é um **teste e não irá para produção**. A credencial nunca foi/será usada em prod → o valor no histórico git é inócuo. **Rotação dispensada**; reescrever histórico continua descartado (afeta o remoto Lovable compartilhado).

**How to apply:** uma auditoria de secrets futura VAI re-detectar esse valor no histórico do ideiapartner — trate como **aceito por design**, não como gap novo. **Reabrir SÓ se** o Ideia Chat for promovido a produção: aí rotacionar o sysadmin password ANTES de ligar `FEATURE_IDEIA_CHAT_PROVISIONING_ENABLED`. Relacionado: [[feedback-lovable-projects-branch-commit]], [[learning-uncommitted-security-config-ephemeral]].
