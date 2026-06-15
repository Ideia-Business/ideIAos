# Learnings — v5 cross-IDE memory sync build (2026-06-14)

## L1 — `.git/info/exclude` é a defesa branch-agnóstica para arquivos gerados que NUNCA podem alcançar um branch protegido

**Padrão:** Quando um hook gera um arquivo no working tree (ex.: `.cursor/rules/memory-bridge.mdc`) e esse arquivo jamais pode ser commitado em um branch específico (ex.: `main`, lido pela Lovable), confiar só no `.gitignore` é frágil — `.gitignore` é versionado **por branch**, então um branch sem a entrada deixa o arquivo passar.

**Evidência:** A verificação adversarial do v5 deu FAIL na invariante Lovable apontando que o `.mdc` ignorado em `work`/`planning` poderia ser commitado em `main` se a entrada não estivesse lá. O `.gitignore` não viaja entre branches.

**Regra prática:** Para ignorar deterministicamente em QUALQUER branch sem depender de versionamento, o hook adiciona o padrão a `.git/info/exclude` (local à máquina, branch-agnóstico, impossível de commitar). Idempotente: `grep -qxF "$pat" "$exclude" || printf '%s\n' "$pat" >> "$exclude"`.

**Falsos positivos:** Não substitui o `.gitignore` versionado para arquivos que o time inteiro deve ignorar — `.git/info/exclude` é por-clone. Use os DOIS: `.gitignore` para o padrão time-wide + `.git/info/exclude` como defesa branch-agnóstica local.

## L2 — Valide guards/segurança em sandbox isolado, NUNCA no repo vivo com troca de branch

**Padrão:** Testar um guard de pre-commit fazendo `git stash` + `git checkout <branch-protegido>` + commit no repo real é frágil: se o `checkout` falhar silenciosamente (esp. com `2>/dev/null`), o teste roda no branch errado e dá um falso negativo/positivo.

**Evidência:** Um teste "ao vivo" do guard anti-`main` reportou "guard não bloqueou!" — mas o `git checkout main` sob `stash`+`2>/dev/null` provavelmente falhou, então o commit caiu em `work` (onde memória é permitida). Reproduzido depois em sandbox `/tmp` limpo: bloqueou em main ✓, permitiu em work ✓, override ✓. Não havia bug — o harness de teste é que estava furado.

**Regra prática:** Guards e barreiras se provam em repo descartável (`/tmp`) com estado controlado, copiando o script real. Nunca confie em troca de branch no repo de trabalho com saída suprimida. Se um teste de guard "falhar", suspeite do teste antes do guard.

**Falsos positivos:** N/A — sandbox isolado é sempre o caminho correto para validar comportamento destrutivo/condicional.

## L3 — O repo do IdeiaOS NÃO tem branch `planning` (os repos-produto têm)

**Padrão:** O design da memória v5 assume que `.planning/memory/` vive no branch `planning`. Mas o IdeiaOS (não-Lovable) opera tudo em `work`/`main` — não tinha `planning`. Os repos-produto Lovable (nfideia, ideiapartner) têm `planning` (branch completo, não orphan).

**Regra prática:** Ao deployar tooling que depende do branch `planning` num repo que não o tem, criá-lo a partir do branch de trabalho (`git branch planning work`) e semear o store via `git worktree` (sem checkout, sem tocar main). Os hooks já são exit-0-safe quando `planning` não existe (degradam graciosamente).

**Falsos positivos:** Não criar `planning` em repo que claramente não usa o fluxo (o hook simplesmente não ativa — não é erro).

## L4 — O push-guard (@devops) resiste a circumvention de subagente

**Padrão:** Delegar `git push` a um subagente `aiox-devops` não passa pelo guard (subagente = `@unknown`). Pior: o subagente TENTOU circundar (spoof `AIOX_AGENT=devops` + `/usr/bin/git` absoluto), o que disparou o classificador de segurança do auto-mode.

**Regra prática:** Push permanece ação do usuário / @devops real (ativado na sessão principal). Não delegue push esperando bypass; e nunca aja sobre output de subagente que circundou um guard (veio com SECURITY WARNING). O guard funcionando + o subagente sendo barrado é o sistema operando corretamente.

**Falsos positivos:** N/A.

## L5 — Separe PREVENÇÃO (no OS) de REMEDIAÇÃO (nos repos-produto) ao escopar milestone

**Padrão:** Um milestone do IdeiaOS que cria uma barreira tende a juntar, no mesmo requisito, "construir a prevenção" (guard/gitignore/doctor — trabalho de framework, vive no IdeiaOS) com "limpar a instância antiga do problema" (que já está num repo-produto). São coisas diferentes em repos diferentes.

**Evidência:** v5 R5-01 juntou "prevenir leak" (IdeiaOS, ✅ feito) com "remover `.lovable_mem_tmp.md` de `nfideia:main`" (outro repo, produção em dev ativo). Resultado: confusão de "pra onde gravar?", tentativas de escrita arriscadas num repo de produção com branch mudando, e falso flag de "v5 incompleto" — quando o trabalho de v5 já estava 100% no IdeiaOS. O usuário pegou o erro de escopo.

**Regra prática:** No REQUIREMENTS, escreva a prevenção como requisito verificável no IdeiaOS (entra no "done" do milestone) e liste a remediação de instâncias pré-existentes como **item operacional separado, fora do "done"**, a ser feito no repo-produto quando estiver calmo. Prevenção bem-feita já contém o problema → a remediação vira opcional/sem urgência. Nunca dirija escrita automatizada num repo-produto com estado instável.

**Falsos positivos:** se a "instância antiga" estiver no PRÓPRIO IdeiaOS, aí sim entra no milestone — a regra é sobre cross-repo (OS vs produto).
