-- SOURCE: IdeiaOS v14 | kind: model-ddl | targets: claude,cursor
-- =============================================================================
-- schema.sql — DDL das 8 tabelas v14.0 (subconjunto de 13 do doc 40 §3)
--
-- Tabelas v14.0:
--   machine, project, api_key, mcp_connection,
--   productivity_event, soak_heartbeat, daemon_status, machine_snapshot
--
-- Tabelas AUSENTES (v14.2+):
--   commit_log, session, milestone, security_seal, version_pin
--
-- GUARD ESTRUTURAL (credential-isolation materializada — DoD #1):
--   api_key NÃO tem coluna `value`. PROPOSITAL.
--   Qualquer ALTER que adicione `value` reprova o gate:
--     PRAGMA table_info(api_key) | cut -d'|' -f2 | grep -qiw value => FAIL
--
-- Proveniência: doc 40 §3 linhas 332-496 (DDL canônico); subconjunto v14.0 per doc 72 §4.
-- =============================================================================

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- Machine: representa uma máquina física única
-- machine_id = sha256(IOPlatformUUID)[:12] — NUNCA hostname
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS machine (
  machine_id        TEXT PRIMARY KEY,          -- sha256(IOPlatformUUID)[:12]
  canonical_name    TEXT,                       -- nome legível via machine-aliases.json
  os_version        TEXT,
  agentd_version    TEXT,
  first_seen_epoch  INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  last_seen_epoch   INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);

-- ---------------------------------------------------------------------------
-- Project: produto descoberto por iteração ~/dev/*/.git
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project (
  project_slug      TEXT PRIMARY KEY,           -- basename do diretório
  machine_id        TEXT NOT NULL REFERENCES machine(machine_id),
  path              TEXT,                        -- caminho absoluto no disco
  remote_url        TEXT,
  supabase_project_id TEXT,
  is_test_dir       INTEGER NOT NULL DEFAULT 0, -- heurística determinista
  class_reason      TEXT,
  first_seen_epoch  INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  last_seen_epoch   INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);

-- ---------------------------------------------------------------------------
-- ApiKey: SEMPRE por-referência. SEM coluna `value`. PROPOSITAL.
--
-- GUARD ESTRUTURAL (DoD #1 — Zero-Leak release gate):
--   PK (project_slug, var_name) | risk_tier CHECK | SEM value
--   Qualquer ALTER que adicione `value` = violação de credential-isolation.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_key (
  project_slug      TEXT NOT NULL REFERENCES project(project_slug),
  var_name          TEXT NOT NULL,
  present           INTEGER NOT NULL DEFAULT 0,
  expected          INTEGER NOT NULL DEFAULT 0,
  risk_tier         TEXT CHECK(risk_tier IN ('critical','sensitive','low','none')) NOT NULL,
  file_mtime_epoch  INTEGER,
  committed         INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (project_slug, var_name)
);

-- ---------------------------------------------------------------------------
-- MCP Connection: servidores MCP configurados na máquina
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mcp_connection (
  machine_id        TEXT NOT NULL REFERENCES machine(machine_id),
  source_file       TEXT NOT NULL,              -- basename do arquivo de config
  server_name       TEXT NOT NULL,
  enabled           INTEGER NOT NULL DEFAULT 1,
  last_seen_epoch   INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  PRIMARY KEY (machine_id, source_file, server_name)
);

-- ---------------------------------------------------------------------------
-- Productivity Event: evento de produtividade capturado pelo agentd
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS productivity_event (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  machine_id        TEXT NOT NULL REFERENCES machine(machine_id),
  event_type        TEXT NOT NULL,              -- ex: 'session_start', 'commit'
  project_slug      TEXT,
  epoch             INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  payload_json      TEXT                        -- JSON adicional (sem secrets)
);

-- ---------------------------------------------------------------------------
-- Soak Heartbeat: linha do ledger .planning/soak/<milestone>.log
-- Formato pipe-delimited: epoch|iso|host|idea_doctor=PASS|regression=PASS|commit_hash
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS soak_heartbeat (
  milestone         TEXT NOT NULL,
  epoch             INTEGER NOT NULL,
  iso               TEXT NOT NULL,
  host              TEXT NOT NULL,
  idea_doctor       TEXT NOT NULL DEFAULT '',
  regression        TEXT NOT NULL DEFAULT '',
  commit_hash       TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (milestone, epoch, host)
);

-- ---------------------------------------------------------------------------
-- Daemon Status: estado de cada LaunchAgent ideiaos na máquina
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daemon_status (
  machine_id        TEXT NOT NULL REFERENCES machine(machine_id),
  label             TEXT NOT NULL,              -- ex: com.ideiaos.cockpit
  pid               INTEGER,
  status_code       TEXT,
  last_seen_epoch   INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  PRIMARY KEY (machine_id, label)
);

-- ---------------------------------------------------------------------------
-- Machine Snapshot: snapshot completo gravado pelo agentd (payload_json)
-- Inclui $.commits[].actor_class (ator classificado em v14.0, commit_log é v14.2+)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS machine_snapshot (
  machine_id        TEXT NOT NULL REFERENCES machine(machine_id),
  taken_epoch       INTEGER NOT NULL,
  agentd_version    TEXT,
  payload_json      TEXT NOT NULL,              -- snapshot ideiaos-cockpit-snapshot/v1 (sem value)
  PRIMARY KEY (machine_id, taken_epoch)
);
