#!/usr/bin/env node
// fake-stepup-backend.mjs — assinador de COMPROVANTE de TESTE (v14.4 · F0a, harness-only).
//
// NÃO é código de produção. Mimetiza o que a edge function `verify-otp` (Deno) fará: assinar o
// comprovante com Ed25519/WebCrypto sobre o JSON canônico — byte-idêntico ao que
// `source/agentd/stepup-verify-comprovante.mjs` verifica. Existe só para o gate de bootstrap gerar
// fixtures (chave Ed25519 DESCARTÁVEL em /tmp; NÃO é o STEPUP_SIGNING_KEY real — credential-isolation
// se aplica a segredo real, este é fixture efêmero).
//
// Subcomandos:
//   gen-keypair                       -> stdout JSON {kid, spki_b64, pkcs8_b64}
//   sign <pkcs8_b64> <comprovante.json> -> stdout wire {comprovante, sig}
//
// O `kid` = sha256(spki) hex (16 chars) — rótulo de lookup do pin.

import { readFileSync } from 'node:fs';

// Canonicalização IDÊNTICA à do verificador (chaves ordenadas, sem espaço).
function canonicalize(obj) {
  if (obj === null || typeof obj !== 'object') return JSON.stringify(obj);
  if (Array.isArray(obj)) return '[' + obj.map(canonicalize).join(',') + ']';
  const keys = Object.keys(obj).sort();
  return '{' + keys.map((k) => JSON.stringify(k) + ':' + canonicalize(obj[k])).join(',') + '}';
}

const toB64 = (buf) => Buffer.from(buf).toString('base64');
const fromB64 = (b64) => new Uint8Array(Buffer.from(String(b64), 'base64'));

async function genKeypair() {
  const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
  const spki = new Uint8Array(await crypto.subtle.exportKey('spki', kp.publicKey));
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', kp.privateKey));
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', spki));
  const kid = Buffer.from(digest).toString('hex').slice(0, 16);
  process.stdout.write(JSON.stringify({ kid, spki_b64: toB64(spki), pkcs8_b64: toB64(pkcs8) }) + '\n');
}

async function sign(pkcs8B64, comprovanteFile) {
  const comprovante = JSON.parse(readFileSync(comprovanteFile, 'utf8'));
  const priv = await crypto.subtle.importKey('pkcs8', fromB64(pkcs8B64), { name: 'Ed25519' }, false, ['sign']);
  const msg = new TextEncoder().encode(canonicalize(comprovante));
  const sig = new Uint8Array(await crypto.subtle.sign({ name: 'Ed25519' }, priv, msg));
  process.stdout.write(JSON.stringify({ comprovante, sig: toB64(sig) }) + '\n');
}

const [cmd, ...rest] = process.argv.slice(2);
if (cmd === 'gen-keypair') await genKeypair();
else if (cmd === 'sign') await sign(rest[0], rest[1]);
else {
  process.stderr.write('usage: fake-stepup-backend.mjs {gen-keypair|sign <pkcs8_b64> <comprovante.json>}\n');
  process.exit(2);
}
