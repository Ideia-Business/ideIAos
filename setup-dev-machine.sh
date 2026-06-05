#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-dev-machine.sh
#
# Configura UMA MÁQUINA NOVA (ex: MacBook) com TODOS os projetos de dev em ~/dev/
# e o auto-sync consolidado entre máquinas (Git + LaunchAgent).
#
# Substitui o antigo setup-cfoai-machine.sh (que era só do cfoai).
#
# COMO USAR:
#   1. AirDrop / copie este arquivo para o Mac novo.
#   2. No Terminal:  bash setup-dev-machine.sh
#
# Idempotente — pode rodar quantas vezes quiser.
# .env (segredos) NÃO vem pelo git nos projetos onde é gitignored — o script avisa.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

DEV="$HOME/dev"
BIN_DIR="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state"
SCRIPT_PATH="$BIN_DIR/git-autosync"
LIST="$STATE_DIR/git-autosync-repos.txt"
NPM_CACHE="$STATE_DIR/npm-cache"
LABEL="com.ideiaos.gitautosync"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

# Projetos: "nome|url-github|branch-de-trabalho"
REPOS=(
  "cfoai-grupori|https://github.com/Ideia-Business/cfoai-grupori.git|work"
  "IdeiaOS|https://github.com/Ideia-Business/ideIAos.git|work"
  "lapidai|https://github.com/Ideia-Business/lapidai.git|work"
  "nfideia|https://github.com/Ideia-Business/nfideia.git|work"
  "ideiapartner|https://github.com/Ideia-Business/ideiapartner.git|work"
)

say()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[0;32m✓ %s\033[0m\n' "$*"; }
warn() { printf '  \033[0;33m⚠ %s\033[0m\n' "$*"; }
die()  { printf '\n\033[0;31m✗ %s\033[0m\n' "$*"; exit 1; }

# ── 0) Pré-requisitos ─────────────────────────────────────────────────────────
say "Verificando pré-requisitos"
for cmd in git gh node npm; do
  command -v "$cmd" >/dev/null 2>&1 || die "Falta '$cmd'. Instale antes (ex: brew install $cmd)."
  ok "$cmd → $(command -v "$cmd")"
done

# ── 1) GitHub auth + credential helper (push em background sem senha) ─────────
say "Configurando autenticação do GitHub (gh)"
gh auth status >/dev/null 2>&1 || { warn "Não logado no gh — abrindo login…"; gh auth login; }
gh auth setup-git
ok "gh autenticado + credential helper do git"

# ── 2) npm cache gravável (evita EACCES de ~/.npm root-owned) ─────────────────
say "Apontando npm para cache gravável"
mkdir -p "$NPM_CACHE"
npm config set cache "$NPM_CACHE"
ok "npm cache → $(npm config get cache)"
warn "Fix permanente opcional (com senha): sudo chown -R \$(id -u):\$(id -g) ~/.npm"

# ── 2.5) Comando `timeout` (macOS não traz o do GNU coreutils) ────────────────
# GSD e diversos workflows/IAs chamam `timeout N CMD`. Sem ele, falham com
# "timeout: command not found" (ex.: o connectivity test do GSD). Instala um
# shim em ~/.local/bin que usa gtimeout (brew coreutils) se houver, senão emula
# via perl alarm. Também garante ~/.local/bin no PATH (macOS não inclui).
say "Garantindo o comando 'timeout' (ausente no macOS por padrão)"
if command -v timeout >/dev/null 2>&1; then
  ok "timeout já disponível ($(command -v timeout))"
else
  mkdir -p "$BIN_DIR"
  cat > "$BIN_DIR/timeout" <<'TIMEOUT_EOF'
#!/usr/bin/env bash
# timeout — shim para macOS (sem GNU coreutils). Prefere gtimeout; senão perl alarm.
if command -v gtimeout >/dev/null 2>&1; then exec gtimeout "$@"; fi
while [ "$#" -gt 0 ]; do case "$1" in -k|-s) shift 2 ;; -*) shift ;; *) break ;; esac; done
dur="${1%s}"; shift || exit 125
exec perl -e '
  my $t = shift @ARGV; $t = ($t =~ /^(\d+)$/) ? $1 : 0;
  my $pid = fork(); defined $pid or die "timeout: fork: $!\n";
  if ($pid == 0) { exec @ARGV; exit 127; }
  $SIG{ALRM} = sub { kill "TERM", $pid; };
  alarm($t) if $t > 0;
  waitpid($pid, 0);
  my $st = $?; alarm(0);
  exit( ($st & 127) ? 124 : ($st >> 8) );
' "$dur" "$@"
TIMEOUT_EOF
  chmod +x "$BIN_DIR/timeout"
  ok "shim 'timeout' instalado em $BIN_DIR/timeout"
fi
# Garante ~/.local/bin no PATH (macOS não inclui por padrão) — zsh e bash.
for rc in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if ! grep -qs '\.local/bin' "$rc" 2>/dev/null; then
    printf '\n# IdeiaOS: ~/.local/bin no PATH (timeout shim, git-autosync, etc.)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
    ok "PATH: ~/.local/bin adicionado em $(basename "$rc")"
  fi
done
case ":$PATH:" in *":$BIN_DIR:"*) : ;; *) export PATH="$BIN_DIR:$PATH" ;; esac

# ── 3) Clonar + branch + deps de cada projeto ─────────────────────────────────
mkdir -p "$DEV"
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name url branch <<< "$entry"
  dst="$DEV/$name"
  say "Projeto: $name"
  if [ -d "$dst/.git" ]; then
    git -C "$dst" fetch --quiet origin && ok "já existe — fetch ok"
  else
    git clone --quiet "$url" "$dst" && ok "clonado" || { warn "clone falhou — pulando"; continue; }
  fi
  # branch de trabalho: usa origin/<branch> se existir, senão cria a partir do default
  if git -C "$dst" checkout "$branch" 2>/dev/null; then
    ok "na branch $branch"
  else
    git -C "$dst" checkout -b "$branch" 2>/dev/null && ok "branch $branch criada"
  fi
  git -C "$dst" pull --rebase --autostash --quiet 2>/dev/null || true
  if [ -f "$dst/package.json" ]; then
    printf '  instalando dependências (npm install)…\n'
    ( cd "$dst" && npm install >/dev/null 2>&1 ) && ok "node_modules pronto" || warn "npm install falhou — rode manualmente em $dst"
  else
    ok "sem package.json (não é projeto Node) — skip npm"
  fi
  [ -f "$dst/.env" ] || warn ".env ausente em $name — copie do outro Mac (AirDrop) se necessário"
done

# ── 4) Instalar o agente git-autosync (multi-repo) ────────────────────────────
say "Instalando git-autosync em $SCRIPT_PATH"
mkdir -p "$BIN_DIR" "$STATE_DIR"
cat > "$SCRIPT_PATH" <<'AUTOSYNC_EOF'
#!/usr/bin/env bash
# git-autosync — sincroniza repositórios git em segundo plano.
# Uso: git-autosync --all   (lê ~/.local/state/git-autosync-repos.txt)
#      git-autosync <repo>
# work/feature: auto-commit + pull --rebase + push.  main/master: só puxa, nunca escreve.
set -uo pipefail
LIST="${HOME}/.local/state/git-autosync-repos.txt"
LOG="${HOME}/.local/state/git-autosync.log"
mkdir -p "$(dirname "$LOG")"
log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" >> "$LOG"; }
notify() { /usr/bin/osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true; }
sync_one() {
  local REPO="$1"; local NAME; NAME="$(basename "$REPO")"
  cd "$REPO" 2>/dev/null || { log "$NAME" "ERRO: repo não encontrado em $REPO"; exit 1; }
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "$NAME" "ERRO: não é repo git"; exit 1; }
  local BRANCH; BRANCH="$(git branch --show-current)"
  [ -z "$BRANCH" ] && { log "$NAME" "detached HEAD — pulado"; exit 0; }
  local DIRTY=0; [ -n "$(git status --porcelain)" ] && DIRTY=1
  case "$BRANCH" in
    main|master)
      if [ "$DIRTY" -eq 1 ]; then log "$NAME" "$BRANCH (protegida) com alterações — pulado"; exit 0; fi
      git fetch --quiet origin 2>>"$LOG" || { log "$NAME" "fetch falhou — pulado"; exit 0; }
      if git rev-parse "@{u}" >/dev/null 2>&1; then
        if [ "$(git rev-parse @)" != "$(git rev-parse '@{u}')" ]; then
          git pull --rebase --quiet 2>>"$LOG" && log "$NAME" "pull OK em $BRANCH" \
            || { git rebase --abort 2>/dev/null; log "$NAME" "CONFLITO pull $BRANCH"; notify "Git sync — conflito" "$NAME (main): conflito."; }
        fi
        local AHEAD; AHEAD="$(git rev-list --count '@{u}..@' 2>/dev/null || echo 0)"
        [ "$AHEAD" -gt 0 ] && { log "$NAME" "$AHEAD commit(s) no $BRANCH — push MANUAL"; notify "Git sync — main protegido" "$NAME: $AHEAD commit(s) aguardando push manual."; }
      fi
      exit 0 ;;
  esac
  if [ "$DIRTY" -eq 1 ]; then
    local HOST; HOST="$(hostname -s 2>/dev/null || echo mac)"
    git add -A 2>>"$LOG"
    git commit -q -m "wip: autosync $(date '+%Y-%m-%d %H:%M') ($HOST)" 2>>"$LOG" && log "$NAME" "auto-commit em $BRANCH" || log "$NAME" "nada para commitar em $BRANCH"
  fi
  git fetch --quiet origin 2>>"$LOG" || { log "$NAME" "fetch falhou — push adiado"; exit 0; }
  if git rev-parse "@{u}" >/dev/null 2>&1; then
    if [ "$(git rev-parse @)" != "$(git rev-parse '@{u}')" ]; then
      if git pull --rebase --autostash --quiet 2>>"$LOG"; then log "$NAME" "pull/rebase OK em $BRANCH";
      else git rebase --abort 2>/dev/null; log "$NAME" "CONFLITO pull $BRANCH — push pulado"; notify "Git sync — conflito" "$NAME ($BRANCH): conflito."; exit 1; fi
    fi
    local AHEAD; AHEAD="$(git rev-list --count '@{u}..@' 2>/dev/null || echo 0)"
    [ "$AHEAD" -gt 0 ] && { git push --quiet 2>>"$LOG" && log "$NAME" "push OK ($AHEAD) em $BRANCH" || { log "$NAME" "push FALHOU $BRANCH"; notify "Git sync — push falhou" "$NAME ($BRANCH)."; }; }
  else
    git push --quiet -u origin "$BRANCH" 2>>"$LOG" && log "$NAME" "push inicial OK em $BRANCH" || { log "$NAME" "push inicial FALHOU $BRANCH"; notify "Git sync — push falhou" "$NAME ($BRANCH)."; }
  fi
  exit 0
}
if [ "${1:-}" = "--all" ] || [ "$#" -eq 0 ]; then
  [ -f "$LIST" ] || { log "*" "lista $LIST não encontrada"; exit 0; }
  while IFS= read -r repo; do
    repo="${repo%%#*}"; repo="$(echo "$repo" | xargs)"
    [ -z "$repo" ] && continue
    ( sync_one "$repo" )
  done < "$LIST"
else
  ( sync_one "$1" )
fi
AUTOSYNC_EOF
chmod +x "$SCRIPT_PATH"
ok "git-autosync instalado"

# ── 5) Lista de repos sincronizados ───────────────────────────────────────────
say "Escrevendo lista de repos"
{
  echo "# Repositórios sincronizados pelo git-autosync --all (um por linha; # comenta)."
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name _ _ <<< "$entry"
    echo "$DEV/$name"
  done
} > "$LIST"
ok "lista em $LIST"

# ── 6) LaunchAgent consolidado ────────────────────────────────────────────────
say "Criando + carregando o LaunchAgent $LABEL"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array><string>$SCRIPT_PATH</string><string>--all</string></array>
    <key>StartInterval</key><integer>900</integer>
    <key>RunAtLoad</key><true/>
    <key>StandardOutPath</key><string>$STATE_DIR/git-autosync.out.log</string>
    <key>StandardErrorPath</key><string>$STATE_DIR/git-autosync.err.log</string>
    <key>EnvironmentVariables</key>
    <dict><key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string></dict>
</dict>
</plist>
PLIST_EOF
UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST" && launchctl enable "gui/$UID_NUM/$LABEL" 2>/dev/null
launchctl kickstart -k "gui/$UID_NUM/$LABEL" 2>/dev/null || true
ok "agente ativo (a cada 15 min + agora)"

# ── 7) IdeiaOS — setup global (skills, MCPs, hooks, overlay) ───────────────────
# Sem isto, a máquina nova teria os repos clonados mas SEM o ambiente IdeiaOS
# global (skills /idea, /frontend-visual-loop, etc., MCPs chrome-devtools/context7,
# hooks Fase A, agentes Cursor, overlay de patches). --global-only não configura
# projeto algum; sync-all aplica o overlay (incl. OKLCH no design-system).
say "Instalando ambiente global IdeiaOS"
if [ -f "$DEV/IdeiaOS/setup.sh" ]; then
  bash "$DEV/IdeiaOS/setup.sh" --global-only && ok "setup global IdeiaOS aplicado" \
    || warn "setup.sh --global-only retornou erro — rode manualmente em $DEV/IdeiaOS"
  if [ -f "$DEV/IdeiaOS/scripts/sync-all.sh" ]; then
    bash "$DEV/IdeiaOS/scripts/sync-all.sh" && ok "overlay IdeiaOS aplicado" \
      || warn "sync-all.sh retornou erro — rode manualmente"
  fi
else
  warn "IdeiaOS não encontrado em $DEV/IdeiaOS — pulei o setup global"
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
say "Concluído 🎉"
cat <<RESUMO
  Projetos em:  $DEV
  Branch:       work (motor); main reservada p/ release → Lovable
  Log sync:     $STATE_DIR/git-autosync.log

  Útil — autosync:
    launchctl list | grep gitautosync
    launchctl kickstart -k gui/$UID_NUM/$LABEL     # sincronizar git agora
    launchctl bootout   gui/$UID_NUM/$LABEL        # desligar autosync

  Útil — IdeiaOS (ambiente global):
    bash $DEV/IdeiaOS/scripts/idea-doctor.sh          # diagnóstico de saúde + drift
    bash $DEV/IdeiaOS/scripts/sync-all.sh             # atualizar tudo (pull→setup→overlay→doctor)
    bash $DEV/IdeiaOS/scripts/update-design-suite.sh  # atualizar Suíte de Design do upstream
    bash $DEV/IdeiaOS/setup.sh /caminho/projeto       # configurar IdeiaOS num projeto
RESUMO
