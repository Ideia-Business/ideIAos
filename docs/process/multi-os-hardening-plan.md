# Multi-OS Hardening — Plano de implementação (backlog, gated)

> Origem: exame minucioso da instalação multi-SO do IdeiaOS (workflow `wf_0f029597-a31`,
> 7 agentes, 2026-06-25). Veredito do red-team: **sound-with-caveats**.
> Status: **plano aprovado, execução de código GATED** no teste empírico do Windows nativo
> (ver "Gate de entrada"). A doc multi-SO já foi entregue (`docs/guides/windows-wsl.md` 2 caminhos).

## Princípio

**1 corpo portável (hooks + daemon, escrito uma vez) + adapters finos por-SO só onde o SO
diverge (scheduler, notify).** Separar radicalmente **consumidor** (Claude Code + git + Node +
plugins; zero `setup.sh`) de **mantenedor** (bootstrap completo). Config via plugin nativo (zero
bash); execução via shell mínimo — **Git Bash no Windows nativo (sem VM)**, WSL2 só para
mantenedor/paridade.

## Descoberta central

A dependência de SO do IdeiaOS é **concentrada, rasa e portável** — não é "precisa de Linux":
- **Config** (47 skills + 19 agents + 42 rules) já é 100% portável via `claude plugin install`.
- O **bloqueador nº1 do Windows** é UM defeito mecânico: `/usr/bin/python3` hardcoded em 12 hooks
  de produto + 2 scripts (42 ocorrências) — não a ausência de Linux.
- Claude Code **Windows nativo executa hooks `.sh` via Git Bash** (confirmado por pesquisa;
  `sh -c` no mac/linux, Git Bash no Windows, PowerShell se Git Bash ausente) → WSL deixa de ser
  obrigatório para o consumidor.

## Gate de entrada (regime runtime — não exit-code)

**Teste de 5 min do dev Windows** (roteiro em `docs/guides/windows-wsl.md` §A.0): instalar
`ideiaos-core@ideiaos` numa Windows real com Git for Windows e observar se um hook
`${CLAUDE_PLUGIN_ROOT}/hooks/x.sh` **executa** ao editar um arquivo.
- **PASS** → habilita o tier "Windows nativo + Git Bash" como caminho de consumidor; dispara este milestone.
- **FAIL** → Windows nativo fica fora; WSL2 segue como único caminho Windows.

## Os 7 fixes priorizados

| # | Fix | Arquivos | Effort | Risk |
|---|-----|----------|--------|------|
| 1 | `/usr/bin/python3` → lookup `PY="$(command -v python3 \|\| command -v python)"` no topo de cada hook | 12 hooks de produto (excluir `test-*`) + 2 scripts | low | low |
| 2 | Adapter de scheduler: extrair o bloco launchd inline para `source/autosync/schedulers/{launchd,systemd,taskscheduler}.sh` com interface comum | **`setup-dev-machine.sh` (RAIZ, ~linhas 158-190)** | medium | medium |
| 3 | `notify()` 3 ramos (osascript / notify-send / no-op) mantendo `\|\| true` | `source/autosync/git-autosync.sh` (~linha 15) | low | low |
| 4 | Parametrizar paths macOS hardcoded (vault `IDEIAOS_VAULT_PATH`; base do alias dinâmica) | `setup-dev-machine.sh` (~219); `scripts/install-alias.sh` (~7) | low | low |
| 5 | `shell:"bash"` (ou exec-form) + `.gitattributes *.sh text eol=lf` no plugin | `source/.../hooks.json` → regenerar via `build-plugins.sh` | low | medium |
| 6 | `/tmp` → `${TMPDIR:-/tmp}` | `source/hooks/strategic-compact.sh`; `scripts/install-git-hooks.sh` | low | low |
| 7 | Ramo Linux de machine-id (`/etc/machine-id` sha256[:12]) + check `systemctl --user is-active` quando não-Darwin | `scripts/idea-doctor.sh` (§6, §15) | low | low |

## Caveats do red-team (OBRIGATÓRIOS na implementação)

1. **Validar o DEPLOYADO, não a fonte.** Corrigir `/usr/bin/python3` no `source/` é inerte até
   `build-plugins.sh` + re-cópia do daemon. Histórico documentado de binário deployado driftar
   ([[learning-autosync-pause-file-guard-not-deployed]]). Gate: `grep -L '/usr/bin/python3'` no
   **plugin instalado** (`~/.claude/plugins/.../hooks/*.sh`) e no `~/.local/bin/git-autosync`.
2. **Guard diferenciado.** `[ -z "$PY" ] && exit 0` cego silencia os hooks de **proteção**
   (`console-log-guard`, `typecheck-on-edit`) → falsa segurança. Para esses, avisar 1× a stderr
   ("IdeiaOS: python ausente — guard X desativado"). `test-*.sh` ficam fora do guard (devem FALHAR
   ruidosamente). Scripts (não-hooks) seguem contrato de build (exit 1), não de hook (exit 0).
3. **Windows nativo = tier EXPERIMENTAL até a prova.** A mitigação `shell:"bash"` do bug
   file-association (#21847/#24097) é **hipótese não confirmada por fonte**. Não declarar
   "suportado" antes do gate de entrada passar com artefato observável.
4. **Segurança do autosync.** Portar o daemon que auto-pusha branches ([[autosync-pushes-feature-branches]],
   [[autosync-races-ai-git-surgery]]) para N máquinas com agendador persistente exige **opt-in
   explícito** de push + default pull-only/notify em máquina não-primária + `@security-reviewer`
   no diff de portabilidade (toca PATH-inject/.env).

## Validação por SO (gates de aceitação, exit-code)

- **macOS** (verificável aqui): após o fix #1, `source/hooks/test-hooks.sh` + `test-observe-hooks.sh` verdes (não-regressão); re-build dos plugins; `grep -L '/usr/bin/python3'` no deployado.
- **Linux**: `systemctl --user enable --now git-autosync.timer` → `is-active` + `journalctl` confirmam disparo; reboot real prova `Persistent=true` + `enable-linger`.
- **Windows**: gate de entrada (hook executa) + `schtasks /query` + primeira gravação em `~/.local/state/git-autosync.log`.

## Decisões abertas

- `shell:"bash"` vs exec-form no `hooks.json` — depende do teste Windows.
- Fallback de scheduler sem privilégio (Task Scheduler bloqueado por GPO/UAC → HKCU Run / Startup).
- `setup.sh --consumer` explícito vs só documentar que consumidor não roda `setup.sh`.
- Vault fora do macOS (git/Syncthing/Dropbox) — decisão de fluxo do time.
- Papel CI/headless (sem sessão gráfica, sem linger) — fora do escopo v1.

---

**Não-objetivo:** port nativo PowerShell. O ideIAos permanece bash-based; Windows roda via Git
Bash (consumidor) ou WSL2 (mantenedor). Reavaliar só se o gate de entrada falhar de forma irrecuperável.
