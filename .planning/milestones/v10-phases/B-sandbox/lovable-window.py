#!/usr/bin/env python3
"""
lovable-window.py — abre/fecha a janela de permissão da Fase B (R10-06) de forma
idempotente. Move as 5 tools do experimento entre permissions.deny <-> permissions.ask
no .claude/settings.json do IdeiaOS, e mantém o estado durável em B-01-WINDOW-STATE.json
(fonte de verdade independente da conversa, para o <recovery> do PLAN).

Uso:
    python3 lovable-window.py open    # deny -> ask para as 5 tools (abre janela)
    python3 lovable-window.py close   # ask  -> deny para as 5 tools (fecha janela) + assert endurecido
    python3 lovable-window.py status  # imprime contagens, sem mutar

Princípio antifrágil: o close roda um assert binário (deny==19 E ask==0 E allow==0 E disabled)
e sai != 0 se a janela não estiver de fato fechada. Build-contract (não é hook): exit 1 em falha.
"""
import json
import sys
import os
from datetime import datetime, timezone

CONNECTOR = "6f530143-e779-405d-bf42-190cae4e231b"
PROMOTE = [
    "remix_project",
    "send_message",
    "deploy_project",
    "set_project_visibility",
    "move_projects_to_folder",
]
# query_database é a 6ª, condicional (Task 5 + Task 1b confirmar DB isolado). Fora do default.

HERE = os.path.dirname(os.path.abspath(__file__))
# .claude/settings.json fica na raiz do repo (4 níveis acima desta pasta)
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
SETTINGS = os.path.join(REPO, ".claude", "settings.json")
STATE = os.path.join(HERE, "B-01-WINDOW-STATE.json")

DENY_TOTAL_CLOSED = 19  # invariante: 19 tools mutantes negadas quando a janela está fechada


def full(t):
    return f"mcp__{CONNECTOR}__{t}"


def load(path, default):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return default


def lovable_in(lst):
    return [x for x in lst if CONNECTOR in x]


def counts(settings):
    perm = settings.get("permissions", {})
    dn = lovable_in(perm.get("deny", []))
    ask = lovable_in(perm.get("ask", []))
    al = lovable_in(perm.get("allow", []))
    disabled = CONNECTOR in settings.get("disabledMcpServers", [])
    return dn, ask, al, disabled


def write_settings(settings):
    with open(SETTINGS, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")


def update_state(**kw):
    st = load(STATE, {})
    st.update(kw)
    with open(STATE, "w") as f:
        json.dump(st, f, indent=2)
        f.write("\n")


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def do_open():
    s = load(SETTINGS, {})
    perm = s.setdefault("permissions", {})
    deny = perm.setdefault("deny", [])
    ask = perm.setdefault("ask", [])
    for t in PROMOTE:
        ft = full(t)
        if ft in deny:
            deny.remove(ft)
        if ft not in ask:
            ask.append(ft)
    # disabledMcpServers permanece (não bloqueia connector account-level, mas é defesa-em-profundidade)
    write_settings(s)
    update_state(
        state="open",
        connector=CONNECTOR,
        promoted=[full(t) for t in PROMOTE],
        opened_at=now(),
        note="Janela ABERTA: 5 tools em ask. Provavelmente exige restart da sessao p/ valer.",
    )
    dn, ask_l, al, dis = counts(s)
    print(f"OPEN ok -> deny lovable={len(dn)} ask lovable={len(ask_l)} allow lovable={len(al)} disabled={dis}")
    print("Esperado: deny=14, ask=5. (restart provavel p/ o harness reler settings.json)")


def do_close():
    s = load(SETTINGS, {})
    perm = s.setdefault("permissions", {})
    deny = perm.setdefault("deny", [])
    ask = perm.setdefault("ask", [])
    for t in PROMOTE:
        ft = full(t)
        if ft in ask:
            ask.remove(ft)
        if ft not in deny:
            deny.append(ft)
    if not ask:
        perm.pop("ask", None)
    if CONNECTOR not in s.setdefault("disabledMcpServers", []):
        s["disabledMcpServers"].append(CONNECTOR)
    write_settings(s)
    update_state(state="closed", closed_at=now(), note="Janela FECHADA: deny reaplicado.")
    # assert endurecido (mesmo da Task 6 do PLAN)
    dn, ask_l, al, dis = counts(s)
    ok = len(dn) == DENY_TOTAL_CLOSED and len(ask_l) == 0 and len(al) == 0 and dis
    print(f"CLOSE -> deny lovable={len(dn)} ask lovable={len(ask_l)} allow lovable={len(al)} disabled={dis}")
    if not ok:
        print(f"FALHA: janela NAO fechada corretamente (esperado deny={DENY_TOTAL_CLOSED}, ask=0, allow=0, disabled=True)")
        sys.exit(1)
    print("OK: janela fechada — invariante restaurada.")


def do_status():
    s = load(SETTINGS, {})
    dn, ask_l, al, dis = counts(s)
    st = load(STATE, {})
    print(f"settings -> deny lovable={len(dn)} ask lovable={len(ask_l)} allow lovable={len(al)} disabled={dis}")
    print(f"window state -> {st.get('state', 'unknown')} (fork={st.get('fork_project_id')})")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "open":
        do_open()
    elif cmd == "close":
        do_close()
    elif cmd == "status":
        do_status()
    else:
        print(f"uso: python3 {os.path.basename(__file__)} open|close|status")
        sys.exit(2)
