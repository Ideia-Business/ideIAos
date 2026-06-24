#!/usr/bin/env node
// seal.mjs — SELA (cifra) o bundle de comando ao destinatário (v14.4 · SEAL do canal de comando).
//
// Decisão: docs/decisions/v14.4-command-ref-origin-exposure.md (ACEITO) — cláusula
//   "Conteúdo: SELO + ordem cripto fixa": o produtor 1º ASSINA o payload (O2, sign-payload.sh →
//   assinatura DESTACADA .sig) e DEPOIS sela `payload‖sig` JUNTOS à chave de encriptação pinada do
//   alvo. ORDEM OBRIGATÓRIA `assina(P) → sela(P‖sig)`. PROIBIDO seal-then-sign (assinar ciphertext
//   não prova origem do conteúdo → confused-deputy). O `.sig` em claro vazaria o fingerprint da
//   máquina-origem ao terceiro; por isso a assinatura é selada JUNTO ao payload.
//
// PRIMITIVA (nativa, ZERO dep — host sem `age`/openssl-X25519; Node X25519 PROVADO viável):
//   sealed-box estilo libsodium em node:crypto:
//     par EFÊMERO X25519 do remetente + diffieHellman com a enc_pubkey raw do destinatário → shared;
//     hkdfSync('sha256', shared, salt=ephemeral_pubkey, info='ideiaos-cmd-seal/v1', 32) → AES-256-GCM.
//   Salt = a pubkey efêmera (domínio-separado por handshake; nunca reusa chave AEAD entre selos).
//   Blob (base64 de): ephemeral_pubkey(32 raw) || iv(12) || tag(16) || ciphertext.
//   NENHUMA identidade de destinatário no blob — só quem tem a enc-privkey decifra (R-WP6: sem alvo
//   em claro; o destinatário viaja DENTRO do ciphertext, nunca no nome do ref/path/blob).
//
// credential-isolation: a privada do remetente é EFÊMERA (gerada e descartada nesta invocação) e a
//   enc_pubkey do destinatário é PÚBLICA (raw base64); nenhum segredo durável transita aqui.
// antifragile-gates: o resultado é o EXIT-CODE (não a leitura do stdout). fail-closed.
//
// Uso: seal.mjs <payload-file> <sig-file> <recipient-enc-pubkey-file> [out-blob]
//   <recipient-enc-pubkey-file>: 1 linha = pubkey X25519 raw em base64 (32 bytes) — vem SÓ do pin local.
//   [out-blob]: se omitido, escreve o blob base64 em stdout.
//
// Exit-codes:
//   0  selado
//   >=2 erro de invocação / fail-closed (REASON= nomeado em stderr)

import { readFileSync, writeFileSync } from 'node:fs';
import {
  createCipheriv,
  createPublicKey,
  diffieHellman,
  generateKeyPairSync,
  hkdfSync,
  randomBytes,
} from 'node:crypto';

const INFO = 'ideiaos-cmd-seal/v1'; // domínio-separado do KDF (distinto de qualquer outra primitiva)

function die(code, reason, extra = '') {
  process.stderr.write(`REASON=${reason}${extra ? ' ' + extra : ''}\n`);
  process.exit(code);
}

// Importa uma pubkey X25519 raw (32 bytes) como KeyObject (via jwk OKP).
function importRawX25519Pub(raw) {
  if (raw.length !== 32) die(2, 'bad-enc-pubkey', `(len=${raw.length}, want 32)`);
  return createPublicKey({
    key: { kty: 'OKP', crv: 'X25519', x: Buffer.from(raw).toString('base64url') },
    format: 'jwk',
  });
}

function main() {
  const [payloadFile, sigFile, pubFile, outBlob] = process.argv.slice(2);
  if (!payloadFile || !sigFile || !pubFile) {
    die(2, 'usage', '(seal.mjs <payload-file> <sig-file> <recipient-enc-pubkey-file> [out-blob])');
  }

  // 1) Lê payload + assinatura DESTACADA (já produzida por sign-payload.sh — assina(P) ANTES de selar)
  let payload, sig;
  try {
    payload = readFileSync(payloadFile);
  } catch {
    die(2, 'payload-read-failed', `(${payloadFile})`);
  }
  try {
    sig = readFileSync(sigFile);
  } catch {
    die(2, 'sig-read-failed', `(${sigFile})`);
  }
  if (sig.length === 0) die(2, 'empty-sig'); // selar sem assinatura derrotaria a prova de origem

  // 2) Resolve a enc_pubkey raw do destinatário (SÓ do pin local — nunca do payload/ref)
  let pubRaw;
  try {
    pubRaw = Buffer.from(readFileSync(pubFile, 'utf8').trim(), 'base64');
  } catch {
    die(2, 'enc-pubkey-read-failed', `(${pubFile})`);
  }
  const recipientPub = importRawX25519Pub(pubRaw);

  // 3) Framing do CONTEÚDO selado: [4 bytes BE = len(payload)] || payload || sig — split inequívoco.
  const lenPrefix = Buffer.alloc(4);
  lenPrefix.writeUInt32BE(payload.length, 0);
  const sealedContent = Buffer.concat([lenPrefix, payload, sig]);

  // 4) Sealed-box: par EFÊMERO + DH com a pubkey do destinatário → shared → HKDF → AES-256-GCM.
  const eph = generateKeyPairSync('x25519');
  const ephPubRaw = Buffer.from(eph.publicKey.export({ format: 'jwk' }).x, 'base64url');
  const shared = diffieHellman({ privateKey: eph.privateKey, publicKey: recipientPub });
  // salt = pubkey efêmera (handshake-único) — garante chave AEAD nunca reusada entre selos.
  const dk = Buffer.from(hkdfSync('sha256', shared, ephPubRaw, Buffer.from(INFO), 32));
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', dk, iv);
  const ct = Buffer.concat([cipher.update(sealedContent), cipher.final()]);
  const tag = cipher.getAuthTag();

  // 5) Blob = ephemeral_pubkey(32) || iv(12) || tag(16) || ciphertext  (base64; SEM alvo em claro)
  const blob = Buffer.concat([ephPubRaw, iv, tag, ct]).toString('base64');

  if (outBlob) {
    try {
      writeFileSync(outBlob, blob + '\n');
    } catch {
      die(2, 'out-write-failed', `(${outBlob})`);
    }
  } else {
    process.stdout.write(blob + '\n');
  }
  process.exit(0);
}

main();
