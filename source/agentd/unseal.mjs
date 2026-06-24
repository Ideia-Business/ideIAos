#!/usr/bin/env node
// unseal.mjs — DESLACRA (decifra) o bundle selado no destinatário e SEPARA payload+sig (v14.4 · SEAL).
//
// Decisão: docs/decisions/v14.4-command-ref-origin-exposure.md (ACEITO).
//   Contraparte de seal.mjs. O alvo deslacra com a SUA enc-privkey (X25519), o AEAD autentica
//   (tamper de ciphertext OU destinatário errado → falha) e o framing `[len|payload|sig]` separa
//   inequivocamente. Depois do unseal, a borda chama verify-payload.sh(payload', sig') contra o pin
//   LOCAL — fechando a ordem `assina(P)→sela(P‖sig)`: deslacra → separa → verifica.
//
// PRIMITIVA: sealed-box estilo libsodium, node:crypto, ZERO dep. O blob carrega a pubkey efêmera do
//   remetente; DH(enc-privkey-local, ephemeral_pub) reconstrói o shared; HKKDF idêntico ao seal →
//   AES-256-GCM. NENHUMA identidade de destinatário no blob: só quem tem ESTA enc-privkey decifra
//   (auth-fail para qualquer outra → fail-closed).
//
// credential-isolation: a enc-privkey é referenciada por PATH e lida direto; nunca ecoada no stdout.
// antifragile-gates: o resultado é o EXIT-CODE. fail-closed em qualquer falha de AEAD/framing.
//
// Uso: unseal.mjs <blob-file> <recipient-enc-privkey-file> <out-payload> <out-sig>
//   <recipient-enc-privkey-file>: 1 linha = privkey X25519 em PKCS8 base64.
//
// Exit-codes:
//   0  deslacrado: payload + sig gravados
//   3  auth-fail (tamper OU destinatário errado — AEAD recusa)   (REASON=auth-failed)
//   2  erro de invocação / blob malformado / framing inválido     (REASON= nomeado)

import { readFileSync, writeFileSync } from 'node:fs';
import { createDecipheriv, createPrivateKey, createPublicKey, diffieHellman, hkdfSync } from 'node:crypto';

const INFO = 'ideiaos-cmd-seal/v1'; // DEVE ser byte-idêntico ao seal.mjs

function die(code, reason, extra = '') {
  process.stderr.write(`REASON=${reason}${extra ? ' ' + extra : ''}\n`);
  process.exit(code);
}

function importRawX25519Pub(raw) {
  return createPublicKey({
    key: { kty: 'OKP', crv: 'X25519', x: Buffer.from(raw).toString('base64url') },
    format: 'jwk',
  });
}

function main() {
  const [blobFile, privFile, outPayload, outSig] = process.argv.slice(2);
  if (!blobFile || !privFile || !outPayload || !outSig) {
    die(2, 'usage', '(unseal.mjs <blob-file> <recipient-enc-privkey-file> <out-payload> <out-sig>)');
  }

  // 1) Lê o blob (base64) e a enc-privkey local (PKCS8 base64).
  let blob;
  try {
    blob = Buffer.from(readFileSync(blobFile, 'utf8').trim(), 'base64');
  } catch {
    die(2, 'blob-read-failed', `(${blobFile})`);
  }
  // framing mínimo: 32 (eph) + 12 (iv) + 16 (tag) = 60 bytes de cabeçalho.
  if (blob.length < 60) die(2, 'blob-too-short', `(len=${blob.length})`);

  let priv;
  try {
    const pkcs8 = Buffer.from(readFileSync(privFile, 'utf8').trim(), 'base64');
    priv = createPrivateKey({ key: pkcs8, format: 'der', type: 'pkcs8' });
  } catch {
    die(2, 'enc-privkey-read-failed', `(${privFile})`);
  }

  const ephPubRaw = blob.subarray(0, 32);
  const iv = blob.subarray(32, 44);
  const tag = blob.subarray(44, 60);
  const ct = blob.subarray(60);

  // 2) Reconstrói o shared via DH(privkey-local, ephemeral_pub) → HKDF idêntico ao seal.
  let pt;
  try {
    const ephPub = importRawX25519Pub(ephPubRaw);
    const shared = diffieHellman({ privateKey: priv, publicKey: ephPub });
    const dk = Buffer.from(hkdfSync('sha256', shared, ephPubRaw, Buffer.from(INFO), 32));
    const decipher = createDecipheriv('aes-256-gcm', dk, iv);
    decipher.setAuthTag(tag);
    pt = Buffer.concat([decipher.update(ct), decipher.final()]); // .final() LANÇA se a tag não casar
  } catch {
    // tamper de ciphertext OU enc-privkey errada (destinatário errado) → AEAD recusa. fail-closed.
    die(3, 'auth-failed');
  }

  // 3) Separa via o framing [4 BE len(payload)] || payload || sig.
  if (pt.length < 4) die(2, 'framing-too-short');
  const plen = pt.readUInt32BE(0);
  if (4 + plen > pt.length) die(2, 'framing-invalid', `(payload_len=${plen} exceeds blob)`);
  const payload = pt.subarray(4, 4 + plen);
  const sig = pt.subarray(4 + plen);

  try {
    writeFileSync(outPayload, payload);
    writeFileSync(outSig, sig);
  } catch {
    die(2, 'out-write-failed');
  }
  process.exit(0);
}

main();
