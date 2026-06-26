# SOURCE: IdeiaOS v15 | kind: summary | phase: v15-A | plan: A-04 | requirement: R15-05

# A-04 — Corrigir 3 inconsistências factuais (R15-05) — SUMMARY

**Status:** ✅ DONE (executado 2026-06-25, sem commit/push — exclusivo @devops/fechamento)
**Wave:** 1 · **depends_on:** [] · **autonomous:** true

## O que foi entregue

### (a) Path morto do alias iCloud → path real `$HOME/dev/IdeiaOS`
Corrigido na FONTE e em todas as fontes que herdam o erro (não só o sintoma):
- `scripts/install-alias.sh:7` — `DEV_SETUP` de `Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS` → `$HOME/dev/IdeiaOS`.
- `source/agents/ideiaos-checker.md` — 2 pontos (`DEV_SETUP=` e o `bash ".../setup.sh" --project-only`).
- `source/skills/ideiaos-setup/SKILL.md` — `ls ".../setup.sh"`.

### (b) Desambiguação das 3 cópias `.aiox-core` no README (NÃO unificação)
Rotuladas por papel, com o FATO GIT VERDADEIRO (vendor = ignorado, NÃO tracked):
- L224 — `~/dev/.aiox-core/` = cópia **debug/instalada** (alvo do overlay `install-global-patches.sh`).
- L237 — `npx aiox-core` = **runtime npm-global** (`aiox-core@5.x`).
- Frase-âncora nova (perto da tabela de caminhos) nomeando os 3 papéis: vendor PRISTINE (ignorado pelo git) / debug-instalado / runtime npm-global.
- Nota nova após a árvore vanilla/overlay: `Projects/.aiox-core/` = cópia instalada via npm upstream ≠ vendor PRISTINE do repo.
- Vendor PRISTINE **PRESERVADO** — nenhum arquivo dentro de `.aiox-core/` tocado.

### (c) Slug GitHub correto `Ideia-Business/ideIAos` (repo PÚBLICO)
- README:119 — casing corrigido + premissa obsoleta ("Decisão de tornar o repo público: pendente") removida (repo é público).
- README:124 — `claude plugin marketplace add Ideia-Business/ideIAos`.
- Total: 4 ocorrências do slug correto (13, 119, 124, 184); zero casing errado.

## Gates (exit-code — antifragile)

| Gate | Comando (resumo) | exit |
|------|-------------------|------|
| 1 | `! grep iCloud-legada README.md` | 0 |
| 2 | PRISTINE + ignorad + .gitignore perto do aiox-core | 0 |
| 3 | `! grep aiox-core…(tracked\|versionad)` (Article IV) | 0 |
| 4 | slug `Ideia-Business/ideIAos` (casing certo) | 0 |
| 5 | vendor checksum-FS `find … shasum \| sort \| shasum` == baseline | 0 |
| a/b/c finais + não-regressão iCloud-legítimo | TODOS PASS (FAIL=0) | 0 |

## Invariante crítico — vendor PRISTINE intocado
- Baseline (Task 0): `67c023225a5b2eb1b50a7112735896d019a10816` (8396 arquivos)
- Final: `67c023225a5b2eb1b50a7112735896d019a10816` — **byte-idêntico**
- `git ls-files .aiox-core` = 0 · `git check-ignore .aiox-core` = ignorado (exit 0) — segue UNTRACKED/IGNORED.

## Autosync
Pausado pelo wrapper SANCIONADO `scripts/autosync-pause.sh on` (pause-file canônico `${HOME}/.local/state/git-autosync.pause`).
Guard verificado na FONTE **e no binário DEPLOYADO** (`~/.local/bin/git-autosync:85` — honra o path). Despausado com `off` no fim (pause-file removido).

## Decisões / disciplina de escopo
- `idea-smoke.sh` (untracked) gera FAIL no `check-readme-sync.sh` — é de OUTRA unidade (A-03), ortogonal ao A-04. NÃO documentado aqui (escopo cirúrgico; condição 3 do plano). Pendência da unidade que criou o arquivo.
- `setup-dev-machine.sh` aparece como `M` no working tree — resíduo de A-03, NÃO editado por A-04.
- Linha de slug em `source/agents/ideiaos-checker.md:32` (`Ideia-Business/IdeiaOS.git` num exemplo de `git clone`) está FORA dos achados c1/c2 (que são README:119/124) — deixada como está; marcar como `debt:` se virar item próprio.

## Não-regressão
Usos legítimos de iCloud (vault Obsidian em `evolve/SKILL.md` etc.) preservados.

## Git
NÃO houve `git add`/`commit`/`push` nem `gh pr` — exclusivo @devops/fechamento de sessão. HEAD inalterado (`a323e39`). Working tree: 4 arquivos do A-04 modificados (`README.md`, `install-alias.sh`, `ideiaos-checker.md`, `ideiaos-setup/SKILL.md`).
