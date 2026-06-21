---
name: learning-automate-the-reminder-not-the-integrity-stamp
description: "Ao automatizar (scheduler/CI) a CONCLUSÃO de um gate que exige atores REAIS distintos, automatize o LEMBRETE — nunca o carimbo (a automação vira um ator sintético e frauda a distinção que o gate protege)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Quando você vai automatizar (cron/scheduler/CI) a **conclusão** de um gate de integridade que exige **≥N atores/máquinas REAIS distintos** (SOAK ≥2 máquinas, quórum multi-assinatura, dual-control), lembre que **o host da automação é ele próprio um ator**. Se a automação executa a ação gateada (o "carimbo"/record), ela injeta um ator sintético e **satisfaz fraudulentamente** o requisito de distinção — defeating exatamente a propriedade que o gate existe para garantir.

Regra: **automatize o LEMBRETE/relatório (read-only), nunca o carimbo.** O movimento ingênuo ("agendo o re-record pra não esquecer") silenciosamente derrota o gate.

**Why:** ao fechar o v13 ([[project-milestone-v13-security-freshness]]) ofereci `/schedule` para o re-record do SOAK. Percebi que uma rotina rodando em host de nuvem, ao gravar o heartbeat, faria um hostname de cloud contar como a "2ª máquina" do v13 (que só tinha 1 máquina real) — fraudando o `≥2 máquinas reais`. Reformulei para um lembrete read-only de status (roda `--status`, nunca `--record`), que diz ao humano o que rodar nas máquinas REAIS. Complementa [[learning-soak-span-is-record-delta-not-wallclock]] (aquele é sobre o span ser delta-de-gravações; este é sobre QUEM grava).

**How to apply:** antes de wirar um scheduler/CI para "finalizar" um gate, pergunte — *"a integridade deste gate depende de QUEM age? Se sim, a automação só pode NOTIFICAR um ator real a agir, nunca agir."* Saída read-only + passo humano/máquina-real explícito.
