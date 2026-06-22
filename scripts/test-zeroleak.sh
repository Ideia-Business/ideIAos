#!/usr/bin/env bash
# SOURCE: IdeiaOS v14.1 | kind: gate | targets: claude,cursor
# =============================================================================
# test-zeroleak.sh — Gate Zero-Leak (R14-06, A3) — o P0 de release da Bridge.
#
# Varre 7 SUPERFÍCIES (S1–S7), cada uma MATERIALIZADA em arquivo /tmp ANTES do
# scan por exit-code (antifragile-gates: `test -s` / exit-code, NUNCA o Read tool;
# regime-2 runtime vira regime-1 exit-code). Detector = source/agentd/zeroleak-
# snapshot.sh (regex literal + entropia de Shannon >=4.0 com allowlist por nome/
# shape — Task 1). Prova estrutural POSITIVA (S3) bate o scan negativo.
#
# As 7 superfícies (doc 78 §1.1):
#   S1 snapshot do ref ......... git show cockpit:snapshots/<MID>.json  > /tmp/s1
#   S2 read-model.db ........... sqlite3 read-model.db '.dump'          > /tmp/s2
#   S3 schema (PROVA POSITIVA) . PRAGMA table_info(api_key) — assert SEM coluna value
#   S4 estado React serializado  corpos JSON dos endpoints de estado     > /tmp/s4
#   S5 DOM renderizado ......... vite build -> servir dist/ loopback -> curl HTML+bundle > /tmp/s5
#   S6 tráfego de rede loopback  curl GET /overview /fleet /vault + body de POST /command > /tmp/s6
#   S7 logs .................... stdout/err do read.js                   > /tmp/s7
#
# DOGFOOD-VENENO TRIPLO (anti-teatro, obrigatório — doc 78 §1.2 nota):
#   (1) sk-ant-FAKEKEY... plantado em /tmp  -> camada REGEX  -> exit !=0
#   (2) token novo de alta-entropia non-sk- -> camada ENTROPIA -> exit !=0
#   (3) veneno de SUPERFÍCIE-RUNTIME (FIX S-05): injeta um token no arquivo
#       materializado de S6 (body de /command) / S4 (estado) -> assert o scan
#       dessa superfície sai !=0. Prova que S4/S5/S6 materializam o RUNTIME de
#       verdade — não um arquivo vazio que passa por vacuidade. Restaura limpo.
#
# Build script (NÃO hook): exit 1 em falha. exit 0 só se as 7 superfícies limpas
# E os 3 venenos reprovam. S6 usa SÓ o verbo run_doctor (B6, read-only) — NUNCA
# resume_autosync (B2) nem force_sync (B4): não perturba o autosync pausado.
#
# USO:
#   bash scripts/test-zeroleak.sh         # gate (exit 0=7 superfícies limpas + venenos reprovam)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCANNER="$ROOT/source/agentd/zeroleak-snapshot.sh"
DB_PATH="$HOME/.ideiaos/console/read-model.db"
COCKPIT_DIR="$ROOT/apps/cockpit"

# Porta NÃO-padrão p/ não colidir com read.js (3073) / vite (5273) em uso.
READ_PORT_TEST=37073   # read.js sob teste (S4/S6/S7)
DIST_PORT_TEST=37173   # http server servindo dist/ (S5)

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

# ── Antifragile gate (fallback inline) — test -s, nunca Read tool ────────────
type assert_nonempty >/dev/null 2>&1 \
  || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }

# ── tmpfiles + cleanup determinístico ────────────────────────────────────────
TMPDIR_ZL="$(mktemp -d "${TMPDIR:-/tmp}/zeroleak.XXXXXX")"
S1="$TMPDIR_ZL/s1"; S2="$TMPDIR_ZL/s2"; S3="$TMPDIR_ZL/s3"
S4="$TMPDIR_ZL/s4"; S5="$TMPDIR_ZL/s5"; S6="$TMPDIR_ZL/s6"; S7="$TMPDIR_ZL/s7"
READ_PID=""; DIST_PID=""

cleanup() {
  [ -n "$READ_PID" ] && kill "$READ_PID" 2>/dev/null || true
  [ -n "$DIST_PID" ] && kill "$DIST_PID" 2>/dev/null || true
  rm -rf "$TMPDIR_ZL" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

FAILED=0

# ── scan helper: materializa-antes-de-varrer já feito; aqui só roda o detector ─
scan_surface() {
  local label="$1" file="$2"
  if ! assert_nonempty "$file"; then
    err "$label: superfície NÃO materializada (arquivo vazio) — $file"
    FAILED=1; return 1
  fi
  if bash "$SCANNER" "$file" >/dev/null 2>&1; then
    ok "$label limpa (regex + entropia)"
    return 0
  else
    err "$label: SEGREDO DETECTADO — RELEASE BLOQUEADO"
    FAILED=1; return 1
  fi
}

echo "── Zero-Leak gate (7 superfícies + dogfood-veneno triplo) ──────────────────"

# ── S1 — snapshot do ref (git show cockpit:snapshots/<MID>.json) ─────────────
# MID auto-descoberto do ref (robusto em qualquer máquina): 1o snapshot do ref.
MID_FILE="$(git -C "$ROOT" ls-tree --name-only cockpit:snapshots 2>/dev/null | head -1)"
MID="${MID_FILE%.json}"
if [ -n "$MID" ]; then
  git -C "$ROOT" show "cockpit:snapshots/$MID.json" > "$S1" 2>/dev/null || true
  scan_surface "S1 ref snapshot ($MID)" "$S1"
else
  info "S1: nenhum snapshot no ref cockpit (ref vazio) — superfície n/a"
  printf '{"note":"no snapshot on ref"}' > "$S1"
fi

# ── S2 — read-model.db (.dump) ───────────────────────────────────────────────
if [ -f "$DB_PATH" ]; then
  sqlite3 "$DB_PATH" '.dump' > "$S2" 2>/dev/null || true
  scan_surface "S2 read-model .dump" "$S2"
else
  info "S2: read-model.db ausente — superfície n/a"
  printf '{"note":"no read-model.db"}' > "$S2"
fi

# ── S3 — schema (PROVA ESTRUTURAL POSITIVA bate o scan negativo) ─────────────
# api_key NÃO pode ter coluna `value`. PRAGMA table_info(api_key) | coluna 2 (name)
# | grep -qiw value => se ACHAR, FAIL. Positiva: "é impossível haver segredo".
if [ -f "$DB_PATH" ]; then
  sqlite3 "$DB_PATH" 'PRAGMA table_info(api_key)' > "$S3" 2>/dev/null || true
  if assert_nonempty "$S3" && cut -d'|' -f2 "$S3" | grep -qiw value; then
    err "S3 PROVA ESTRUTURAL: coluna 'value' EXISTE em api_key — P0 credential-isolation violada"
    FAILED=1
  else
    ok "S3 prova estrutural: api_key SEM coluna value (table_info(api_key) limpo)"
  fi
else
  info "S3: read-model.db ausente — prova estrutural n/a"
fi

# ── S4 — estado React serializado ────────────────────────────────────────────
# O estado que o SPA serializa vem dos corpos dos endpoints de estado do read.js
# (/overview /fleet /vault). Materializa o JSON serializado p/ arquivo e varre.
# (start do read.js compartilhado para S4/S6/S7 — porta não-padrão de teste.)
READ_LOG="$TMPDIR_ZL/read.log"
READ_PORT="$READ_PORT_TEST" node "$COCKPIT_DIR/server/read.js" > "$READ_LOG" 2>&1 &
READ_PID=$!
# espera o bind (loopback) ficar pronto
for _ in $(seq 1 30); do
  curl -sf "http://127.0.0.1:$READ_PORT_TEST/health" >/dev/null 2>&1 && break
  sleep 0.2
done
{
  echo '{"surface":"S4-serialized-react-state",'
  echo '"overview":'; curl -sf "http://127.0.0.1:$READ_PORT_TEST/overview" 2>/dev/null || echo 'null'
  echo ',"fleet":';   curl -sf "http://127.0.0.1:$READ_PORT_TEST/fleet"   2>/dev/null || echo 'null'
  echo ',"vault":';   curl -sf "http://127.0.0.1:$READ_PORT_TEST/vault"   2>/dev/null || echo 'null'
  echo '}'
} > "$S4" 2>/dev/null
scan_surface "S4 estado React serializado" "$S4"

# ── S5 — DOM renderizado (vite build -> servir dist/ loopback -> curl HTML+bundle)
# Q3 do RESEARCH: preferir vite build + static serve + curl (exit-code, sem MCP).
info "S5: vite build (materializa o DOM/bundle do SPA)…"
( cd "$COCKPIT_DIR" && npm run build ) > "$TMPDIR_ZL/build.log" 2>&1
if [ -s "$COCKPIT_DIR/dist/index.html" ]; then
  # serve dist/ em loopback numa porta não-padrão e curl o HTML + cada bundle JS
  ( cd "$COCKPIT_DIR/dist" && exec node -e '
    const http=require("http"),fs=require("fs"),path=require("path");
    const root=process.cwd();
    http.createServer((req,res)=>{
      let p=path.join(root,decodeURIComponent(req.url.split("?")[0]));
      if(req.url==="/"||req.url==="") p=path.join(root,"index.html");
      fs.readFile(p,(e,d)=>{ if(e){res.writeHead(404);res.end("nf");} else {res.writeHead(200);res.end(d);} });
    }).listen('"$DIST_PORT_TEST"',"127.0.0.1");
  ' ) &
  DIST_PID=$!
  for _ in $(seq 1 30); do
    curl -sf "http://127.0.0.1:$DIST_PORT_TEST/" >/dev/null 2>&1 && break
    sleep 0.2
  done
  {
    echo '<!-- S5 rendered DOM: index.html -->'
    curl -sf "http://127.0.0.1:$DIST_PORT_TEST/" 2>/dev/null || true
    echo '<!-- S5 rendered DOM: JS bundles -->'
    for js in "$COCKPIT_DIR"/dist/assets/*.js; do
      [ -f "$js" ] || continue
      curl -sf "http://127.0.0.1:$DIST_PORT_TEST/assets/$(basename "$js")" 2>/dev/null || true
    done
  } > "$S5" 2>/dev/null
  scan_surface "S5 DOM renderizado (dist/ loopback)" "$S5"
else
  err "S5: vite build não produziu dist/index.html"
  FAILED=1
fi

# ── S6 — tráfego de rede loopback (corpos GET + body de POST /command) ───────
# FIX S-03: o stdout inline do /command é superfície de rede — DEVE ser varrido.
# Usa SÓ run_doctor (B6, read-only). NUNCA resume_autosync/force_sync (não mexe
# no autosync pausado). Token efêmero obtido via GET /command-token (same-origin).
CMD_TOKEN="$(curl -sf -H "Origin: http://127.0.0.1:5273" -H "Host: 127.0.0.1:$READ_PORT_TEST" \
  "http://127.0.0.1:$READ_PORT_TEST/command-token" 2>/dev/null \
  | sed -n 's/.*"token":"\([0-9a-f]*\)".*/\1/p')"
{
  echo '{"surface":"S6-loopback-network-bodies",'
  echo '"overview":'; curl -sf "http://127.0.0.1:$READ_PORT_TEST/overview" 2>/dev/null || echo 'null'
  echo ',"fleet":';   curl -sf "http://127.0.0.1:$READ_PORT_TEST/fleet"   2>/dev/null || echo 'null'
  echo ',"vault":';   curl -sf "http://127.0.0.1:$READ_PORT_TEST/vault"   2>/dev/null || echo 'null'
  echo ',"command_run_doctor":'
  if [ -n "$CMD_TOKEN" ]; then
    curl -sf -X POST "http://127.0.0.1:$READ_PORT_TEST/command" \
      -H "Origin: http://127.0.0.1:5273" \
      -H "Host: 127.0.0.1:$READ_PORT_TEST" \
      -H "Content-Type: application/json" \
      -H "X-Cockpit-Token: $CMD_TOKEN" \
      --data '{"verb":"run_doctor"}' 2>/dev/null || echo 'null'
  else
    echo 'null'
  fi
  echo '}'
} > "$S6" 2>/dev/null
scan_surface "S6 corpos de rede loopback (inclui /command)" "$S6"

# ── S7 — logs (stdout/err do read.js) ────────────────────────────────────────
cat "$READ_LOG" > "$S7" 2>/dev/null || true
[ -s "$S7" ] || printf '[read.js] (sem logs)\n' > "$S7"
scan_surface "S7 logs (read.js stdout/err)" "$S7"

echo "── Dogfood-veneno TRIPLO (anti-teatro) ─────────────────────────────────────"

# (1) VENENO REGEX — sk-ant-FAKEKEY plantado num /tmp snapshot DEVE reprovar.
POISON_SK="$TMPDIR_ZL/poison_sk.json"
printf '{"poison":"sk-ant-FAKEKEY0123456789abcdef"}' > "$POISON_SK"
if bash "$SCANNER" "$POISON_SK" >/dev/null 2>&1; then
  err "VENENO(1) regex: sk-ant-FAKEKEY NÃO foi pego — gate é teatro!"
  FAILED=1
else
  ok "VENENO(1) regex: sk-ant-FAKEKEY pego (exit !=0)"
fi

# (2) VENENO ENTROPIA — token novo de alta-entropia non-sk- DEVE reprovar (camada b).
POISON_ENT="$TMPDIR_ZL/poison_entropy.json"
printf '{"tok":"Xq9Zk2Lm7Pw4Rt8Vn3Bc6Dh1Fj5Gs0Ay"}' > "$POISON_ENT"
if bash "$SCANNER" "$POISON_ENT" >/dev/null 2>&1; then
  err "VENENO(2) entropia: token alta-entropia non-sk- NÃO foi pego — camada b morta!"
  FAILED=1
else
  ok "VENENO(2) entropia: token alta-entropia non-sk- pego (exit !=0)"
fi

# (3) VENENO DE SUPERFÍCIE-RUNTIME (FIX S-05) — injeta um token na superfície
# RUNTIME já materializada (S6: body de /command) e ASSERT que o scan DESSA
# superfície sai !=0. Prova que S4/S5/S6 NÃO são arquivo-vazio (vacuidade).
# Restaura o estado limpo após o veneno (cópia mutada, nunca o S6 original).
POISON_RUNTIME="$TMPDIR_ZL/poison_runtime_s6.json"
cp "$S6" "$POISON_RUNTIME"
# injeta um token de segredo no body de /command (superfície runtime de rede)
printf '\n{"injected_runtime_secret":"sk-ant-FAKEKEY-runtime-0123456789"}\n' >> "$POISON_RUNTIME"
if bash "$SCANNER" "$POISON_RUNTIME" >/dev/null 2>&1; then
  err "VENENO(3) runtime: S6 com token injetado NÃO reprovou — S4/S5/S6 é teatro de arquivo-vazio!"
  FAILED=1
else
  ok "VENENO(3) runtime: S6 (body de /command) com token injetado reprovou (exit !=0) — superfície materializa runtime real"
fi
rm -f "$POISON_RUNTIME"  # restaura estado limpo

echo "────────────────────────────────────────────────────────────────────────────"
if [ "$FAILED" -ne 0 ]; then
  err "Zero-Leak FAIL — release BLOQUEADO (P0)"
  exit 1
fi
ok "Zero-Leak OK — 7 superfícies limpas + dogfood-veneno triplo reprovou (A3 verde)"
exit 0
