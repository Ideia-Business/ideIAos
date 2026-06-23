// verify-otp — backend dedicado de step-up (v14.4 · B3 / F0b deploy). O FIX S-01.
//
// Decisão: v14.4-step-up-without-relying-party.md + v14.4-stepup-comprovante-key-scheme.md.
// CRÍTICO: NUNCA retorna `{verified:true}` booleano (o anti-padrão do ideiapartren). Em sucesso,
//   retorna um COMPROVANTE ASSINADO `{payload_hash, sub, exp, jti, iat, kid}` + assinatura Ed25519
//   (WebCrypto, chave DEDICADA `STEPUP_SIGNING_KEY` por NOME no env — credential-isolation; ≠ SERVICE_ROLE).
//   O agentd-origem (stepup-verify-comprovante.mjs) verifica a ASSINATURA contra a pubkey PINADA
//   ANTES do binding — fecha o confused-deputy. A canonicalização aqui é byte-idêntica à do verificador.
//
// Lockout/rate-limit por EMAIL (S-07). CORS loopback (S-08). Sem signInWithPassword (S-09).
// Scaffold F0a (NÃO deployado aqui). F0b: deploy + set STEPUP_SIGNING_KEY/KID + enrollment da pubkey no agentd.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handlePreflight, isLoopback } from "../_shared/cors.ts";

const COMPROVANTE_TTL_SEC = 120; // janela curta do comprovante
const LOCKOUT_MAX = 5;           // falhas por email na janela → lockout
const LOCKOUT_WINDOW_SEC = 3600;

// Canonicalização determinística IDÊNTICA à de stepup-verify-comprovante.mjs (chaves ordenadas, sem espaço).
function canonicalize(obj: unknown): string {
  if (obj === null || typeof obj !== "object") return JSON.stringify(obj);
  if (Array.isArray(obj)) return "[" + obj.map(canonicalize).join(",") + "]";
  const o = obj as Record<string, unknown>;
  const keys = Object.keys(o).sort();
  return "{" + keys.map((k) => JSON.stringify(k) + ":" + canonicalize(o[k])).join(",") + "}";
}
const b64 = (b: ArrayBuffer) => btoa(String.fromCharCode(...new Uint8Array(b)));
const fromB64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));

async function sha256Hex(s: string): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(d)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
function sanitizeEmail(x: unknown): string { return String(x ?? "").trim().toLowerCase().slice(0, 255); }
function sanitizeHash(x: unknown): string { const h = String(x ?? "").trim().toLowerCase(); return /^[0-9a-f]{64}$/.test(h) ? h : ""; }
function sanitizeCode(x: unknown): string { return String(x ?? "").replace(/\D/g, "").slice(0, 6); }

async function signComprovante(payload_hash: string, sub: string): Promise<{ comprovante: unknown; sig: string }> {
  const pkcs8 = Deno.env.get("STEPUP_SIGNING_KEY"); // por NOME — valor nunca em log/contexto
  const kid = Deno.env.get("STEPUP_SIGNING_KID");
  if (!pkcs8 || !kid) throw new Error("signing key not configured");
  const now = Math.floor(Date.now() / 1000);
  const comprovante = {
    payload_hash, sub,
    iat: now,
    exp: now + COMPROVANTE_TTL_SEC,
    jti: crypto.randomUUID(),
    kid,
  };
  const key = await crypto.subtle.importKey("pkcs8", fromB64(pkcs8), { name: "Ed25519" }, false, ["sign"]);
  const sig = await crypto.subtle.sign({ name: "Ed25519" }, key, new TextEncoder().encode(canonicalize(comprovante)));
  return { comprovante, sig: b64(sig) };
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return handlePreflight(origin);
  if (!isLoopback(origin)) return new Response("forbidden", { status: 403 });
  if (req.method !== "POST") return new Response("method not allowed", { status: 405, headers: corsHeaders(origin) });

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...corsHeaders(origin), "content-type": "application/json" } });

  let payload: { email?: unknown; code?: unknown; payload_hash?: unknown };
  try { payload = await req.json(); } catch { return json({ error: "BAD_REQUEST" }, 400); }
  const email = sanitizeEmail(payload.email);
  const code = sanitizeCode(payload.code);
  const payload_hash = sanitizeHash(payload.payload_hash);
  if (!email || code.length !== 6 || !payload_hash) return json({ error: "BAD_REQUEST" }, 400);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // lockout por EMAIL (S-07)
  const since = new Date(Date.now() - LOCKOUT_WINDOW_SEC * 1000).toISOString();
  const { count: fails } = await supabase
    .from("otp_attempts").select("id", { count: "exact", head: true })
    .eq("email", email).eq("success", false).gte("attempted_at", since);
  if ((fails ?? 0) >= LOCKOUT_MAX) return json({ error: "ACCOUNT_LOCKED" }, 429);

  // lookup por email+payload_hash (binding), não-usado, não-expirado — o código NÃO é recuperável do DB:
  // comparamos o DIGEST salgado em tempo-constante (S-01 binding + credential-isolation: zero plaintext)
  const { data: row } = await supabase
    .from("otp_codes").select("id, code_hash, salt")
    .eq("email", email).eq("payload_hash", payload_hash)
    .is("used_at", null).gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false }).limit(1).maybeSingle();

  const expected = row ? await sha256Hex(row.salt + ":" + code) : "";
  if (!row || !timingSafeEqual(expected, row.code_hash)) {
    await supabase.from("otp_attempts").insert({ email, success: false });
    return json({ error: "INVALID_OTP" }, 400);
  }

  // consome o código (single-use) + zera falhas
  await supabase.from("otp_codes").update({ used_at: new Date().toISOString() }).eq("id", row.id);
  await supabase.from("otp_attempts").insert({ email, success: true });

  // SUCESSO = COMPROVANTE ASSINADO, jamais booleano (S-01)
  try {
    const signed = await signComprovante(payload_hash, email);
    return json(signed);
  } catch {
    return json({ error: "SIGNING_UNAVAILABLE" }, 500); // fail-closed: sem assinatura, sem aprovação
  }
});
