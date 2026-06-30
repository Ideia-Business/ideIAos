---
name: coarse-grouper-view-bypasses-fine-scope-mask
description: Mascaramento por-campo por escopo FINO (projeto) é furado por uma view de agrupador GROSSO (máquina) que expõe payload bruto/agregado — agrupador grosso = admin-only ou re-particionar no nível fino
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2bc6b4ee-e331-4ec9-ae8f-bed36cd18a66
---

Ao desenhar RLS/mascaramento multi-nível, o mascaramento cuidadoso de uma view de
granularidade FINA (ex.: `api_key_v` mascara nome de chave critical por
`user_project_scope`) é **contornado** por qualquer view de granularidade mais
GROSSA que exponha o mesmo dado em forma bruta/agregada. No schema do Plano de View
(P3, v16/R16-02), `machine_snapshot_v` usava `can_see_machine` (true se o dev tem
**qualquer** projeto na máquina) e devolvia `payload_json` cru — o dump da máquina
inteira inclui projetos FORA do escopo do dev. Um dev com escopo em 1 projeto lia o
recon de todos os projetos daquela máquina, anulando o mascaramento fino de
`api_key_v`/`project_v`. Mesmo mecanismo em `mcp_connection_v` (path completo) e
eventos machine-level. **Fix: agrupador grosso → admin-only** (ou re-particionar a
ingestão no nível fino, com `project_slug`, trocando `can_see_machine`→`can_see_project`).

**Why:** a superfície de segurança de um schema é o MÍNIMO de todas as views, não o
cuidado da view mais protegida. Uma view fina blindada não vale nada se outra view
grossa entrega o mesmo dado cru. Design solo tende a blindar a view "óbvia" e
esquecer o agrupador grosso; foi exatamente o achado CRITICAL/HIGH que `rls-reviewer`
+ `security-reviewer` pegaram e o primeiro design não viu.

**How to apply:** ao revisar RLS/mascaramento, audite TODAS as views por
payload bruto/agregado que cruze a fronteira do escopo fino — não só a view que você
mascarou com carinho. Agrupadores grossos (máquina/tenant/org) que expõem dump →
admin-only por default, ou re-particione no nível fino. Rode verificação adversarial
ANTES de aplicar qualquer RLS (não confie no design solo). Liga a
[[review-own-design-before-build-with-refutation]] e [[antitheater-gate-blind-spot-happy-path]].
