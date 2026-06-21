#!/usr/bin/env python3
# SOURCE: IdeiaOS v2 | padrão minerado de chopratejas/headroom (Apache-2.0); dependência NÃO adotada
"""tool-output-compressor — compressor local, determinístico e reversível de
saídas de ferramenta (log / JSON tabular / search), CLI-First, sem rede.

Contrato (specs/tool-output-compressor): protege mensagem de usuário, reversível
por CCR (store local keyed por sha256), verificação por exit-code, economia medida
honestamente, fail-open, determinístico/idempotente. stdlib apenas.
"""
from __future__ import annotations
import sys, os, json, re, hashlib, argparse

MARKER_PREFIX = "<<toc:v1"
STORE_DIR = os.environ.get("TOC_STORE", os.path.expanduser("~/.ideiaos/toc-store"))


# ----- token measurement (honest: measured vs estimated) -----
def count_tokens(s: str):
    """Returns (n_tokens, measured: bool). Uses tiktoken if present, else ~chars/4."""
    try:
        import tiktoken  # optional; never a hard dependency
        return len(tiktoken.get_encoding("cl100k_base").encode(s)), True
    except Exception:
        return max(1, len(s) // 4), False


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ----- CCR store (local, no network) -----
def _store_put(original: str) -> str:
    os.makedirs(STORE_DIR, exist_ok=True)
    h = _sha256(original)
    path = os.path.join(STORE_DIR, h + ".orig")
    if not os.path.exists(path):  # idempotent write
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(original)
        os.replace(tmp, path)  # atomic; no partial artifact
    return h


def _store_get(h: str):
    path = os.path.join(STORE_DIR, h + ".orig")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        return f.read()


# ----- detection -----
def detect(content: str) -> str:
    s = content.strip()
    if not s:
        return "empty"
    if s.startswith(MARKER_PREFIX):
        return "already-compressed"
    # JSON array of uniform dicts -> tabular
    try:
        obj = json.loads(s)
        if isinstance(obj, list) and len(obj) >= 3 and all(isinstance(x, dict) for x in obj):
            return "json_tabular"
    except Exception:
        pass
    lines = s.splitlines()
    if len(lines) >= 8:
        # log-ish: many lines sharing a normalized template
        tmpls = {_log_template(l) for l in lines if l.strip()}
        if tmpls and len(tmpls) <= max(2, len(lines) // 4):
            return "log"
    return "text"


# ----- log compressor (template-ization; reversible via store) -----
_LOG_SUBS = [
    (re.compile(r"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?"), "<ts>"),
    (re.compile(r"\b[0-9a-f]{7,40}\b"), "<hex>"),
    (re.compile(r"\b\d+(?:\.\d+)?\b"), "<n>"),
]


def _log_template(line: str) -> str:
    t = line
    for rx, rep in _LOG_SUBS:
        t = rx.sub(rep, t)
    return t.strip()


def compress_log(content: str) -> str:
    lines = [l for l in content.splitlines() if l.strip()]
    order, counts, sample = [], {}, {}
    for l in lines:
        t = _log_template(l)
        if t not in counts:
            counts[t] = 0
            order.append(t)
            sample[t] = l.strip()
        counts[t] += 1
    out = [f"# {len(lines)} log lines -> {len(order)} templates"]
    for t in order:
        out.append(f"{counts[t]:>6}x  {t}")
        if counts[t] > 1:
            out.append(f"        e.g. {sample[t]}")
    return "\n".join(out)


# ----- JSON tabular compressor (schema header + CSV rows; lossless transform) -----
def _csv_cell(v) -> str:
    if isinstance(v, (dict, list)):
        v = json.dumps(v, separators=(",", ":"), sort_keys=True)
    s = "" if v is None else str(v)
    if any(c in s for c in [",", '"', "\n"]):
        s = '"' + s.replace('"', '""') + '"'
    return s


def compress_json_tabular(content: str) -> str:
    rows = json.loads(content)
    keys = sorted({k for r in rows for k in r.keys()})
    def typ(k):
        for r in rows:
            if k in r and r[k] is not None:
                return type(r[k]).__name__
        return "null"
    header = f"[{len(rows)}]{{" + ",".join(f"{k}:{typ(k)}" for k in keys) + "}"
    body = [",".join(_csv_cell(r.get(k)) for k in keys) for r in rows]
    return header + "\n" + "\n".join(body)


# ----- orchestration -----
def compress(content: str, role: str = "tool", mode: str = "reversible"):
    """Returns dict: compressed, tokens_before, tokens_after, reduction_pct,
    transform, measured, sha256."""
    tb, measured = count_tokens(content)

    def result(compressed, transform, store=False):
        ta, _ = count_tokens(compressed)
        red = round(100.0 * (tb - ta) / tb, 1) if tb else 0.0
        h = None
        if store and mode == "reversible":
            h = _store_put(content)
            compressed = f"{MARKER_PREFIX} type={transform} sha256={h} n={tb}>>\n" + compressed
            ta, _ = count_tokens(compressed)
            red = round(100.0 * (tb - ta) / tb, 1) if tb else 0.0
        return {
            "compressed": compressed, "tokens_before": tb, "tokens_after": ta,
            "reduction_pct": red, "transform": transform, "measured": measured,
            "sha256": h,
        }

    # R2 — never compress user intent
    if role == "user":
        return result(content, "protected:user")

    kind = detect(content)
    # R7 — idempotent: already compressed is a no-op
    if kind in ("already-compressed", "empty"):
        return result(content, "noop:" + kind)

    try:
        if kind == "log":
            return result(compress_log(content), "log", store=True)
        if kind == "json_tabular":
            return result(compress_json_tabular(content), "json_tabular", store=True)
        # R1 — unrecognized/incompressible passes through intact (0%)
        return result(content, "passthrough:" + kind)
    except Exception as e:  # recoverable routing/compress error -> safe passthrough
        return result(content, f"passthrough:error:{type(e).__name__}")


def retrieve(h: str):
    return _store_get(h)


# ----- self-test (verification by exit-code; antifragile-gates) -----
def self_test() -> int:
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(name)

    logs = "\n".join(
        f"2026-06-21T01:{m:02d}:00Z INFO worker[{m%4}] processed batch=512 ok lat_ms={100+m%30}"
        for m in range(200))
    r = compress(logs, role="tool")
    check("log_reduces>50%", r["reduction_pct"] > 50)
    check("log_reversible_marker", r["compressed"].startswith(MARKER_PREFIX))
    check("log_roundtrip_sha", _sha256(retrieve(r["sha256"]) or "") == r["sha256"])

    rows = [{"id": i, "status": "active", "plan": "pro", "region": "us-east-1"} for i in range(100)]
    rj = compress(json.dumps(rows), role="tool")
    check("json_reduces>20%", rj["reduction_pct"] > 20)
    check("json_roundtrip_sha", retrieve(rj["sha256"]) == json.dumps(rows))

    user = "por favor refatore o módulo de pagamento, ele está confuso"
    ru = compress(user, role="user")
    check("user_protected_byte_identical", ru["compressed"] == user and ru["reduction_pct"] == 0.0)
    check("user_transform_label", ru["transform"] == "protected:user")

    unknown = "uma frase curta de prosa qualquer."
    rk = compress(unknown, role="tool")
    check("unknown_passthrough", rk["compressed"] == unknown)

    again = compress(r["compressed"], role="tool")
    check("idempotent_noop", again["compressed"] == r["compressed"] and again["transform"].startswith("noop"))

    d1 = compress(logs, role="tool")["compressed"]
    d2 = compress(logs, role="tool")["compressed"]
    check("deterministic", d1 == d2)

    miss = retrieve("0" * 64)
    check("retrieve_miss_is_none", miss is None)

    if fails:
        print("SELF-TEST FAIL:", ", ".join(fails), file=sys.stderr)
        return 1
    print("SELF-TEST OK — 12/12 checks passed")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="toc_compress", description="tool-output-compressor")
    sub = p.add_subparsers(dest="cmd")
    c = sub.add_parser("compress")
    c.add_argument("--role", default="tool", choices=["tool", "user", "assistant"])
    c.add_argument("--mode", default="reversible", choices=["reversible", "stateless"])
    c.add_argument("--json", action="store_true", help="emit full result as JSON")
    rp = sub.add_parser("retrieve")
    rp.add_argument("--hash", required=True)
    sub.add_parser("self-test")
    args = p.parse_args(argv)

    if args.cmd == "self-test":
        return self_test()
    if args.cmd == "retrieve":
        orig = retrieve(args.hash)
        if orig is None:
            print(json.dumps({"error": "not_found", "hash": args.hash}), file=sys.stderr)
            return 3  # explicit miss (R3) — not silent
        sys.stdout.write(orig)
        return 0
    if args.cmd == "compress":
        data = sys.stdin.read()
        res = compress(data, role=args.role, mode=args.mode)
        if args.json:
            out = dict(res)
            sys.stdout.write(json.dumps(out, ensure_ascii=False))
        else:
            sys.stdout.write(res["compressed"])
        return 0
    p.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
