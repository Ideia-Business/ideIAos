---
phase: "v15-A"
plan: "A-01"
type: execute
wave: 1
depends_on: []
files_modified:
  - source/hooks/console-log-guard.sh
  - source/hooks/extract-learnings-reminder.sh
  - source/hooks/ideiaos-detector.sh
  - source/hooks/ideiaos-readme-reminder.sh
  - source/hooks/instinct-recover.sh
  - source/hooks/memory-export.sh
  - source/hooks/memory-import.sh
  - source/hooks/observe-session-end.sh
  - source/hooks/observe-tool-use.sh
  - source/hooks/precompact-state-save.sh
  - source/hooks/session-summary.sh
  - source/hooks/typecheck-on-edit.sh
  - plugins/ideiaos-core/hooks/  # ARTEFATO GERADO por scripts/build-plugins.sh — não editar à mão
autonomous: true
requirements: [R15-01]
must_haves:
  truths:
    - "Os 12 hooks de PRODUTO da FONTE (source/hooks/, excluindo as 3 fixtures test-*.sh) não contêm mais o literal `/usr/bin/python3` — cada chamada resolve via lookup `command -v python3` (PY3) computado uma vez no topo do hook"
    - "Os 13 hooks .sh DEPLOYADOS em plugins/ideiaos-core/hooks/ ficam 100% limpos do literal `/usr/bin/python3` após re-rodar scripts/build-plugins.sh"
    - "GUARD DIFERENCIADO: typecheck-on-edit.sh e console-log-guard.sh (hooks de PROTEÇÃO) emitem aviso quando python3 está ausente E o arquivo editado é relevante (TS/JS) — NUNCA viram `exit 0` mudo cego; mas para arquivo NÃO-relevante (.md/.json/etc) sob python3-ausente, saem 0 em silêncio (não viram warn-every-edit)"
    - "Hooks de observação/memória (não-proteção) degradam silenciosamente (exit 0) quando python3 ausente, conforme o contrato fail-silent já existente — sem novo ruído"
    - "Nenhuma declaração de 'Windows suportado' é introduzida: o plano só remove o caminho POSIX-only hardcoded; o lookup torna o hook portável sem afirmar suporte"
  artifacts:
    - path: "source/hooks/typecheck-on-edit.sh"
      provides: "Guard diferenciado: warn quando python3 ausente E arquivo é .ts/.tsx (fallback de extensão em sed), lookup em vez de /usr/bin/python3"
      contains: "command -v python3"
    - path: "source/hooks/console-log-guard.sh"
      provides: "Guard diferenciado: warn quando python3 ausente E arquivo é .ts/.tsx/.js/.jsx (fallback de extensão em sed), lookup em vez de /usr/bin/python3"
      contains: "command -v python3"
    - path: "plugins/ideiaos-core/hooks/typecheck-on-edit.sh"
      provides: "Hook deployado limpo do literal /usr/bin/python3 (re-gerado pelo build)"
      contains: "command -v python3"
  key_links:
    - from: "source/hooks/*.sh"
      to: "plugins/ideiaos-core/hooks/*.sh"
      via: "scripts/build-plugins.sh build_core (cp literal, linhas 288-294)"
      pattern: "build-plugins.sh"
    - from: "source/lib/gates.sh"
      to: "plano (gates por exit-code)"
      via: "assert_nonempty / gate_output (test -s binário)"
      pattern: "gates.sh"
---

<objective>
Remover o bloqueador de portabilidade `/usr/bin/python3` (caminho POSIX absoluto, inexistente em
muitos ambientes) dos **12 hooks de PRODUTO da fonte** (`source/hooks/`, excluindo as 3 fixtures de
teste `test-hooks.sh`/`test-observe-hooks.sh`/`test-typecheck-on-edit.sh`), substituindo cada
invocação por um lookup resolvido **uma vez** no topo do hook (`PY3="$(command -v python3 || true)"`).
Re-rodar `scripts/build-plugins.sh` para regenerar `plugins/ideiaos-core/hooks/`, e provar por
**exit-code** (`grep -L`) que os **13 hooks `.sh` deployados** ficam limpos do literal.

Purpose: É a unidade A-01 da Fase A do v15 — destravar a frota multi-dev. O caminho hardcoded
`/usr/bin/python3` falha fora do macOS/POSIX-padrão; o lookup remove o bloqueador SEM afirmar
"Windows suportado" (escopo cirúrgico: só apaga o impedimento). Validável 100% no macOS por
exit-code — independe do teste do Lucas.

**Distinção crítica (guard diferenciado, enforçada por teste — a ALMA de R15-01):**
- **Hooks de PROTEÇÃO** — `typecheck-on-edit.sh` (PostToolUse, asyncRewake) e `console-log-guard.sh`
  (PostToolUse) — existem para PROTEGER o dev. Se python3 sumir, eles NÃO podem virar `exit 0` mudo
  (isso esconderia bug de tipo / console.log indo pra produção sem qualquer sinal). Devem emitir um
  **aviso** via `additionalContext` informando que o check foi pulado por falta de python3 — MAS
  **só quando o arquivo editado é relevante** (.ts/.tsx para typecheck; .ts/.tsx/.js/.jsx para
  console-log-guard). Para arquivo não-relevante (.md/.json/.png) sob python3-ausente, o hook sai 0
  em silêncio — senão o aviso viraria warn-EVERY-edit (ruído novo, proibido por C-4).
- **Hooks de OBSERVAÇÃO/MEMÓRIA** — os outros 10 — já são fail-silent por contrato (telemetria/IO
  que nunca bloqueia sessão). Para esses, ausência de python3 → `exit 0` silencioso é CORRETO; não
  introduzir ruído novo.

**Reconciliação verificada no código (não nos design-docs) — Article IV No-Invention:**
- A FONTE tem **13 `.sh` que contêm o literal `/usr/bin/python3`**. Destes, **1 é fixture**
  (`test-observe-hooks.sh` — as outras 2 fixtures `test-hooks.sh`/`test-typecheck-on-edit.sh` não
  contêm o literal). Logo são **12 hooks de produto** a corrigir. Confirmado por grep:
  `grep -rln '/usr/bin/python3' source/hooks/ | grep -v '/test-' | wc -l` = 12.
- O DEPLOY tem 13 `.sh` em `plugins/ideiaos-core/hooks/`. Destes, **11 contêm o literal hoje**
  (confirmado por grep; `deia-trigger.sh` e `strategic-compact.sh` já são limpos). O gate `grep -L`
  afirma os **13** limpos pós-build (os 2 já-limpos passam trivialmente; é cobertura, não erro).
- `instinct-recover.sh` é hook de produto (12º), MAS não está no array `CORE_HOOKS`
  (build-plugins.sh:112-124 — confirmado: 11 hooks, sem instinct-recover/memory-export/memory-import)
  nem em `plugins/`. Ele é distribuído ao GLOBAL via `install-global-patches.sh`. Portanto:
  corrigimos a FONTE de `instinct-recover.sh` (entra na conta dos 12), mas o gate dos 13-deployados
  NÃO o inclui (ele não vive em plugins/). Já usa `command -v claude` (linha 51) — o padrão de lookup
  é familiar ali. Tem **6 invocações reais** de `/usr/bin/python3` (linhas 35, 89, 122, 160, 182,
  198); a 7ª linha que o `grep -c` conta (linha 17) é COMENTÁRIO, não invocação.
- `memory-export.sh`/`memory-import.sh` estão deployados em `plugins/` (resíduo de build anterior,
  fora do `CORE_HOOKS` array) E são corrigidos na fonte. O `build-plugins.sh --plugin core` NÃO os
  re-copia (não estão no array) → após o build eles ficam STALE no plugin. Trataremos isso na Task 2
  (Condição C-5): sincronizar a cópia deployada desses 2 a partir da fonte corrigida, para que o
  gate dos 13 passe sem deixar deriva.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/rules/ideiaos-common-antifragile-gates.md
@.claude/rules/ideiaos-common-operating-discipline.md
@source/lib/gates.sh
@scripts/build-plugins.sh
@scripts/autosync-pause.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Pausar autosync + trocar /usr/bin/python3 → lookup nos 12 hooks de produto (guard diferenciado, com fallback de extensão, nos 2 de proteção)</name>
  <files>source/hooks/console-log-guard.sh, source/hooks/extract-learnings-reminder.sh, source/hooks/ideiaos-detector.sh, source/hooks/ideiaos-readme-reminder.sh, source/hooks/instinct-recover.sh, source/hooks/memory-export.sh, source/hooks/memory-import.sh, source/hooks/observe-session-end.sh, source/hooks/observe-tool-use.sh, source/hooks/precompact-state-save.sh, source/hooks/session-summary.sh, source/hooks/typecheck-on-edit.sh</files>
  <read_first>
    - scripts/autosync-pause.sh (linhas 24-37: `on [motivo]` cria pause-file em `$HOME/.local/state/git-autosync.pause`; `off` remove; `status`). É cirurgia multi-arquivo (12 hooks) — autosync-race: pausar ANTES (learning autosync-races-ai-git-surgery).
    - source/hooks/typecheck-on-edit.sh (HOOK DE PROTEÇÃO #1): linha 25 `| /usr/bin/python3 -c` (parse file_path/cwd); linha 69 `MSG="$(/usr/bin/python3 -c` (serializa JSON de erro). O parse (25) vem ANTES do filtro de extensão `*.ts|*.tsx` (linha 43). Hoje ambos com `2>/dev/null` → se python3 sumir, PARSED fica vazio, FILE_PATH vazio, case cai em `*) exit 0` MUDO. Esse é o anti-padrão a corrigir — MAS o guard NÃO pode avisar antes de filtrar a extensão (senão vira warn-every-edit).
    - source/hooks/console-log-guard.sh (HOOK DE PROTEÇÃO #2): linha 26 `| /usr/bin/python3 -c` (parse tool_name/file_path/session/cwd); linha 78 `LINE_NUMS="$(... | /usr/bin/python3 -c`; linha 89 `/usr/bin/python3 -c` (emite JSON de warning). Parse (26) vem ANTES do filtro de extensão `*.ts|*.tsx|*.js|*.jsx` (linha 53). Mesmo modo de falha: python3 ausente → FILE_PATH vazio → `[ -z "$FILE_PATH" ] && exit 0` MUDO (linha 50).
    - source/hooks/instinct-recover.sh: 6 invocações de `/usr/bin/python3` (linhas 35, 89, 122, 160, 182, 198 — a linha 17 é comentário). Já usa `command -v claude` (linha 51) — padrão lookup familiar. Usa `$HOME` (linhas 46, 118, 178, 179) sob `set -uo pipefail` (linha 21). Fail-silent por contrato (exit 0 em todo caminho, linha 216). NÃO é de proteção.
    - source/hooks/observe-tool-use.sh, observe-session-end.sh, memory-export.sh, memory-import.sh, session-summary.sh, precompact-state-save.sh, extract-learnings-reminder.sh, ideiaos-detector.sh, ideiaos-readme-reminder.sh — hooks de observação/memória/lembrete: já fail-silent (telemetria/IO, exit 0). NÃO são de proteção → degradação silenciosa é o comportamento correto. NOTA: vários usam `$HOME` sob `set -u` (observe-tool-use:101, observe-session-end, memory-*, session-summary) — relevante para o harness de teste da Task 3 (C-14).
    - .claude/rules/ideiaos-common-antifragile-gates.md ("Hook Contract": hook MUST exit 0 em qualquer falha — nunca exit não-zero de hook).
  </read_first>
  <action>
    (0) PAUSAR AUTOSYNC antes de tocar múltiplos arquivos:
        `bash scripts/autosync-pause.sh on "A-01 fix python3 hooks"` e confirmar
        `bash scripts/autosync-pause.sh status`. (Restauração é responsabilidade da Task 3.)

    (1) PADRÃO COMUM (todos os 12 hooks) — definir o lookup UMA vez, logo após `set -uo pipefail`:
        ```
        # python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
        PY3="$(command -v python3 2>/dev/null || true)"
        ```
        Trocar TODA ocorrência de `/usr/bin/python3` por `"$PY3"` no corpo do hook. Manter o
        restante (flags `-c`, heredocs, `2>/dev/null`) intacto — mudança cirúrgica só do binário.
        Para hooks com here-string interpolada (`'''$INPUT'''` em instinct-recover linha 36), NÃO
        mexer na interpolação — só no nome do binário.

    (2) GUARD DIFERENCIADO — typecheck-on-edit.sh (PROTEÇÃO) — com FALLBACK DE EXTENSÃO:
        O guard só pode avisar quando o arquivo é RELEVANTE (.ts/.tsx). Como o file_path normalmente
        sai do parse via python3 — indisponível justamente quando PY3 está vazio — extraímos o
        file_path por um parse-fallback em sed puro (suficiente p/ filtrar a extensão), aplicamos o
        MESMO filtro de extensão, e SÓ então decidimos avisar ou sair em silêncio.
        Inserir, logo após o lookup PY3 (antes do parse python3 da linha 25):
        ```
        if [ -z "$PY3" ]; then
          # python3 ausente: este hook PROTEGE contra erro de tipo — não pode silenciar cego.
          # Mas só avisa se o arquivo for relevante (.ts/.tsx); senão sai 0 em silêncio
          # (evitar warn-every-edit em .md/.json/.png — ruído proibido por C-4).
          _FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
          case "$_FP" in
            *.ts|*.tsx)
              printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[IdeiaOS] typecheck-on-edit pulado: python3 não encontrado no PATH — verificação de tipos NÃO executada neste edit. Instale/exponha python3 para reativar."}}'
              exit 0 ;;
            *) exit 0 ;;
          esac
        fi
        ```
        O exit 0 é exigido pelo contrato de hook; o aviso (quando .ts/.tsx) é visível — não é
        `exit 0` mudo. Para arquivo não-TS, sai 0 sem aviso — não vira ruído. (A Task 3 enforça
        AMBOS os ramos: avisa em .ts; NÃO avisa em .md.) NOTA: `$INPUT` já existe na linha 22
        (`INPUT="$(cat ...)"`) antes do parse — o guard usa essa mesma variável.

    (3) GUARD DIFERENCIADO — console-log-guard.sh (PROTEÇÃO) — com FALLBACK DE EXTENSÃO:
        Mesmo padrão, após o lookup PY3 e ANTES do parse python3 (linha 26). Filtro relevante aqui é
        .ts/.tsx/.js/.jsx (igual ao filtro da linha 53):
        ```
        if [ -z "$PY3" ]; then
          _FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
          case "$_FP" in
            *.ts|*.tsx|*.js|*.jsx)
              printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[IdeiaOS] console-log-guard pulado: python3 não encontrado no PATH — console.* NÃO verificado neste edit. Instale/exponha python3 para reativar."}}'
              exit 0 ;;
            *) exit 0 ;;
          esac
        fi
        ```
        (`$INPUT` já existe na linha 24 antes do parse — reusar.)

    (4) HOOKS NÃO-PROTEÇÃO (os outros 10): apenas a troca do (1). NÃO adicionar guard warn —
        eles já degradam silenciosamente por contrato (telemetria/memória). Adicionar ruído violaria
        escopo (operating-discipline §5). A ausência de python3 nesses já cai em exit 0 silencioso
        (o `|| true` no lookup + `2>/dev/null` nas chamadas garante que não estoura).

    ESCOPO CIRÚRGICO: tocar SÓ a linha do binário + (nos 2 de proteção) o bloco-guard com fallback de
    extensão. NÃO refatorar a lógica de parse downstream, NÃO mexer nas 3 fixtures test-*.sh (não são
    produto), NÃO declarar suporte a SO algum em comentário.
  </action>
  <acceptance_criteria>
    - AUTOSYNC PAUSADO: `bash scripts/autosync-pause.sh status` reporta pausado (exit 0) — gate: `test -f "$HOME/.local/state/git-autosync.pause"` exit 0.
    - LITERAL ERRADICADO DA FONTE (12 hooks de produto): `! grep -rl '/usr/bin/python3' source/hooks/ | grep -v '/test-' | grep .` exit 0 (nenhum hook de produto retém o literal). Equivalente afirmativo: `[ "$(grep -rln '/usr/bin/python3' source/hooks/ | grep -v '/test-' | wc -l | tr -d ' ')" = 0 ]` exit 0.
    - LOOKUP PRESENTE nos 12: `[ "$(grep -rln 'command -v python3' source/hooks/ | grep -v '/test-' | wc -l | tr -d ' ')" = 12 ]` exit 0 (os 12 hooks de produto agora têm o lookup).
    - SINTAXE VÁLIDA (todos os 12, bash 3.2): `ok=1; for f in $(grep -rln 'command -v python3' source/hooks/ | grep -v '/test-'); do bash -n "$f" || ok=0; done; [ "$ok" = 1 ]` exit 0.
    - GUARD DE PROTEÇÃO PRESENTE (2 hooks): `grep -q 'typecheck-on-edit pulado' source/hooks/typecheck-on-edit.sh && grep -q 'console-log-guard pulado' source/hooks/console-log-guard.sh` exit 0.
    - FALLBACK DE EXTENSÃO PRESENTE (anti-warn-every-edit): `grep -q '"file_path"' source/hooks/typecheck-on-edit.sh && grep -q '"file_path"' source/hooks/console-log-guard.sh` exit 0 — prova que o guard extrai file_path p/ filtrar antes de avisar. (Mais forte: o filtro de extensão dentro do bloco PY3-ausente é validado COMPORTAMENTALMENTE pela Task 3, gates G3-NEG.)
    - SEM DECLARAÇÃO DE SO (escopo): `! grep -riE 'windows suportado|windows support|suporta windows' source/hooks/` exit 0.
  </acceptance_criteria>
  <done>Autosync pausado; os 12 hooks de produto da fonte usam `command -v python3` (zero literal `/usr/bin/python3`); os 2 hooks de proteção têm guard warn COM fallback de extensão (avisa só em arquivo relevante); sintaxe válida; nenhuma afirmação de suporte a SO.</done>
</task>

<task type="auto">
  <name>Task 2: Re-build dos plugins + sincronizar cópia deployada dos hooks fora-do-array</name>
  <files>plugins/ideiaos-core/hooks/</files>
  <read_first>
    - scripts/build-plugins.sh linhas 112-124 (`CORE_HOOKS` array — 11 hooks; NÃO inclui memory-export.sh, memory-import.sh, instinct-recover.sh — confirmado) e 288-294 (`build_core` faz `cp "$src" "$PLUGIN_DIR/hooks/${hook}"` + `chmod +x` por hook do array).
    - plugins/ideiaos-core/hooks/ — 13 .sh deployados hoje (confirmado por ls). memory-export.sh/memory-import.sh estão lá (resíduo) mas NÃO no CORE_HOOKS → `build-plugins.sh --plugin core` não os re-copia. Sem sincronizá-los, ficariam STALE (com python3 antigo) e o gate dos 13 falharia.
    - scripts/build-plugins.sh:17 (`set -euo pipefail` — build-script sai 1 em falha, contrato correto).
  </read_first>
  <action>
    (1) RE-BUILD do core (regenera os 11 hooks do array a partir da fonte corrigida):
        `bash scripts/build-plugins.sh --plugin core`. Isso re-copia console-log-guard.sh,
        extract-learnings-reminder.sh, ideiaos-detector.sh, ideiaos-readme-reminder.sh,
        observe-session-end.sh, observe-tool-use.sh, precompact-state-save.sh, session-summary.sh,
        typecheck-on-edit.sh (9 dos que tinham python3) + deia-trigger.sh + strategic-compact.sh.

    (2) SINCRONIZAR os 2 hooks fora-do-array que vivem deployados (memory-export.sh,
        memory-import.sh): copiar da fonte corrigida para o plugin, preservando o estado deployado
        consistente (a distribuição global desses 2 é via install-global-patches.sh, mas a cópia em
        plugins/ precisa refletir a fonte para o gate dos 13 passar e não deixar deriva):
        `cp source/hooks/memory-export.sh plugins/ideiaos-core/hooks/memory-export.sh && chmod +x plugins/ideiaos-core/hooks/memory-export.sh`
        `cp source/hooks/memory-import.sh plugins/ideiaos-core/hooks/memory-import.sh && chmod +x plugins/ideiaos-core/hooks/memory-import.sh`
        (debt: o drift estrutural — esses 2 hooks deployados em plugins/ sem estar no CORE_HOOKS
        array — está FORA do escopo de R15-01. Marcar como `debt:` no SUMMARY, não consertar aqui.)

    NÃO tocar instinct-recover.sh em plugins/ (ele NÃO vive lá — é só global via patch; sua fonte já
    foi corrigida na Task 1). NÃO rodar `--plugin all` (escopo: só o core tem hooks).
  </action>
  <acceptance_criteria>
    - BUILD VERDE: `bash scripts/build-plugins.sh --plugin core` exit 0.
    - GATE PRINCIPAL (R15-01) — os 13 .sh deployados LIMPOS do literal, via `grep -L` afirmando 13 sem-match: `[ "$(grep -L '/usr/bin/python3' plugins/ideiaos-core/hooks/*.sh | wc -l | tr -d ' ')" = 13 ]` exit 0. (grep -L lista arquivos SEM o padrão; 13 = todos limpos.)
    - GATE NEGATIVO (anti-teatro — prova que o gate PEGA stale): antes do build/sync, `grep -L` retorna 2 (só deia-trigger/strategic-compact limpos); o gate só passa DEPOIS do build+sync. Asserção dupla: `[ "$(grep -L '/usr/bin/python3' plugins/ideiaos-core/hooks/*.sh | wc -l | tr -d ' ')" = 13 ]` exit 0 PÓS-build (e se algum stale sobrar, retorna <13 → falha).
    - NEGATIVA REDUNDANTE: `! grep -rl '/usr/bin/python3' plugins/ideiaos-core/hooks/ | grep .` exit 0 (nenhum deployado retém o literal).
    - LOOKUP CHEGOU AO DEPLOY: `grep -q 'command -v python3' plugins/ideiaos-core/hooks/typecheck-on-edit.sh && grep -q 'command -v python3' plugins/ideiaos-core/hooks/console-log-guard.sh` exit 0.
    - GUARD DE PROTEÇÃO NO DEPLOY: `grep -q 'typecheck-on-edit pulado' plugins/ideiaos-core/hooks/typecheck-on-edit.sh && grep -q 'console-log-guard pulado' plugins/ideiaos-core/hooks/console-log-guard.sh` exit 0.
    - SINTAXE DOS 13 DEPLOYADOS: `ok=1; for f in plugins/ideiaos-core/hooks/*.sh; do bash -n "$f" || ok=0; done; [ "$ok" = 1 ]` exit 0.
  </acceptance_criteria>
  <done>build-plugins.sh --plugin core re-gerou os hooks; memory-export/import deployados sincronizados; os 13 .sh deployados estão 100% limpos do literal (grep -L = 13), com lookup + guard de proteção presentes.</done>
</task>

<task type="auto">
  <name>Task 3: Teste de comportamento do guard diferenciado (python3 ausente — caso-feliz E caso-inválido) + religar autosync</name>
  <files>source/hooks/typecheck-on-edit.sh, source/hooks/console-log-guard.sh</files>
  <read_first>
    - source/hooks/typecheck-on-edit.sh e console-log-guard.sh já corrigidos (Tasks 1-2): o guard warn (com fallback de extensão) deve disparar quando `PY3` vazio E arquivo é relevante; e ficar SILENCIOSO quando `PY3` vazio E arquivo NÃO é relevante.
    - source/hooks/observe-tool-use.sh (hook NÃO-proteção, para o teste negativo): linha 101 `OBS_DIR="$HOME/.ideiaos/observations/$PROJ"` usa `$HOME` sob `set -uo pipefail` (linha 19). SE o teste rodar com `env -i PATH=...` (HOME zerado), o hook quebra com `HOME: unbound variable` (EXIT=1) — FALSO-NEGATIVO. Por isso o harness DEVE preservar HOME (C-14).
    - .claude/rules/ideiaos-common-antifragile-gates.md ("Inline Fallback" / regime artefato-de-arquivo: verificação por exit-code, nunca Read tool; gate exercita TAMBÉM input inválido — anti-teatro-verde).
    - scripts/autosync-pause.sh (off: remove o pause-file — restauração garantida).
  </read_first>
  <action>
    (0) MONTAR PATH SINTÉTICO sem python3 (macOS tem python3 em /usr/bin → não basta esvaziar PATH;
        criar um dir com SÓ os binários necessários EXCETO python3):
        ```
        TMPBIN="$(mktemp -d)"; for b in bash sh env cat sed grep head basename dirname date mkdir rm chmod printf; do ln -sf "$(command -v $b)" "$TMPBIN/$b" 2>/dev/null; done
        # (NÃO linkar python3 → ausente)
        ```
        CONTRATO DO HARNESS (C-14 — corrige GAP-1): toda simulação de python3-ausente roda com
        `env -i HOME="$HOME" PATH="$TMPBIN"` — PRESERVAR HOME. Sob `env -i` puro (sem HOME),
        observe-tool-use.sh:101 / instinct-recover / hooks de memória quebram com `HOME: unbound
        variable` e dão falso-negativo no gate de degradação silenciosa. HOME preservado = só python3
        ausente é exercitado.

    (1) GUARD DE PROTEÇÃO — CASO-FELIZ (.ts → DEVE avisar). python3 ausente + file_path .ts:
        ```
        OUT_TC="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/typecheck-on-edit.sh; echo "EXIT=$?")"
        OUT_CLG="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.tsx"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/console-log-guard.sh; echo "EXIT=$?")"
        ```
        Asserções: cada um `grep -q 'EXIT=0'` E `grep -q 'pulado'` (avisa + sai 0 = não-mudo).

    (2) GUARD DE PROTEÇÃO — CASO-INVÁLIDO (.md → NÃO deve avisar). É o INPUT INVÁLIDO que o verdict
        exige (fecha o blind-spot warn-every-edit). python3 ausente + file_path .md:
        ```
        OUT_TC_MD="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/notes.md"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/typecheck-on-edit.sh; echo "EXIT=$?")"
        OUT_CLG_MD="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/notes.md"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/console-log-guard.sh; echo "EXIT=$?")"
        ```
        Asserções: cada um `grep -q 'EXIT=0'` E `! grep -q 'pulado'` (sai 0 SEM avisar — não vira
        warn-every-edit em arquivo não-relevante).

    (3) DEGRADAÇÃO SILENCIOSA dos não-proteção (negativo do guard): observe-tool-use.sh com o mesmo
        PATH sem-python3 (HOME preservado) DEVE sair 0 e NÃO emitir 'pulado':
        ```
        OUT_OBS="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/observe-tool-use.sh; echo "EXIT=$?")"
        ```
        Asserções: `grep -q 'EXIT=0'` E `! grep -q 'pulado'`.

    (4) NÃO-REGRESSÃO (com python3 presente, PATH normal): typecheck-on-edit num .ts limpo sai 0 e
        NÃO emite 'pulado' (o guard PY3-ausente não dispara quando PY3 existe). Criar `T="$(mktemp).ts"`
        com `export const x: number = 1;` (sem erro de tipo) e:
        ```
        OUT_REG="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"'$T'"},"cwd":"/tmp"}' | bash source/hooks/typecheck-on-edit.sh; echo "EXIT=$?")"
        ```
        Asserções: `grep -q 'EXIT=0'` E `! grep -q 'pulado'`.

    (5) RELIGAR AUTOSYNC (restauração garantida — operating-discipline / autosync-race):
        `bash scripts/autosync-pause.sh off` e confirmar `bash scripts/autosync-pause.sh status` ativo.
        Limpar `$TMPBIN` e `$T`.
  </action>
  <acceptance_criteria>
    - G3-POS typecheck (.ts, python3 ausente → AVISA): `echo "$OUT_TC" | grep -q 'EXIT=0' && echo "$OUT_TC" | grep -q 'typecheck-on-edit pulado'` exit 0.
    - G3-POS console-log-guard (.tsx, python3 ausente → AVISA): `echo "$OUT_CLG" | grep -q 'EXIT=0' && echo "$OUT_CLG" | grep -q 'console-log-guard pulado'` exit 0.
    - G3-NEG typecheck (.md, python3 ausente → NÃO AVISA — INPUT INVÁLIDO, anti-warn-every-edit): `echo "$OUT_TC_MD" | grep -q 'EXIT=0' && ! echo "$OUT_TC_MD" | grep -q 'pulado'` exit 0.
    - G3-NEG console-log-guard (.md, python3 ausente → NÃO AVISA — INPUT INVÁLIDO): `echo "$OUT_CLG_MD" | grep -q 'EXIT=0' && ! echo "$OUT_CLG_MD" | grep -q 'pulado'` exit 0.
    - NÃO-MUDO PROVADO (proteção sob .ts python3-ausente tem stdout não-vazio): `[ -n "$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.ts"},"cwd":"/tmp"}' | env -i HOME="$HOME" PATH="$TMPBIN" bash source/hooks/typecheck-on-edit.sh)" ]` exit 0.
    - DEGRADAÇÃO SILENCIOSA (não-proteção, HOME preservado): `echo "$OUT_OBS" | grep -q 'EXIT=0' && ! echo "$OUT_OBS" | grep -q 'pulado'` exit 0.
    - NÃO-REGRESSÃO (com python3, .ts limpo): `echo "$OUT_REG" | grep -q 'EXIT=0' && ! echo "$OUT_REG" | grep -q 'pulado'` exit 0.
    - AUTOSYNC RELIGADO: `! test -f "$HOME/.local/state/git-autosync.pause"` exit 0 (pause-file removido).
  </acceptance_criteria>
  <done>Provado por exit-code: hooks de proteção AVISAM em arquivo relevante (.ts/.tsx) sob python3-ausente (não-mudo) E ficam SILENCIOSOS em arquivo não-relevante (.md — input inválido provado); hooks de observação degradam em silêncio (HOME preservado); com python3 o comportamento normal volta; autosync religado.</done>
</task>

</tasks>

<conditions_invariants>
Condições e invariantes que o executor DEVE respeitar (violar = retrabalho):

- **C-1 — Contagem-âncora:** 12 hooks de PRODUTO na fonte (não 13: a fonte tem 13 `.sh` COM o literal
  `/usr/bin/python3` = 12 produto + 1 fixture `test-observe-hooks.sh`; as fixtures saem por
  `grep -v '/test-'`). O gate da fonte é `... | grep -v '/test-'`.
- **C-2 — Gate dos 13 deployados via `grep -L`:** o gate principal afirma os 13 `.sh` em
  `plugins/ideiaos-core/hooks/` limpos — `grep -L '/usr/bin/python3' .../*.sh | wc -l == 13`.
  (`grep -L` = lista arquivos SEM o padrão; 13 = todos limpos. Os 2 já-limpos —
  `deia-trigger.sh`, `strategic-compact.sh` — passam trivialmente; é cobertura, não erro. PRÉ-build o
  valor é 2 → o gate PEGA stale.)
- **C-3 — instinct-recover é o 12º da fonte mas NÃO entra no gate dos 13:** ele não vive em
  `plugins/` (distribuído ao global por `install-global-patches.sh`). Corrigir a FONTE (6 invocações,
  linhas 35/89/122/160/182/198); não esperá-lo no `plugins/`.
- **C-4 — Guard diferenciado é a alma de R15-01 (com filtro de extensão):** SOMENTE
  `typecheck-on-edit.sh` e `console-log-guard.sh` ganham guard warn — e SÓ avisam quando o arquivo é
  relevante (.ts/.tsx; +.js/.jsx no console-guard). Arquivo não-relevante sob python3-ausente →
  exit 0 silencioso (NÃO warn-every-edit). Os outros 10 degradam em silêncio (exit 0). NÃO inverter:
  aviso nos de observação = ruído (viola escopo); silêncio mudo nos de proteção em arquivo relevante
  = o anti-padrão proibido; warn em arquivo não-relevante = o "ruído novo" que o próprio requisito
  proíbe.
- **C-5 — Drift de deploy fora-do-array:** `memory-export.sh`/`memory-import.sh` estão deployados em
  `plugins/` sem estar no `CORE_HOOKS` array; `build-plugins.sh --plugin core` não os re-copia. A
  Task 2 os sincroniza manualmente (cp+chmod) para o gate dos 13 passar. O drift estrutural em si é
  `debt:` fora de escopo — registrar, não consertar.
- **C-6 — Contrato de hook (antifragile-gates):** todo hook sai 0 em qualquer falha. O guard
  warn dos hooks de proteção sai 0 COM aviso no stdout (quando relevante) ou 0 silencioso (quando
  não-relevante) — exit 0 sempre, nunca exit não-zero.
- **C-7 — Contrato de build-script:** `scripts/build-plugins.sh` (`set -euo pipefail`) sai 1 em
  falha. NÃO alterá-lo.
- **C-8 — Autosync-race:** pausar autosync (`autosync-pause.sh on`) ANTES de tocar os 12 hooks
  (Task 1.0) e religar (`off`) ao final (Task 3.5). Restauração garantida mesmo se uma task falhar
  no meio (religar é a última ação obrigatória). Verificar pelo pause-file
  (`test -f "$HOME/.local/state/git-autosync.pause"`), não confiar em "status PAUSADO" textual.
- **C-9 — Escopo cirúrgico:** trocar SÓ o binário `/usr/bin/python3 → "$PY3"` + (nos 2 de proteção)
  o bloco-guard com fallback de extensão. NÃO refatorar o parse downstream, NÃO mexer nas fixtures
  `test-*.sh`, NÃO tocar `build-plugins.sh` CORE_HOOKS array, NÃO `--plugin all`.
- **C-10 — Não afirmar "Windows suportado":** o lookup torna o hook portável, mas o plano NÃO
  introduz nenhuma declaração de suporte a SO. Remove-se o bloqueador; afirmar suporte é decisão
  fora de R15-01 (e dependeria do teste do Lucas).
- **C-11 — @devops exclusivo para push:** este plano NÃO faz `git push` nem `gh pr`. Commit local é
  permitido (@dev); o push (`work → main` FF) é fechamento de sessão via @devops, fora deste plano.
- **C-12 — Verificação = exit-code binário (antifragile-gates):** toda asserção acima é exit-code
  (`grep`, `bash -n`, `test`, `wc | == N`). NUNCA usar o Read tool para "confirmar" que o literal
  sumiu — só o exit-code conta. Cada task tem ao menos um gate que exercita INPUT INVÁLIDO
  (Task 1: literal-erradicado é negativo; Task 2: grep -L pega stale; Task 3: G3-NEG edit de .md
  NÃO avisa) — anti-teatro-verde.
- **C-13 — Header de proveniência:** não criar artefatos novos neste plano (só edita existentes);
  se algum helper novo for extraído (não previsto), levaria `# SOURCE: IdeiaOS v15 | ...` no topo.
- **C-14 — Harness de teste preserva HOME (corrige GAP-1):** qualquer simulação de python3-ausente
  roda com `env -i HOME="$HOME" PATH="$TMPBIN"`. `env -i` puro zera HOME e quebra hooks que usam
  `$HOME` sob `set -u` (observe-tool-use:101, instinct-recover, memory-*, observe-session-end,
  session-summary) → `HOME: unbound variable` (EXIT=1) → falso-negativo. Preservar HOME garante que
  o teste isola APENAS a ausência de python3.
</conditions_invariants>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| stdin (PostToolUse JSON) → hook | JSON do harness; já tratado como dado (parse via python3, nunca eval). O parse-fallback em sed (guard PY3-ausente) também trata como dado: extrai só o valor de file_path para filtro de extensão, nunca eval — mudança não amplia a superfície |
| python3 ausente → hook de proteção | falha de capacidade NÃO pode silenciar a proteção em arquivo relevante: deve sinalizar (warn); MAS em arquivo não-relevante, silêncio é o correto (senão ruído) |
| source/hooks → plugins/ (build) | cp literal; o gate grep -L prova que o artefato gerado não regrediu o literal (pré-build=2, pós-build=13) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-A01-DoS | Denial of Service | hook de proteção sob python3 ausente | mitigate | guard warn (com filtro de extensão): sai 0 (não trava IDE) MAS avisa em arquivo relevante — gate G3-POS prova stdout não-vazio + 'pulado' |
| T-A01-Silent | Tampering/Repudiation | proteção virando exit 0 mudo (relevante) OU warn-every-edit (irrelevante) | mitigate | C-4 + Task 3: G3-POS exige 'pulado' em .ts/.tsx; G3-NEG exige AUSÊNCIA de 'pulado' em .md — os DOIS ramos provados por mutação (python3-ausente × extensão) |
| T-A01-Drift | Tampering | hooks deployados stale (fora do array) | mitigate | C-5: sincronizar memory-export/import; gate grep -L=13 pega qualquer stale com literal (pré-build=2 prova que pega) |
| T-A01-Race | Tampering | autosync atropela cirurgia multi-arquivo | mitigate | C-8: autosync-pause on antes / off depois (restauração garantida; verificar pelo pause-file, não pelo texto) |
| T-A01-FalseNeg | Repudiation | harness de teste zerando HOME → falso-negativo | mitigate | C-14: `env -i HOME="$HOME" PATH=...` preserva HOME; isola só python3 ausente |
| T-A01-Scope | — | reforma não-solicitada (afirmar suporte a SO) | mitigate | C-9/C-10: gate `! grep -ri 'windows suportado'`; escopo só remove bloqueador |
</threat_model>

<verification>
- Fonte: zero `/usr/bin/python3` nos 12 hooks de produto; 12× `command -v python3`; `bash -n` verde em todos; guard 'pulado' nos 2 de proteção COM fallback de extensão (file_path extraído por sed); sem 'windows suportado'.
- Build: `build-plugins.sh --plugin core` exit 0; `grep -L '/usr/bin/python3' plugins/ideiaos-core/hooks/*.sh | wc -l == 13` (pré-build=2 → o gate pega stale); lookup + guard chegaram ao deploy; `bash -n` verde nos 13.
- Comportamento (mutação python3-ausente × extensão, HOME preservado): proteção AVISA em .ts/.tsx e sai 0 (stdout não-vazio + 'pulado'); proteção NÃO avisa em .md e sai 0 (G3-NEG — input inválido); observação degrada em silêncio (exit 0, sem 'pulado'); com python3, proteção volta ao normal (.ts limpo, sem 'pulado').
- Autosync: pausado durante a cirurgia, religado ao final (pause-file ausente — verificado por `test -f`, não por texto).
</verification>

<success_criteria>
- Os 12 hooks de produto da fonte resolvem python3 por `command -v python3` (zero literal `/usr/bin/python3`).
- Os 13 hooks `.sh` deployados em `plugins/ideiaos-core/hooks/` provados limpos por `grep -L` (== 13; pré-build == 2, prova que o gate pega stale).
- Guard diferenciado enforçado por teste de comportamento com caso-feliz E caso-inválido: proteção AVISA em arquivo relevante (.ts/.tsx; não-mudo) e fica SILENCIOSA em arquivo não-relevante (.md — anti-warn-every-edit); observação degrada em silêncio. HOME preservado no harness (sem falso-negativo).
- Sem declaração de "Windows suportado"; escopo cirúrgico; autosync pausado→religado; validável 100% no macOS por exit-code.
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-01-fix-python3-hooks-SUMMARY.md` when done.
Registrar no SUMMARY o `debt:` do drift estrutural (memory-export/import deployados fora do CORE_HOOKS array).
</output>
