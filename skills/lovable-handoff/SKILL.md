---
name: lovable-handoff
description: Valida que o projeto atual é gerenciado pela Lovable Cloud, executa o playbook de implantação (typecheck → commit → push → handoff Lovable → postmortem) e produz a comunicação final ao usuário informando se a Lovable precisa puxar/aplicar algo manualmente.
---

# Skill: lovable-handoff

Você é um especialista em **implantações em projetos Lovable Cloud**. Quando esta skill é invocada,
você executa o **playbook obrigatório de implantação** definido em `docs/playbook-implantacao.md`
do projeto atual, com **gate de segurança duplo** para garantir que estamos mesmo em um projeto
Lovable (e não em outro projeto que poderia quebrar com este fluxo).

**Idioma:** Português brasileiro (preferência persistente do usuário).

---

## Pré-condição obrigatória: gate de segurança Lovable

Antes de fazer **qualquer coisa**, valide que este projeto é Lovable. Execute na ordem:

### 1. Buscar marker no repo

```bash
# Marker mais forte: arquivo config Lovable
ls lovable.config.* 2>/dev/null

# Marker padrão dev-setup: seção lovable-deploy-section no AGENTS.md
grep -l "lovable-deploy-section" AGENTS.md 2>/dev/null

# Marker fraco: declaração textual no AGENTS.md
grep -i "Deploy:\s*Lovable\s*Cloud" AGENTS.md 2>/dev/null

# Marker no .aiox-ai-config.yaml
grep -A2 "^deploy:" .aiox-ai-config.yaml 2>/dev/null | grep -i "lovable"
```

### 2. Decisão

| Resultado | Ação |
|-----------|------|
| Marker forte encontrado | Prosseguir com o playbook |
| Apenas marker fraco | Pedir confirmação explícita ao usuário antes de prosseguir |
| Nenhum marker | **BLOQUEAR** — informar ao usuário e pedir confirmação textual ou rodar `bash dev-setup/setup.sh --lovable <projeto>` antes |

**Nunca** assuma que o projeto é Lovable só porque parece ser (Supabase + Vite ≠ Lovable). O gate
existe para evitar aplicar o playbook em projetos não-Lovable e gerar handoffs/instruções erradas.

---

## Playbook (após gate passar)

### Passo 1 — Typecheck

Executar o typecheck do projeto (detectar via `package.json`):

```bash
# Buscar script equivalente:
cat package.json | grep -E '"(typecheck|type-check|check:types)"' || echo "fallback: npx tsc --noEmit"
```

Rodar e **bloquear** se falhar. Mostrar resumo dos erros e parar — não tentar commitar com typecheck quebrado.

### Passo 2 — Commit

```bash
git status -sb
git diff --stat
git log --oneline -5
```

- Stage apenas os arquivos relevantes (`git add <files>`), nunca `git add -A`.
- Mensagem em conventional commits: `fix(area):` / `feat(area):` / `docs:` etc.
- Corpo do commit explica causa raiz se for bug fix.
- Co-author: incluir o agente que de fato escreveu o código.

### Passo 3 — Push

```bash
git push origin <branch>
```

**Imediatamente após o commit, sem esperar pergunta do usuário** — política `feedback-commit-push-automatico`.

### Passo 4 — Handoff Lovable (condicional)

**Detectar se é necessário** olhando os arquivos modificados no commit:

```bash
git show --stat HEAD
```

| Padrão modificado | Handoff obrigatório? |
|-------------------|---------------------|
| `supabase/migrations/*.sql` | **Sim** |
| `supabase/functions/*/index.ts` | **Sim** |
| `.env.example` (sugere novo secret) | **Sim** (descrever no handoff) |
| Apenas `src/**` (frontend) | Não — Lovable puxa main automaticamente |
| Apenas `docs/**` | Não |

Se obrigatório:

1. Copiar `docs/lovable/_TEMPLATE.md` para `docs/lovable/<SLUG>_LOVABLE_HANDOFF.md`.
2. Preencher: migrations a aplicar, edges a redeploy, secrets, queries SQL de verificação, UAT.
3. Linkar ao postmortem se houver.
4. Commit + push separado (`docs(handoff): ...`).

### Passo 5 — Postmortem (condicional)

**Criar se:**
- Bug reaberto / reportado mais de uma vez
- Causa raiz não-óbvia
- Múltiplas tentativas de fix anteriores

**Onde:** `docs/postmortems/<INC-NN>-<slug>.md`.
**Estrutura:** sintoma → causa raiz (com evidência) → correção → UAT → lições.

### Passo 6 — Comunicação final ao usuário

Sempre encerrar com um bloco assim:

```
✅ Typecheck: passou
✅ Commit: <hash> em <branch> ("<mensagem>")
✅ Push: origin/<branch>
{condicional}
✅ Handoff Lovable: docs/lovable/<SLUG>_LOVABLE_HANDOFF.md
✅ Postmortem: docs/postmortems/<INC-NN>-<slug>.md

⚠️ Lovable precisa fazer alguma ação manual?
  → SIM: <ação concreta — aplicar migration X, redeployar edge Y, configurar secret Z>
  → NÃO: puxará main automaticamente, sem ação manual necessária.
```

A linha "Lovable precisa fazer X?" é **obrigatória** mesmo quando a resposta é "não" — o usuário
quer ver explicitamente que você considerou esse ponto (memória `feedback-lovable-deploy-alert`).

---

## Quando esta skill é invocada

- `/lovable-handoff` (explícito)
- Frase do usuário sugerindo conclusão de implantação ("commita e dá push", "fecha essa entrega")
  **e** o gate de segurança confirma que é projeto Lovable
- Após resolução de incidente em projeto Lovable

## Limitações

- **Não aplica migrations na Cloud.** Isso é responsabilidade da Lovable. Esta skill apenas
  prepara o handoff descrevendo o que precisa ser aplicado.
- **Não modifica `src/integrations/supabase/{client,types}.ts`, `.env`, `supabase/config.toml`** —
  arquivos protegidos.
- **Não bypassa o gate de segurança.** Se o projeto não é Lovable, recusar.

## Exemplos de invocação

- `/lovable-handoff` — executa playbook completo no projeto atual
- "commita, dá push e prepara o handoff Lovable" — invocação implícita
- "fecha esse incidente" — invocação implícita se há mudanças em migrations/edges

## Memórias relacionadas

- `feedback_commit_push_automatico.md` — sempre commit + push automático
- `feedback_lovable_deploy_alert.md` — sempre informar se Lovable precisa puxar/aplicar
- `feedback_debugging_disciplina.md` — postmortem se bug recorrente
- `reference_lovable_projects.md` — índice de projetos Lovable conhecidos
