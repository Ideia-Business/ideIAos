# A-01 — fix python3 hooks (R15-01) — SUMMARY

**Fase:** v15-A (destravar a frota multi-dev) · **Plano:** A-01 · **Wave:** 1
**Data:** 2026-06-25 · **Executor:** GSD (@dev / Dex) · **Status:** ✅ DONE (todos os gates verdes por exit-code)

## Objetivo (R15-01)

Remover o bloqueador de portabilidade `/usr/bin/python3` (caminho POSIX absoluto) dos 12 hooks de
PRODUTO da fonte (`source/hooks/`, excluindo as 3 fixtures `test-*.sh`), substituindo cada
invocação por um lookup resolvido UMA vez no topo (`PY3="$(command -v python3 2>/dev/null || true)"`);
re-rodar `scripts/build-plugins.sh --plugin core`; e provar por exit-code que os 13 hooks `.sh`
deployados em `plugins/ideiaos-core/hooks/` ficam limpos do literal.

## Arquivos modificados

### Fonte (12 hooks de produto — `source/hooks/`)

| Hook | Tipo | Invocações trocadas | Guard diferenciado |
|------|------|---------------------|--------------------|
| `typecheck-on-edit.sh` | PROTEÇÃO | 2 | SIM — warn em .ts/.tsx sob python3-ausente; silêncio em não-relevante (fallback sed) |
| `console-log-guard.sh` | PROTEÇÃO | 3 | SIM — warn em .ts/.tsx/.js/.jsx sob python3-ausente; silêncio em não-relevante (fallback sed) |
| `extract-learnings-reminder.sh` | observação | 1 | não (degrada em silêncio) |
| `ideiaos-detector.sh` | observação | 1 | não |
| `ideiaos-readme-reminder.sh` | observação | 1 | não |
| `instinct-recover.sh` | memória | 6 | não (12º hook de produto; NÃO vive em plugins/ — global via install-global-patches.sh) |
| `memory-export.sh` | memória | 2 + 1 comentário | não |
| `memory-import.sh` | memória | 6 + 1 comentário | não |
| `observe-session-end.sh` | observação | 5 + 1 comentário | não |
| `observe-tool-use.sh` | observação | 1 + 1 comentário | não |
| `precompact-state-save.sh` | observação | 3 | não |
| `session-summary.sh` | observação | 5 | não |

> Comentários que mencionavam o literal (`Sem-jq: só /usr/bin/python3`) também foram atualizados —
> o gate `grep -L` casa o literal em QUALQUER posição (inclusive comentário), então todos tinham
> de sair para o artefato ficar 100% limpo.

### Deploy (`plugins/ideiaos-core/hooks/` — ARTEFATO GERADO)

- 9 hooks re-gerados por `build-plugins.sh --plugin core` (os 9 do CORE_HOOKS que tinham o literal:
  console-log-guard, extract-learnings-reminder, ideiaos-detector, ideiaos-readme-reminder,
  observe-session-end, observe-tool-use, precompact-state-save, session-summary, typecheck-on-edit).
- 2 hooks sincronizados manualmente (Condição C-5 — fora do CORE_HOOKS array): `memory-export.sh`,
  `memory-import.sh` (cp + chmod +x).
- 2 hooks já-limpos passam trivialmente (cobertura, não erro): `deia-trigger.sh`, `strategic-compact.sh`.

## Gates provados (evidência binária por exit-code)

### Task 1 — fonte (12 hooks)
| Gate | Comando | Resultado |
|------|---------|-----------|
| T1-A literal erradicado | `grep -rl '/usr/bin/python3' source/hooks/ | grep -v '/test-' | wc -l` == 0 | **0 PASS** |
| T1-B lookup presente | `grep -rln 'command -v python3' source/hooks/ | grep -v '/test-' | wc -l` == 12 | **12 PASS** |
| T1-C sintaxe válida | `bash -n` nos 12 | **todos verdes PASS** |
| T1-D guard presente | `grep -q '...pulado'` nos 2 de proteção | **PASS** |
| T1-E fallback extensão | `grep -q '"file_path"'` nos 2 de proteção | **PASS** |
| T1-F sem decl. de SO | `! grep -riE 'windows suportado|...'` | **PASS** |

### Task 2 — build + deploy (13 hooks)
| Gate | Comando | Resultado |
|------|---------|-----------|
| build | `bash scripts/build-plugins.sh --plugin core` | **EXIT=0 PASS** |
| PRE-BUILD (anti-teatro) | `grep -L` pré-build == 2 (gate PEGA stale) | **2 — confirma que o gate detecta stale** |
| T2-PRINCIPAL (R15-01) | `grep -L '/usr/bin/python3' plugins/ideiaos-core/hooks/*.sh | wc -l` == 13 | **13 PASS** |
| T2-NEG redundante | `grep -rl '/usr/bin/python3' plugins/.../hooks/` VAZIO (exit 1) | **vazio PASS** |
| T2-LOOKUP | lookup nos 2 de proteção deployados | **PASS** |
| T2-GUARD | guard nos 2 de proteção deployados | **PASS** |
| T2-SINTAXE | `bash -n` nos 13 | **verdes PASS** |

### Task 3 — comportamento do guard diferenciado (mutação python3-ausente × extensão, HOME preservado C-14)
| Gate | Cenário | Resultado |
|------|---------|-----------|
| G3-POS typecheck | .ts + python3 ausente → AVISA + exit 0 | **PASS** (stdout = JSON 'typecheck-on-edit pulado') |
| G3-POS console-log-guard | .tsx + python3 ausente → AVISA + exit 0 | **PASS** (stdout = JSON 'console-log-guard pulado') |
| G3-NEG typecheck (INPUT INVÁLIDO) | .md + python3 ausente → NÃO avisa + exit 0 | **PASS** (stdout vazio) |
| G3-NEG console-log-guard (INPUT INVÁLIDO) | .md + python3 ausente → NÃO avisa + exit 0 | **PASS** (stdout vazio) |
| NÃO-MUDO provado | .ts python3-ausente → stdout não-vazio (237 chars) | **PASS** |
| G3-OBS degradação silenciosa | observe-tool-use, HOME preservado → exit 0, sem 'pulado' | **PASS** |
| G3-REG não-regressão | com python3, .ts limpo → exit 0, sem warn-PY3-ausente | **PASS** |

## Invariantes respeitados

- **Guard diferenciado (C-4):** só `typecheck-on-edit.sh` e `console-log-guard.sh` avisam — e SÓ em
  arquivo relevante (fallback de extensão em `sed` puro extrai file_path antes de filtrar). Arquivo
  não-relevante sob python3-ausente → exit 0 silencioso (anti-warn-every-edit). Os outros 10 degradam
  em silêncio. Provado por mutação (python3-ausente × .ts/.md) — os DOIS ramos.
- **Verificação = exit-code binário (C-12):** nenhum gate confiou no Read tool; todos por
  `grep`/`bash -n`/`wc | == N`. Cada task exercitou input inválido (anti-teatro-verde).
- **HOME preservado (C-14):** `env -i HOME="$HOME" PATH="$TMPBIN"` em toda simulação.
- **Escopo cirúrgico (C-9/C-10):** só o binário + bloco-guard nos 2 de proteção. Fixtures `test-*.sh`
  intactas (test-observe-hooks.sh ainda tem o literal — correto, é fixture). Nenhuma declaração de SO.
- **instinct-recover (C-3):** corrigido na fonte (6 invocações), NÃO esperado no gate dos 13 (não vive
  em plugins/).
- **@devops exclusivo (C-11):** NÃO houve `git push` / `gh pr` / commit. Working tree apenas.

## Débito registrado (fora de escopo de R15-01)

- `debt:` **Drift estrutural de deploy fora-do-array** — `memory-export.sh` e `memory-import.sh` estão
  deployados em `plugins/ideiaos-core/hooks/` (resíduo de build anterior) SEM estar no array
  `CORE_HOOKS` (`scripts/build-plugins.sh:112-124`). Logo `build-plugins.sh --plugin core` NÃO os
  re-copia, exigindo sincronização manual (cp+chmod, feita na Task 2). Isso é dívida estrutural: ou
  esses 2 hooks deveriam estar no array (se devem viver em plugins/), ou não deveriam estar deployados
  em plugins/ (se sua distribuição é só global). Marcar para uma unidade futura — não consertado aqui
  (precisão cirúrgica).

## Nota honesta (controle negativo C-14)

O controle negativo "sob `env -i` puro (sem HOME) o `observe-tool-use.sh` quebraria?" saiu EXIT=0
mesmo SEM HOME — porque, com python3 ausente, o hook sai cedo (`[ -z "$LINE" ] && exit 0`) antes de
tocar `$HOME` na linha 101. Ou seja, NESTE hook específico o amortecimento já existe. O C-14 segue
sendo a prática correta (outros hooks — instinct-recover, memory-* — usam `$HOME` em pontos sem o
mesmo early-exit), e o gate principal G3-OBS rodou com HOME preservado como o plano manda. Sem
falso-negativo no que importa.

## Estado git ao final

- Branch: `work`. NADA commitado, NADA pushado. Autosync: pause-file PRESENTE — seguia pausado pelo
  usuário; NÃO foi tocado (instrução explícita do usuário).
- 12 fontes + 11 deployados modificados no working tree (os 2 já-limpos `deia-trigger`/`strategic-compact`
  re-gerados idênticos → não aparecem em `git status`).
