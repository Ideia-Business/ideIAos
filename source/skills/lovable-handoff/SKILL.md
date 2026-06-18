---
name: lovable-handoff
description: Valida que o projeto atual é gerenciado pela Lovable Cloud, executa o playbook de implantação (typecheck → commit → push → merge main → handoff Lovable → postmortem) e produz a comunicação final ao usuário informando se a Lovable precisa Update/Publish.
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

# Marker padrão IdeiaOS: seção lovable-deploy-section no AGENTS.md
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
| Nenhum marker | **BLOQUEAR** — informar ao usuário e pedir confirmação textual ou rodar `bash IdeiaOS/setup.sh --lovable <projeto>` antes |

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

### Passo 3b — Merge em `main` (obrigatório antes de Update Lovable)

**Mandato global (todos os projetos Lovable):** PR aberto ≠ deployável. Lovable Update só lê `main`.

```bash
gh pr view <N> --json state,mergedAt
# Se OPEN: gh pr merge <N> --merge (salvo usuário pediu "só abra PR")
git fetch origin && git log origin/main -1 --oneline
git show origin/main:<arquivo-alterado> | head   # smoke: fix está no main
```

Atualizar `.lovable/SYNC_TRIGGER.json` (`main_head`) + push `main` quando o projeto usar gatilho.

**Proibido** instruir "Lovable → Update" enquanto `state != MERGED`.

> **Verificação programática (read-only, aditiva):** `/lovable-mcp verify-deploy` confirma se o que
> está no ar bate com `origin/main` (deploy-drift); `/lovable-mcp detect-hotfix` acha correção feita
> no chat da Lovable que não veio pro Git. Não substitui este playbook — só dá olhos sobre a Cloud.

Memória: `learning_lovable_agent_entrega_merge_main_obrigatorio.md`

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

### Passo 6 — Comunicação final ao usuário (modelo canônico)

**Sempre** seguir o formato canônico em `docs/lovable/conclusao-implantacao.md` do projeto.
São 6 blocos obrigatórios + 1 condicional + 1 opcional:

1. **Cabeçalho** — `# ✅ <INC-NN | FEATURE> — <título>` + linha commit/branch/tipo
2. **Entendimento do problema** — sintoma + evidência confirmada (não copiar pedido literal)
3. **Causa raiz** — com `arquivo:linha`, separar `Gap A / Gap B` se cumulativos
4. **Correção aplicada** — tabela `arquivo | mudança | porquê`, matriz de comportamento se aplicável
5. **Verificação executada** — checklist literal (typecheck, testes, commit, push, handoff, postmortem)
6. **Ação necessária ⚠️** — tabela `Quem | O quê | Onde`. **OBRIGATÓRIO mesmo quando "Nenhuma"** —
   sempre explicitar SIM/NÃO se Lovable/humano precisa fazer algo (memória `feedback-lovable-deploy-alert`).
7. **Aprendizado registrado** (condicional) — preenchido pelo Passo 7 abaixo se houve learning
8. **Próximo passo sugerido** (opcional) — 1 frase, só se houver ação imediata

Tamanho-alvo: 30-60 linhas. Tom: direto, técnico, sem narrativa. Sem bloco "Resumo" redundante.

### Passo 7 — Extrair aprendizado (`/extract-learnings`)

Após o bloco 6 da resposta, invocar a skill `extract-learnings` (ou aplicar seu pipeline):

1. **Gate** — replicável? não-óbvio? estável? Se as 3 = sim, prosseguir; senão, registrar
   `📚 Sessão sem aprendizado registrável (operacional / óbvio / efêmero).`
2. **Extrair padrão abstrato** (não citar nomes específicos de tabelas/colunas — abstrair).
3. **Gravar** `docs/learnings/YYYY-MM-DD-<slug>.md` usando `docs/learnings/_TEMPLATE.md`.
4. **Decidir promoção** — se `applies_to_projects: [global]`, sincronizar com memória Claude global.
5. **Preencher bloco 7** da resposta final:
   ```
   📚 Learning registrado: `docs/learnings/YYYY-MM-DD-<slug>.md` — <título curto>
      Tags: [tag1, tag2]  ·  Aplica-se a: [<projeto> | global]
   ```

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
