#!/usr/bin/env bash
# =============================================================================
# install-deno.sh — instala o runtime Deno em ~/.local/bin (idempotente, CLI-First)
#
# POR QUÊ: edge functions (Supabase/Lovable) rodam em Deno. Sem o binário, uma IA
# que tenta `deno test`/`deno check` cai num fallback de "verificação estática" e
# emite o aviso recorrente "Deno não está instalado nesta máquina". Instalar o
# binário num diretório JÁ no PATH (~/.local/bin) mata o aviso em TODOS os projetos
# desta máquina, sem editar shell profiles a cada projeto.
#
# Idempotente:  se `deno` resolve no PATH E executa (exit-code), não faz nada.
# Portável:     arm64/x86_64 × macOS/Linux. Sem Homebrew, sem `curl | sh`.
# Auditável:    download do canal oficial dl.deno.land + verificação de checksum
#               (.sha256sum) e da execução por exit-code (contrato antifragile-gates).
#
# Uso:   bash scripts/install-deno.sh [--quiet] [--force]
#        DENO_VERSION=v2.9.0 bash scripts/install-deno.sh   # pin explícito
#
# Exit:  0 sucesso (ou já instalado);  1 falha (tool ausente/download/checksum/verify).
# =============================================================================
set -uo pipefail

QUIET=0; FORCE=0
for a in "$@"; do
  case "$a" in
    --quiet) QUIET=1 ;;
    --force) FORCE=1 ;;
    *) printf 'install-deno: flag desconhecida: %s (use --quiet|--force)\n' "$a" >&2 ;;
  esac
done

BIN_DIR="$HOME/.local/bin"
DENO_BIN="$BIN_DIR/deno"
FALLBACK_VERSION="v2.9.0"   # usado SÓ se dl.deno.land/release-latest.txt for inacessível

say()  { [ "$QUIET" -eq 1 ] || printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { [ "$QUIET" -eq 1 ] || printf '  \033[0;32m✓ %s\033[0m\n' "$*"; }
warn() { printf '  \033[0;33m⚠ %s\033[0m\n' "$*" >&2; }
die()  { printf '\n\033[0;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# Valida o formato de uma versão vX.Y.Z — barra /, .., espaço, TAB, ; e letras
# (defesa contra path-traversal na URL e contra lixo em release-latest.txt).
valid_version() {
  case "$1" in
    *[!v0-9.]*) return 1 ;;            # só permite 'v', dígitos e ponto
    v[0-9]*.[0-9]*.[0-9]*) return 0 ;; # vX.Y.Z mínimo
    *) return 1 ;;
  esac
}

# sha256 de um arquivo (macOS: shasum; Linux: sha256sum) — vazio se nenhum existir.
sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | awk '{print $1}'
  else printf ''; fi
}

# ── 1) Idempotência (exit-code, não só PATH) ─────────────────────────────────
# `deno` precisa resolver no PATH E executar — um binário presente-mas-quebrado
# (arch errada, corrompido, stub) NÃO conta como instalado. --force reinstala.
if [ "$FORCE" -eq 0 ] && command -v deno >/dev/null 2>&1 && deno --version >/dev/null 2>&1; then
  ok "Deno já instalado: $(command -v deno) ($(deno --version 2>/dev/null | head -1))"
  exit 0
fi

# ── 2) Ferramentas necessárias ────────────────────────────────────────────────
for t in curl unzip uname mktemp awk; do
  command -v "$t" >/dev/null 2>&1 || die "Falta '$t' — necessário para baixar/instalar o Deno."
done

# ── 3) Detectar alvo (arch + os) → triple de release do Deno ──────────────────
_arch="$(uname -m)"; _os="$(uname -s)"
case "$_arch" in
  arm64|aarch64) A="aarch64" ;;
  x86_64|amd64)  A="x86_64" ;;
  *) die "Arquitetura não suportada: $_arch (Deno publica aarch64 e x86_64)." ;;
esac
case "$_os" in
  Darwin) TARGET="$A-apple-darwin" ;;
  Linux)  TARGET="$A-unknown-linux-gnu" ;;
  *) die "SO não suportado: $_os (este instalador cobre macOS e Linux)." ;;
esac

# ── 4) Resolver versão (env pin > latest oficial > fallback hardcoded) ────────
# Pin explícito malformado = die (não mascarar). Latest malformado = fallback.
V="${DENO_VERSION:-}"
if [ -n "$V" ]; then
  valid_version "$V" || die "DENO_VERSION inválida: '$V' (esperado vX.Y.Z, sem barras/espaços)."
else
  V="$(curl -fsSL --max-time 15 https://dl.deno.land/release-latest.txt 2>/dev/null | awk 'NR==1{print $1}' | tr -d '\r')"
  if ! valid_version "$V"; then
    warn "versão 'latest' indisponível/malformada ('${V:-vazio}') — usando fallback $FALLBACK_VERSION"
    V="$FALLBACK_VERSION"
  fi
fi

# ── 5) Baixar + verificar checksum + extrair em tmpdir (trap garante limpeza) ─
URL="https://dl.deno.land/release/$V/deno-$TARGET.zip"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/deno-install.XXXXXX")" || die "mktemp -d falhou"
trap 'rm -rf "$TMP"' EXIT
say "Baixando Deno $V ($TARGET)"
curl -fL --retry 3 --max-time 120 -o "$TMP/deno.zip" "$URL" || die "download falhou: $URL"
test -s "$TMP/deno.zip" || die "zip vazio/ausente após download ($URL)"

# Verificação de integridade ANTES de extrair/executar (defense-in-depth além do TLS).
# dl.deno.land publica o sidecar <zip>.sha256sum; se indisponível, segue só com TLS.
EXPECTED="$(curl -fsSL --max-time 15 "$URL.sha256sum" 2>/dev/null | awk 'NR==1{print $1}' | tr -d '\r')"
if [ -n "$EXPECTED" ]; then
  ACTUAL="$(sha256_of "$TMP/deno.zip")"
  if [ -z "$ACTUAL" ]; then
    warn "sem shasum/sha256sum nesta máquina — não pude verificar integridade (seguindo só com TLS)"
  elif [ "$EXPECTED" != "$ACTUAL" ]; then
    die "checksum NÃO confere (esperado $EXPECTED, obtido $ACTUAL) — download adulterado/corrompido. Abortando."
  else
    ok "checksum verificado (sha256 $ACTUAL)"
  fi
else
  warn "sidecar .sha256sum indisponível — seguindo só com TLS (paridade com o instalador oficial)"
fi

unzip -oq "$TMP/deno.zip" -d "$TMP" || die "unzip falhou (zip corrompido?)"
test -f "$TMP/deno" || die "binário 'deno' ausente no zip extraído"

# ── 6) Instalar atômico em ~/.local/bin (quarentena removida SÓ após checksum) ─
mkdir -p "$BIN_DIR"
chmod +x "$TMP/deno"
mv -f "$TMP/deno" "$DENO_BIN" || die "falha ao mover para $DENO_BIN"
# Gatekeeper (macOS): remove quarentena agora que a integridade já foi conferida — não-fatal.
if [ "$_os" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  xattr -d com.apple.quarantine "$DENO_BIN" >/dev/null 2>&1 || true
fi

# ── 7) Garantir ~/.local/bin no PATH (zsh + bash) — idempotente por LINHA ─────
# macOS não inclui ~/.local/bin por padrão. O guard casa só uma LINHA de export
# ativa (não comentário/alias que apenas mencione o dir) p/ não pular o append.
for rc in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if ! grep -qsE '^[^#]*export PATH=.*\.local/bin' "$rc" 2>/dev/null; then
    printf '\n# IdeiaOS: ~/.local/bin no PATH (deno, timeout shim, git-autosync, etc.)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
    ok "PATH: ~/.local/bin adicionado em $(basename "$rc")"
  fi
done
case ":$PATH:" in *":$BIN_DIR:"*) : ;; *) export PATH="$BIN_DIR:$PATH" ;; esac

# ── 8) Verificação final por EXIT-CODE (antifragile — não confiar em leitura) ─
hash -r 2>/dev/null || true
"$DENO_BIN" --version >/dev/null 2>&1 || die "binário instalado mas '$DENO_BIN --version' falhou — verifique $DENO_BIN"
ok "Deno instalado: $("$DENO_BIN" --version | head -1) → $DENO_BIN"

# Aviso de PATH-shadow: outro deno antes de ~/.local/bin no PATH torna esta
# instalação invisível (o --force grava o binário bom mas o PATH resolve o outro).
RESOLVED="$(command -v deno 2>/dev/null || true)"
if [ -n "$RESOLVED" ] && [ "$RESOLVED" != "$DENO_BIN" ]; then
  warn "outro deno tem precedência no PATH: $RESOLVED (≠ $DENO_BIN). Garanta ~/.local/bin antes dele no PATH (ou remova o outro) e rode 'hash -r'."
fi
exit 0
