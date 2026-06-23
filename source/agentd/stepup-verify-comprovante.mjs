#!/usr/bin/env node
// stepup-verify-comprovante.mjs — verifica o COMPROVANTE assinado do step-up (v14.4 · B3 / F0a).
//
// Decisão: docs/decisions/v14.4-stepup-comprovante-key-scheme.md (PROPOSTO/ACEITO).
//   • O backend dedicado `ideiaos-cockpit-stepup` (Deno) assina o comprovante com Ed25519/WebCrypto
//     (primitiva DISTINTA do `ssh-keygen -Y` do O2). A privada vive só no env do backend por NOME.
//   • A PÚBLICA correspondente é PINADA no agentd-origem, out-of-band (store local 0600).
//   • Este verificador faz, FAIL-CLOSED e NESTA ORDEM (autenticidade ANTES de binding — fecha o
//     confused-deputy): (1) resolve a pubkey PINADA pelo `kid` do comprovante; kid não-pinado → exit 4;
//     (2) verifica a ASSINATURA Ed25519 sobre o JSON canônico do comprovante; inválida → exit 3;
//     (3) confere `payload_hash` == hash do comando pretendido; divergente → exit 7 (binding/R-WP3);
//     (4) confere `exp` não-expirado → exit 8.
//   O anti-replay de `jti` é DURÁVEL e fica na borda shell (stepup-token.sh) — este verificador é
//     PURO (stateless) e emite o `jti` em stdout para a borda registrar/checar.
//
// credential-isolation: NENHUM material privado entra aqui — só a PÚBLICA pinada e a assinatura.
// antifragile-gates: o resultado é o EXIT-CODE (não a leitura do stdout).
//
// Uso: stepup-verify-comprovante.mjs verify <comprovante-wire.json> <expected_payload_hash>
//   env IDEIAOS_STEPUP_PIN = store de pubkeys pinadas (default ~/.ideiaos/cockpit/stepup-backend-pubkey)
//   store: linhas "kid <spki-base64>"  (kid = rótulo de lookup; a pubkey é a âncora de confiança)
//
// Exit-codes (espelham verify-payload.sh: 3=sig-inválida, 4=não-pinado):
//   0  comprovante autêntico, bound, não-expirado (stdout: o jti)
//   2  erro de invocação / comprovante malformado
//   3  assinatura inválida           (REASON=comprovante-invalid-sig)
//   4  chave do comprovante não-pinada (REASON=comprovante-not-pinned)
//   7  binding divergente            (REASON=binding)
//   8  comprovante expirado          (REASON=expired)

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

function die(code, reason, extra = '') {
  process.stderr.write(`REASON=${reason}${extra ? ' ' + extra : ''}\n`);
  process.exit(code);
}

// Canonicalização determinística: chaves ordenadas recursivamente, sem espaço.
// DEVE ser byte-idêntica entre o assinador (backend Deno / fake-stepup-backend.mjs) e este verificador.
function canonicalize(obj) {
  if (obj === null || typeof obj !== 'object') return JSON.stringify(obj);
  if (Array.isArray(obj)) return '[' + obj.map(canonicalize).join(',') + ']';
  const keys = Object.keys(obj).sort();
  return '{' + keys.map((k) => JSON.stringify(k) + ':' + canonicalize(obj[k])).join(',') + '}';
}

function b64ToBytes(b64) {
  return new Uint8Array(Buffer.from(String(b64), 'base64'));
}

async function main() {
  const [cmd, wireFile, expectedHash] = process.argv.slice(2);
  if (cmd !== 'verify' || !wireFile || !expectedHash) {
    die(2, 'usage', '(verify <comprovante-wire.json> <expected_payload_hash>)');
  }

  // 1) Parse do comprovante wire {comprovante:{...}, sig:"<base64>"}
  let wire;
  try {
    wire = JSON.parse(readFileSync(wireFile, 'utf8'));
  } catch {
    die(2, 'malformed-wire');
  }
  const c = wire && wire.comprovante;
  const sigB64 = wire && wire.sig;
  if (!c || typeof c !== 'object' || typeof sigB64 !== 'string') die(2, 'malformed-wire');
  for (const f of ['payload_hash', 'sub', 'exp', 'jti', 'iat', 'kid']) {
    if (!(f in c)) die(2, 'malformed-comprovante', `(missing ${f})`);
  }

  // 2) Resolve a pubkey PINADA pelo kid (autoridade LOCAL; kid não-pinado → recusa ANTES de qualquer cripto)
  const pinPath = process.env.IDEIAOS_STEPUP_PIN || join(homedir(), '.ideiaos', 'cockpit', 'stepup-backend-pubkey');
  let pinned = '';
  try {
    pinned = readFileSync(pinPath, 'utf8');
  } catch {
    pinned = '';
  }
  let spkiB64 = '';
  for (const line of pinned.split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const sp = t.indexOf(' ');
    if (sp < 0) continue;
    if (t.slice(0, sp) === String(c.kid)) {
      spkiB64 = t.slice(sp + 1).trim();
      break;
    }
  }
  if (!spkiB64) die(4, 'comprovante-not-pinned', `kid=${c.kid}`);

  // 3) Verifica a ASSINATURA Ed25519 sobre o canônico do comprovante (autenticidade ANTES de binding)
  let ok = false;
  try {
    const pub = await crypto.subtle.importKey('spki', b64ToBytes(spkiB64), { name: 'Ed25519' }, false, ['verify']);
    const msg = new TextEncoder().encode(canonicalize(c));
    ok = await crypto.subtle.verify({ name: 'Ed25519' }, pub, b64ToBytes(sigB64), msg);
  } catch {
    ok = false;
  }
  if (ok !== true) die(3, 'comprovante-invalid-sig');

  // 4) Binding (R-WP3): o comprovante tem que casar o payload_hash do comando pretendido
  if (String(c.payload_hash) !== String(expectedHash)) {
    die(7, 'binding', `comprovante=${c.payload_hash} expected=${expectedHash}`);
  }

  // 5) Expiração (fail-closed)
  const now = Math.floor(Date.now() / 1000);
  const exp = Number(c.exp);
  if (!Number.isFinite(exp) || exp <= now) die(8, 'expired', `exp=${c.exp} now=${now}`);

  // Autêntico + bound + fresco — emite o jti para a borda fazer anti-replay DURÁVEL.
  process.stdout.write(String(c.jti) + '\n');
  process.exit(0);
}

main().catch((e) => die(2, 'internal-error', String(e && e.message)));
