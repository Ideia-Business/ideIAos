#!/usr/bin/env bash
# =============================================================================
# ideiaos-update.sh — Atualização completa de máquina em 1 comando
#
# Camada fina sobre o sync-all.sh que adiciona a configuração de usuário
# que o setup.sh (por decisão T-01-10) só imprime como snippet:
#
#   1. scripts/sync-all.sh             (pull → upstream → setup --global-only
#                                        → patches globais → idea-doctor)
#   2. Guarda do git-autosync          (exclui versions.lock do add -A — evita
#                                        revert do pin GSD por árvore stale)
#   2c. Verificação propagate-if-changed no git-autosync (IdeiaOS → ~/dev/*)
#   3. Registro de hooks IdeiaOS faltantes no ~/.claude/settings.json
#      (fonte canônica: plugins/ideiaos-core/hooks/hooks.json)
#   4. Funções claude-dev/review/research no profile do shell (idempotente)
#   5. Statusline IdeiaOS no ~/.claude/settings.json (backup + idempotente)
#
# DIFERENÇA do setup.sh (decisão T-01-10): o setup.sh NUNCA edita dotfiles ou
# settings.json do usuário — só imprime snippets. ESTE script edita, porque
# rodá-lo é o consentimento explícito ("atualizar tudo sem copiar/colar").
#
# Uso:
#   bash scripts/ideiaos-update.sh                  # tudo
#   bash scripts/ideiaos-update.sh --no-shell       # não toca no profile do shell
#   bash scripts/ideiaos-update.sh --no-statusline  # não toca no settings.json
#   bash scripts/ideiaos-update.sh --hooks-only     # registra só os hooks (step 3); pula o resto
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Cores ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
skip() { echo -e "${CYAN}  ⊙${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

NO_SHELL=0; NO_STATUSLINE=0; HOOKS_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-shell)      NO_SHELL=1 ;;
    --no-statusline) NO_STATUSLINE=1 ;;
    --hooks-only)    HOOKS_ONLY=1 ;;
  esac
done

# --hooks-only: registra SÓ os hooks (step 3), pulando sync-all + os patchers do autosync
# (steps 1-2e) e os steps de shell/statusline (4-5, via NO_SHELL/NO_STATUSLINE). Reusa o
# registrador idempotente do step 3 — sem duplicar a lógica. Usado pelo setup-dev-machine.sh
# (bootstrap-mantenedor), onde rodar o script É o consentimento explícito.
if [ "$HOOKS_ONLY" -eq 1 ]; then NO_SHELL=1; NO_STATUSLINE=1; fi

# Steps 1-2e (sync-all + patchers do autosync) só rodam no fluxo COMPLETO; --hooks-only os pula.
if [ "$HOOKS_ONLY" -eq 0 ]; then
# ── 1. sync-all (pull + upstream + setup global + patches + doctor) ──────────
# Self-update: se o pull do sync-all trouxer versão nova DESTE script, a
# execução atual continua com a versão antiga — aceitável (as etapas 2-5 são
# estáveis); a próxima execução já usa a nova.
step "1/6: sync-all.sh (pull → upstream → setup --global-only → patches → propagate → doctor)"
bash "$SETUP_DIR/scripts/sync-all.sh" || warn "sync-all terminou com avisos (ver acima)"

# ── [DEPRECATED — R15-19] Patchers in-place do daemon (steps 2/2b/2c/2d) ──────
# debt: remover os steps 2/2b/2c/2d quando a frota inteira estiver pós-cp-canônico.
# Estes 4 patchers aplicam deltas in-place (sed/grep/python) no binário deployado.
# São REDUNDANTES desde o step 2e (R15-19): o cp-da-fonte roda logo depois e
# SOBRESCREVE o binário inteiro, anulando qualquer patch in-place. Mantidos só como
# DIAGNÓSTICO legado (avisam de daemon antigo) e fallback se o helper sumir. O caminho
# canônico de update é `bash scripts/idea-update.sh` (idea update) → redeploy-daemon.sh.
# ── 2. Guarda do git-autosync (propagação multi-máquina) ─────────────────────
# Máquinas com git-autosync antigo fazem `git add -A` sem excluir versions.lock,
# o que já reverteu o pin GSD 2× via árvore stale (2026-06). Patch in-place,
# idempotente; a fonte canônica é o heredoc do setup-dev-machine.sh.
step "2/6: guarda do git-autosync (versions.lock fora do add -A)"
AUTOSYNC="$HOME/.local/bin/git-autosync"
if [ ! -f "$AUTOSYNC" ]; then
  skip "git-autosync não instalado nesta máquina (setup-dev-machine.sh instala)"
elif grep -qF "(exclude)versions.lock" "$AUTOSYNC"; then
  skip "git-autosync já exclui versions.lock"
else
  sed -i.bak "s|git add -A 2>>\"\$LOG\"|git add -A -- . ':(exclude)versions.lock' 2>>\"\$LOG\"|" "$AUTOSYNC"
  if grep -qF "(exclude)versions.lock" "$AUTOSYNC"; then
    rm -f "$AUTOSYNC.bak"
    ok "git-autosync patcheado: versions.lock fora do auto-commit"
  else
    warn "não consegui patchear $AUTOSYNC — re-rode setup-dev-machine.sh (backup em .bak)"
  fi
fi

# ── 2b. Guarda de memória + push do planning no git-autosync (v5) ────────────
# Máquinas com autosync antigo (só exclui versions.lock) não excluem memória
# nem propagam o branch `planning` (transporte de memória v5). O patch in-place
# aqui é limitado: se o autosync não tiver a forma nova (array de exclusões +
# push_planning_ref), o caminho seguro é re-rodar setup-dev-machine.sh, que
# regrava o heredoc canônico. Detecta e avisa de forma direcional.
step "2b/6: memória fora do autosync + push do branch planning (v5)"
if [ ! -f "$AUTOSYNC" ]; then
  skip "git-autosync não instalado nesta máquina"
elif grep -qF "push_planning_ref" "$AUTOSYNC" && grep -qF "(exclude).cursor/rules/memory-bridge.mdc" "$AUTOSYNC"; then
  skip "git-autosync já exclui memória e propaga o branch planning"
else
  warn "git-autosync desta máquina não tem a guarda de memória v5 (memória fora"
  warn "do add -A + push do planning). Re-rode: bash $SETUP_DIR/setup-dev-machine.sh"
  warn "(regrava o git-autosync canônico — idempotente, não duplica nada)."
fi

# ── 2c. Propagação automática pós-pull no git-autosync (IdeiaOS → ~/dev/*) ───
step "2c/6: git-autosync chama propagate-if-changed após pull no IdeiaOS"
if [ ! -f "$AUTOSYNC" ]; then
  skip "git-autosync não instalado nesta máquina"
elif grep -qF "maybe_propagate_ideiaos" "$AUTOSYNC"; then
  skip "git-autosync já propaga setup após pull no IdeiaOS"
else
  warn "git-autosync desta máquina não chama propagate-if-changed após pull."
  warn "Re-rode: bash $SETUP_DIR/setup-dev-machine.sh (regrava o heredoc canônico)."
fi

# ── 2d. Guards anti-contaminação no git-autosync (pause-file + conflict-marker) ─
# NASA systems-review (2026-06-19): o autosync é um escritor paralelo que pode
# contornar os pre-commit guards. Dois guards determinísticos fecham os vetores
# documentados: (1) pause-file — codifica o bootout manual (scripts/autosync-pause.sh);
# (2) conflict-marker — `git diff --check` aborta auto-commit de árvore com
# <<<<<<< /======= />>>>>>>. Patch in-place idempotente; fonte canônica = heredoc
# do setup-dev-machine.sh.
step "2d/6: guards anti-contaminação no git-autosync (pause-file + conflict-marker)"
if [ ! -f "$AUTOSYNC" ]; then
  skip "git-autosync não instalado nesta máquina"
elif grep -qF "git-autosync.pause" "$AUTOSYNC" && grep -qF "leftover conflict marker" "$AUTOSYNC"; then
  skip "git-autosync já tem os guards de pause-file e conflict-marker"
else
  /usr/bin/python3 - "$AUTOSYNC" <<'PYEOF'
import sys, io
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
changed = False
pause_block = (
    '  # Guard de pause (cirurgia git/infra de IA): pause-file global ou por-repo faz\n'
    '  # este repo ser pulado por inteiro. Codifica o bootout manual — quem pausa é\n'
    '  # responsavel por remover (ver scripts/autosync-pause.sh). Restauracao garantida.\n'
    '  if [ -f "${HOME}/.local/state/git-autosync.pause" ] || [ -f "$REPO/.git/autosync-pause" ]; then\n'
    '    log "$NAME" "pausado (pause-file) — pulado"; exit 0\n'
    '  fi\n'
)
conflict_block = (
    '    # Guard anti-contaminacao: nunca auto-commitar arvore com conflict markers.\n'
    '    if git diff --check 2>>"$LOG" | grep -q \'leftover conflict marker\'; then\n'
    '      log "$NAME" "CONFLICT MARKERS — auto-commit ABORTADO em $BRANCH"\n'
    '      notify "Git sync — conflict markers" "$NAME ($BRANCH): marcadores de conflito; auto-commit pulado."\n'
    '      exit 0\n'
    '    fi\n'
)
anchor_pause = '  local DIRTY=0; [ -n "$(git status --porcelain)" ] && DIRTY=1\n'
if 'git-autosync.pause' not in s and anchor_pause in s:
    s = s.replace(anchor_pause, anchor_pause + pause_block, 1); changed = True
anchor_conf = '    git add -A -- . "${MEM_EXCLUDES[@]}" 2>>"$LOG"\n'
if 'leftover conflict marker' not in s and anchor_conf in s:
    s = s.replace(anchor_conf, conflict_block + anchor_conf, 1); changed = True
if changed:
    open(p, "w", encoding="utf-8").write(s); print("PATCHED")
else:
    print("NOCHANGE")
PYEOF
  if grep -qF "git-autosync.pause" "$AUTOSYNC" && grep -qF "leftover conflict marker" "$AUTOSYNC"; then
    ok "git-autosync patcheado: pause-file + conflict-marker guards"
  else
    warn "não consegui patchear os guards em $AUTOSYNC — re-rode setup-dev-machine.sh"
  fi
fi

# ── 2e. git-autosync redeployado da fonte canônica (CAMINHO CANÔNICO — R15-19) ─
# O cp-da-fonte substitui o binário INTEIRO, curando qualquer drift — e tornando os
# patchers in-place 2/2b/2c/2d acima redundantes. Helper único redeploy-daemon.sh,
# o MESMO usado por propagate-if-changed e por idea-update.sh (1 lógica, não 2).
step "2e/6: git-autosync redeployado da fonte canônica (source/autosync)"
if [ ! -f "$SETUP_DIR/source/lib/redeploy-daemon.sh" ]; then
  skip "helper redeploy-daemon ausente (IdeiaOS antigo?)"
else
  . "$SETUP_DIR/source/lib/redeploy-daemon.sh"
  case "$(redeploy_autosync_daemon "$SETUP_DIR/source/autosync/git-autosync.sh" "$AUTOSYNC")" in
    ALREADY) skip "git-autosync já é a versão canônica" ;;
    HEALED)  ok "git-autosync redeployado da fonte canônica (qualquer drift curado)" ;;
    MISSING) skip "fonte/destino do daemon ausente — rode setup-dev-machine.sh" ;;
    FAILED)  warn "falha ao redeployar git-autosync — rode setup-dev-machine.sh" ;;
  esac
fi
fi  # fim do bloco [ "$HOOKS_ONLY" -eq 0 ] — steps 1-2e pulados sob --hooks-only

# ── 3. Registro de hooks IdeiaOS faltantes no settings.json ──────────────────
# O setup.sh instala os ARQUIVOS dos hooks mas (decisão T-01-10) só imprime o
# snippet de registro. Este passo registra o que faltar, usando o hooks.json
# do plugin ideiaos-core como fonte canônica (evento, matcher, timeout, async).
step "3/6: registro de hooks no settings.json"
SETTINGS="$HOME/.claude/settings.json"
PLUGIN_HOOKS="$SETUP_DIR/plugins/ideiaos-core/hooks/hooks.json"
if [ ! -f "$SETTINGS" ]; then
  warn "~/.claude/settings.json não existe — rode o Claude Code uma vez e re-execute"
elif [ ! -f "$PLUGIN_HOOKS" ]; then
  warn "plugins/ideiaos-core/hooks/hooks.json não encontrado — pulando registro"
else
  /usr/bin/python3 - "$SETTINGS" "$PLUGIN_HOOKS" "$HOME" <<'PYEOF'
import json, sys, shutil, os

settings_path, plugin_hooks_path, home = sys.argv[1], sys.argv[2], sys.argv[3]
settings = json.load(open(settings_path))
canon = json.load(open(plugin_hooks_path))["hooks"]

registered = json.dumps(settings.get("hooks", {}))
added = []
for event, entries in canon.items():
    for entry in entries:
        for hk in entry.get("hooks", []):
            name = hk["command"].rstrip('"').split("/")[-1]
            if name in registered:
                continue
            local = f'{home}/.claude/hooks/{name}'
            if not os.path.exists(local):
                print(f"  ⚠ {name}: arquivo não instalado em ~/.claude/hooks — pulando")
                continue
            new_hk = {"type": "command", "command": f'bash "{local}"'}
            for fld in ("timeout", "async", "asyncRewake"):
                if fld in hk:
                    new_hk[fld] = hk[fld]
            new_entry = {"hooks": [new_hk]}
            if "matcher" in entry:
                new_entry["matcher"] = entry["matcher"]
            settings.setdefault("hooks", {}).setdefault(event, []).append(new_entry)
            added.append(f"{event}/{name}")

if added:
    shutil.copy(settings_path, settings_path + ".bak-hooks")
    json.dump(settings, open(settings_path, "w"), indent=2, ensure_ascii=False)
    for a in added:
        print(f"  + registrado: {a}")
else:
    print("  (nenhum hook faltando)")
PYEOF
  case "$?" in
    0) ok "Registro de hooks verificado" ;;
    *) warn "Falha no registro de hooks — settings.json não alterado" ;;
  esac
fi

# ── 4. Funções de shell (claude-dev/review/research) ─────────────────────────
step "4/6: funções de contexto no shell"
if [ "$NO_SHELL" -eq 1 ]; then
  skip "profile do shell não tocado (--no-shell)"
else
  # Detecta o profile certo: zsh → ~/.zshrc; bash → ~/.bashrc
  case "${SHELL:-/bin/bash}" in
    */zsh)  PROFILE="$HOME/.zshrc" ;;
    *)      PROFILE="$HOME/.bashrc" ;;
  esac
  touch "$PROFILE"
  if grep -q "claude-review()" "$PROFILE" 2>/dev/null; then
    skip "Funções já presentes em $PROFILE"
  else
    {
      printf '\n# IdeiaOS — modos de contexto (Fase 07: contexts-evals)\n'
      printf 'claude-dev()      { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/dev.md")" "$@"; }\n'
      printf 'claude-review()   { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/review.md")" "$@"; }\n'
      printf 'claude-research() { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/research.md")" "$@"; }\n'
    } >> "$PROFILE"
    ok "Funções claude-dev/review/research adicionadas a $PROFILE"
  fi
fi

# ── 5. Statusline IdeiaOS no settings.json ───────────────────────────────────
step "5/6: statusline IdeiaOS"
SETTINGS="$HOME/.claude/settings.json"
SL_CMD="bash $HOME/.ideiaos/statusline/ideiaos-statusline.sh"
if [ "$NO_STATUSLINE" -eq 1 ]; then
  skip "settings.json não tocado (--no-statusline)"
elif [ ! -f "$SETTINGS" ]; then
  warn "~/.claude/settings.json não existe — rode o Claude Code uma vez e re-execute"
elif /usr/bin/python3 -c "
import json, sys
d = json.load(open('$SETTINGS'))
sl = d.get('statusLine', {})
sys.exit(0 if 'ideiaos-statusline' in str(sl.get('command', '')) else 1)
" 2>/dev/null; then
  skip "Statusline IdeiaOS já configurada"
else
  cp "$SETTINGS" "$SETTINGS.bak-statusline"
  /usr/bin/python3 - "$SETTINGS" "$SL_CMD" <<'PYEOF'
import json, sys
p, cmd = sys.argv[1], sys.argv[2]
d = json.load(open(p))
d["statusLine"] = {"type": "command", "command": cmd}
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PYEOF
  ok "Statusline IdeiaOS configurada (backup em settings.json.bak-statusline)"
fi

# ── 6. Daemon do Cockpit (ideiaos-agentd) — telemetria da frota viva ──────────
# Instala+bootstrapa com.ideiaos.cockpit com o node REAL (nvm/homebrew — launchd
# NÃO herda PATH; o plist versionado hardcoda /usr/local/bin/node, que QUEBRA em
# máquina nvm) e o caminho REAL do repo nesta máquina. Idempotente. Assim toda
# máquina que atualiza passa a alimentar o ref `cockpit` (frota viva) — sem passo
# manual. Opt-out: NO_COCKPIT_DAEMON=1. Pulado sob --hooks-only (é infra).
if [ "${HOOKS_ONLY:-0}" -eq 0 ] && [ "${NO_COCKPIT_DAEMON:-0}" -eq 0 ]; then
  step "6/6: daemon do Cockpit (com.ideiaos.cockpit)"
  CK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  CK_AGENTD="$CK_ROOT/source/agentd/agentd.js"
  if [ -f "$CK_AGENTD" ]; then
    CK_LABEL="com.ideiaos.cockpit"
    CK_PLIST="$HOME/Library/LaunchAgents/$CK_LABEL.plist"
    CK_NODE_DIR="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -1 || true)"
    [ -n "$CK_NODE_DIR" ] || CK_NODE_DIR="$(dirname "$(command -v node 2>/dev/null || echo /usr/local/bin/node)")"
    CK_NODE="$CK_NODE_DIR/node"
    CK_PATH="$CK_NODE_DIR:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$CK_PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$CK_LABEL</string>
    <key>ProgramArguments</key>
    <array><string>$CK_NODE</string><string>$CK_AGENTD</string><string>--once</string></array>
    <key>StartInterval</key><integer>900</integer>
    <key>RunAtLoad</key><true/>
    <key>StandardOutPath</key><string>/tmp/ideiaos-cockpit.out.log</string>
    <key>StandardErrorPath</key><string>/tmp/ideiaos-cockpit.err.log</string>
    <key>EnvironmentVariables</key><dict><key>PATH</key><string>$CK_PATH</string></dict>
    <key>AbandonProcessGroup</key><false/>
</dict>
</plist>
PL
    CK_UID="$(id -u)"
    launchctl bootout "gui/$CK_UID/$CK_LABEL" 2>/dev/null || true
    if launchctl bootstrap "gui/$CK_UID" "$CK_PLIST" 2>/dev/null; then
      launchctl enable "gui/$CK_UID/$CK_LABEL" 2>/dev/null || true
      launchctl kickstart -k "gui/$CK_UID/$CK_LABEL" 2>/dev/null || true
      ok "daemon do Cockpit ativo (node=$CK_NODE; a cada 15min + agora)"
    else
      warn "bootstrap do Cockpit falhou (não-fatal) — rode manual: launchctl bootstrap gui/$CK_UID $CK_PLIST"
    fi
  else
    warn "agentd.js não encontrado em $CK_AGENTD — pulei o daemon do Cockpit"
  fi
fi

echo ""
echo -e "${GREEN}${BOLD}━━━ Atualização concluída ━━━${NC}"
echo -e "${YELLOW}⚠ Reinicie o Claude Code (e abra um terminal novo) para tudo surtir efeito.${NC}"
