---
name: feedback-readme-update-no-final
description: "Ao final de TODA implantação no IdeiaOS, atualizar o README do GitHub com todos os novos recursos e instruções"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Ao final de **toda implantação** (cada milestone/conjunto de fases executado) no IdeiaOS, **atualizar o README.md** do projeto no GitHub com todos os novos recursos, componentes e instruções gerais de uso — não só a lista de componentes (que o `check-readme-sync.sh` já força), mas a **narrativa de uso**: como acionar os recursos novos, exemplos, seções de instruções.

**Why:** o usuário quer que o README seja sempre a vitrine fiel e completa do IdeiaOS no GitHub. O hook de README-sync garante que componentes apareçam, mas não garante que as INSTRUÇÕES e a narrativa de uso estejam atualizadas. Pedido explícito em 2026-06-16.

**How to apply:** como passo final de fechamento de implantação (junto com STATE/handoff/vault/push), revisar e atualizar o README com: novos recursos + como usá-los + instruções gerais. Tratar como parte obrigatória do protocolo de fechamento, igual a [[feedback-session-closing-vault]]. Vale para o milestone v6 (fases 23/24/25/27 + indicações GSD×OpenSpec) quando for fechado.
