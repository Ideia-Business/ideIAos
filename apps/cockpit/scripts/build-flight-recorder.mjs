// SOURCE: IdeiaOS v14.1 | kind: build-step | targets: apps/cockpit
// =============================================================================
// build-flight-recorder.mjs — Deriva a fita do Flight Recorder v0 do git LOCAL.
//
// R14-05 / A12. LAW (git) vs INTERPRETED (narrativa rotulada, nunca aqui).
//
// A fita NÃO é um array literal de pins. Ela é DERIVADA do histórico real de
// `versions.lock` no repo IdeiaOS LOCAL (não precisa do ref `cockpit`):
//
//   git log --reverse --format='%H|%cI|%s|%ae' -- versions.lock
//   por commit: git show <H>:versions.lock | grep -m1 '^gsd=' | cut -d= -f2
//   (<absent> se o commit não tem linha gsd= — NUNCA inventar)
//
// Classificação de ator = a MESMA regra determinística de
// source/console/ingest.js:classifyActor (copiada verbatim abaixo, não aproximada):
//   1. subject começa com "wip: autosync"  -> 'autosync'
//   2. autor termina com ".local"           -> 'autosync'
//   3. autor contém "[bot]@"                -> 'bot'
//   4. senão                                -> 'human'
// (um check subject-only classificaria errado o commit 06-11, cujo subject é
//  `fix(...)` mas o autor é `...@Mac-mini-de-Gustavo.local` => autosync.)
//
// REVERSAL (nó âmbar): ator é autosync E o pin gsd mudou vs o commit anterior
// (o daemon re-pinando — o flip-flop real). >=1 nó reversal deve existir.
//
// Saída: apps/cockpit/src/flight-recorder.json
//   [{ hash8, iso, gsd, actor, host, subject, reversal }]
//
// Encadeado no `build` via prebuild — a fita é regenerada do git a cada build.
// O gate `test:recorder` re-deriva do git e compara SET-to-SET (exit 1 se divergir).
// =============================================================================
import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
// scripts/ -> apps/cockpit -> apps -> repo root. Resolvido de forma robusta via git.
const FALLBACK_ROOT = join(__dirname, '..', '..', '..');

function repoRoot() {
  try {
    return execFileSync('git', ['rev-parse', '--show-toplevel'], {
      cwd: FALLBACK_ROOT,
      encoding: 'utf8',
    }).trim();
  } catch {
    return FALLBACK_ROOT;
  }
}

const ROOT = repoRoot();
// Default: src/flight-recorder.json (o render). O gate test-recorder.sh
// redireciona para um /tmp sandbox via FLIGHT_RECORDER_OUT — assim a
// re-derivação nunca toca o working tree (verify-guards-in-sandbox-not-live-repo).
const OUT_PATH =
  process.env.FLIGHT_RECORDER_OUT || join(__dirname, '..', 'src', 'flight-recorder.json');

// ---------------------------------------------------------------------------
// classifyActor — VERBATIM de source/console/ingest.js:72-79 (não re-inventar)
// ---------------------------------------------------------------------------
function classifyActor(subject, author) {
  const subj = (subject || '').toLowerCase();
  const auth = (author || '').toLowerCase();
  if (subj.startsWith('wip: autosync')) return 'autosync';
  if (auth.endsWith('.local')) return 'autosync';
  if (auth.includes('[bot]@')) return 'bot';
  return 'human';
}

// ---------------------------------------------------------------------------
// deriveHost — extrai o sufixo de HOST do subject quando presente.
// "wip: autosync 2026-06-02 20:45 (Mac-mini-de-Gustavo)" -> "Mac-mini-de-Gustavo"
//
// Sem fabricar: só casa um token COM FORMA DE HOST (alfanum + hífens, sem
// espaços) no final do subject. Parênteses de prosa
// ("(migração para get-shit-done-redux)") NÃO são host -> host = null.
// LAW vs INTERPRETED: melhor null honesto do que um "host" inventado da prosa.
// ---------------------------------------------------------------------------
function deriveHost(subject) {
  const m = (subject || '').match(/\(([A-Za-z][A-Za-z0-9-]*)\)\s*$/);
  return m ? m[1] : null;
}

function git(args) {
  return execFileSync('git', args, {
    cwd: ROOT,
    encoding: 'utf8',
    maxBuffer: 16 * 1024 * 1024,
  });
}

// ---------------------------------------------------------------------------
// readPin — git show <H>:versions.lock | grep -m1 '^gsd=' | cut -d= -f2
// '<absent>' se o commit não tem linha gsd= — NUNCA inventar um valor.
// ---------------------------------------------------------------------------
function readPin(hash) {
  let raw;
  try {
    raw = git(['show', `${hash}:versions.lock`]);
  } catch {
    return '<absent>';
  }
  for (const line of raw.split('\n')) {
    if (line.startsWith('gsd=')) {
      const v = line.slice('gsd='.length).trim();
      return v.length ? v : '<absent>';
    }
  }
  return '<absent>';
}

function buildTape() {
  // --reverse => ordem cronológica (mais antigo -> mais novo), igual ao reader RQ3.
  const log = git([
    'log',
    '--reverse',
    '--format=%H|%cI|%s|%ae',
    '--',
    'versions.lock',
  ]);

  const rows = log.split('\n').filter((l) => l.trim().length > 0);
  const nodes = [];
  let prevGsd = null;

  for (const row of rows) {
    // split em '|' mas o subject pode conter '|' — limitamos aos 3 primeiros separadores.
    const i1 = row.indexOf('|');
    const i2 = row.indexOf('|', i1 + 1);
    const i3 = row.lastIndexOf('|');
    const hash = row.slice(0, i1);
    const iso = row.slice(i1 + 1, i2);
    const subject = row.slice(i2 + 1, i3);
    const author = row.slice(i3 + 1);

    const gsd = readPin(hash);
    const actor = classifyActor(subject, author);
    const host = deriveHost(subject);

    // REVERSAL: daemon (autosync) re-pinando E o pin mudou vs o anterior.
    const reversal = actor === 'autosync' && prevGsd !== null && gsd !== prevGsd;

    nodes.push({
      hash8: hash.slice(0, 8),
      iso,
      gsd, // string sempre — '<absent>' onde git não tem linha gsd=, NUNCA null
      actor,
      host,
      subject,
      reversal,
    });

    prevGsd = gsd;
  }

  return nodes;
}

const tape = buildTape();
writeFileSync(OUT_PATH, JSON.stringify(tape, null, 2) + '\n', 'utf8');

const reversals = tape.filter((n) => n.reversal).length;
process.stderr.write(
  `[flight-recorder] ${tape.length} nós derivados do git, ${reversals} reversal(s) -> ${OUT_PATH}\n`,
);
