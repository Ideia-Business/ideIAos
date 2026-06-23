---
name: learning-mitigated-label-must-not-outrun-precondition
description: "Não rotule um blocker de segurança como [MITIGADO] enquanto a PRÉ-CONDIÇÃO da mitigação não for verificada por exit-code — classifique [BLOCKER-CONDICIONAL] e sonde a capacidade do terceiro (read-only) antes de rebaixar"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4ccbd936-70a0-46eb-ba25-4466087d60d1
---

Quando uma mitigação de segurança **repousa sobre uma pré-condição** (o terceiro/org/runtime precisa ter uma capacidade habilitada), o **rótulo de status da mitigação não pode ultrapassar a verificação dessa pré-condição**. Marcar `[MITIGADO]` apoiado num mecanismo cuja pré-condição é "a confirmar" é otimismo que mascara o risco real — o blocker pode ter regredido a aberto sem ninguém ver.

Regra: enquanto a pré-condição não for **provada por exit-code**, o rótulo correto é **`[BLOCKER-CONDICIONAL]`** (gateia a fase por um **teste-negativo real**), não `[MITIGADO]`. E a maioria dessas pré-condições de terceiro é **sondável read-only em segundos** — sonde antes de rotular (liga a [[learning-missing-tool-not-cant-verify]]: "ferramenta/capacidade ausente" é verificável, não presumível).

**Why:** no v15 ([[project-milestone-v15-team-platform]]) eu havia gravado a decisão "manter conta GitHub compartilhada + token fine-grained-PAT por-estação" como **MITIGADO** dos blockers de Reversão e blast-radius. Um review adversarial + um probe `gh` (org `Ideia-Business` = plano FREE; credencial em uso = **token OAuth clássico org-wide**; endpoint owner de gestão FG-PAT = **404 → não provisionado**) provaram que a pré-condição (org habilitar+emitir FG-PATs) **NÃO está satisfeita** — logo o blast-radius é org-wide HOJE e a mitigação é só um ALVO. Reclassifiquei para `[BLOCKER-CONDICIONAL]`. O `[MITIGADO]` precedia a verificação que o sustentava. Mesma família de [[learning-automate-the-reminder-not-the-integrity-stamp]] (não deixar um movimento conveniente derrotar a propriedade que o gate protege) e do piso `operating-discipline` §6 (verify, don't assume).

**How to apply:** ao rebaixar/encerrar um achado de segurança, pergunte — *"de que pré-condição EXTERNA esta mitigação depende, e ela está provada por exit-code?"*. Se não está: rótulo `[BLOCKER-CONDICIONAL]` + sonda read-only (`gh api`, status de plano/feature) AGORA + teste-negativo como gate da fase. Nunca `[MITIGADO]` sobre pré-condição presumida — e se a sonda falhar, re-abra a decisão com o trade-off real (pior caso) exposto, não o otimista.
