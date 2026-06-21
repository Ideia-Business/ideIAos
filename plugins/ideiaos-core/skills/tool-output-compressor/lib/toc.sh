#!/usr/bin/env bash
# SOURCE: IdeiaOS v2 | padrão minerado de chopratejas/headroom (Apache-2.0)
# CLI-First wrapper for tool-output-compressor. Fail-open (R6): if python3 is
# unavailable, the original content passes through intact — never blocks the agent.
# Verification by exit-code (antifragile-gates): 0=ok, non-zero=hard failure.
set -uo pipefail

__TOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
__TOC_PY="$__TOC_DIR/toc_compress.py"

# minimal inline gate fallback (works even when IDEIAOS_DIR is absent)
type gate_output >/dev/null 2>&1 || gate_output() { test -s "${1:-}" 2>/dev/null; }

_have_python() { command -v python3 >/dev/null 2>&1; }

cmd="${1:-compress}"; shift 2>/dev/null || true

case "$cmd" in
  self-test)
    if ! _have_python; then echo "toc: python3 ausente — self-test não pode rodar" >&2; exit 2; fi
    exec python3 "$__TOC_PY" self-test
    ;;
  retrieve)
    if ! _have_python; then echo "toc: python3 ausente — retrieve indisponível" >&2; exit 2; fi
    exec python3 "$__TOC_PY" retrieve "$@"
    ;;
  compress|*)
    if ! _have_python; then
      # FAIL-OPEN: passthrough original (robust even if PATH is broken)
      cat 2>/dev/null || /bin/cat
      exit 0
    fi
    python3 "$__TOC_PY" compress "$@"
    exit $?
    ;;
esac
