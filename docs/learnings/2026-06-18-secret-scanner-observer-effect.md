---
date: 2026-06-18
session_type: security/maintenance
incident: idea-doctor secret FAIL (falso-positivo)
commit: bdbd689
tags: [security, secret-scanner, false-positive, observer-effect, heuristic, idea-doctor]
applies_to_projects: [global]
promote_to_vault: true
---

# Scanner de secrets que lê transcripts faz falso-positivo no próprio dummy — endureça a heurística, não cace transcripts

> O padrão é "scanner que lê logs + dummy de fixture", não o caso específico do
> `idea-doctor`. Aplica-se a qualquer ferramenta que escaneie transcripts/logs por
> segredos e dispare num valor de teste benigno.

## Trigger (quando reler isso)

Quando um scanner de secrets sobre logs/transcripts dá FAIL e o valor sinalizado é um
**dummy de fixture de teste** (não um segredo real) — especialmente se redigir o arquivo
não faz o FAIL sumir, ou se a contagem de arquivos sinalizados **sobe** depois de você
investigar.

## O padrão (abstrato)

Dois fenômenos não-óbvios se combinam:

1. **Observer effect.** Um scanner que lê `~/.claude/projects/**` (ou qualquer store de
   transcripts) escaneia os logs da **própria sessão** que está auditando. Imprimir,
   citar ou copiar o valor plausível durante a investigação o **propaga** para novos
   transcripts (sessão viva + subagentes do workflow de auditoria). Redigir o arquivo
   original vira **whack-a-mole**: a contagem subiu de 1→4 porque a auditoria gerou 3
   cópias novas, incluindo o log da sessão viva (que não dá para limpar enquanto se
   trabalha nele).

2. **Heurística frouxa de plausibilidade.** O filtro `plausible_sk()` só pulava valores
   `<24` chars ou com marcador `example`/`redact`/`…`. Um dummy de 33 chars sem marcador
   (`sk-abcdEFGH1234567890ijklMNOPqrst`, fixture do `test-memory-export.sh`) passava como
   "plausível".

O fix durável ataca **a definição de plausível**, não os sintomas: uma chave de alta
entropia praticamente **nunca** contém uma corrida sequencial/dicionário longa
(`abcdefgh`, `0123456789`, `1234567890`, `qwerty`). Rejeitá-las é conservador — não pula
chaves reais (`sk-proj-…`, `sk-ant-api03-…` continuam detectadas).

## Evidência (concreta — desta sessão)

- `scripts/idea-doctor.sh:225` — adicionado ao `plausible_sk()`:
  `seq = ("abcdefgh", "0123456789", "1234567890", "qwerty"); if any(s in low for s in seq): return False`.
- Doctor antes: `FAIL` no dummy (contagem 1→4 ao auditar). Depois do hardening:
  **65 OK / 0 WARN / 0 FAIL** — `✓ Memória de projeto sem secrets aparentes (scan alta
  confiança)`, **mesmo com os dummies propagados** ainda nos transcripts. Prova de que o
  fix é na heurística, não na limpeza.
- Varredura exaustiva confirmou **zero secret real** comprometido: só anon keys Supabase
  (públicas-por-design, protegidas por RLS, prefixo `VITE_`) e tokens de sessão expirados
  em transcripts locais.

## Regra prática

1. **Nunca reproduza o valor plausível sem mascarar.** `sk-abc…xyz` com `…` já o torna
   não-plausível ao próprio scanner — não re-contamina.
2. **Corrija a heurística na fonte**, não os transcripts. Atacar o sintoma não converge;
   atacar a definição de "plausível" converge e previne recorrência.
3. **Verifique com control test:** prove que chaves reais (`sk-proj-`, `sk-ant-api03-`)
   continuam sendo detectadas após o aperto.
