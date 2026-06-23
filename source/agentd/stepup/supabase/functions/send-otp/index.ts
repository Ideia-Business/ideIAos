// send-otp — backend dedicado de step-up `ideiaos-cockpit-stepup` (v14.4 · B3 / F0b deploy).
//
// Decisões: v14.4-step-up-without-relying-party.md (HYBRID) + v14.4-stepup-comprovante-key-scheme.md.
// Condições de adoção exercidas aqui: CSPRNG (S-06) · binding payload_hash (S-01) ·
//   rate-limit por EMAIL/subject, não IP (S-07) · CORS loopback (S-08) · SEM signInWithPassword (S-09).
//
// O código é amarrado ao `payload_hash` do COMANDO (não a um login). O e-mail mostra a AÇÃO em claro
// (action_label) + o código. NÃO autentica usuário de produto — só prova posse do e-mail allowlisted.
//
// Scaffold F0a (NÃO deployado aqui). F0b: deploy no projeto DEDICADO, SERVICE_ROLE isolada, zero dado
// de produto. Mineração ADAPTADA do ideiapartner: RLS deny-all + lockout/rate-limit; o gerador de OTP
// do ideiapartner (Math.random) NÃO foi reusado — aqui é CSPRNG.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handlePreflight, isLoopback } from "../_shared/cors.ts";

// allowlist de subjects (e-mails autorizados a aprovar) — config por env, NÃO roles de produto.
const ALLOWED = (Deno.env.get("STEPUP_ALLOWED_SUBJECTS") ?? "").split(",").map((s) => s.trim().toLowerCase()).filter(Boolean);
const OTP_TTL_SEC = 300; // 5 min
const RL_MAX = 5;        // máx pedidos por email na janela
const RL_WINDOW_SEC = 60;

// CSPRNG (S-06) — NUNCA o gerador fraco. 6 dígitos.
function generateOtp(): string {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return String(buf[0] % 1_000_000).padStart(6, "0");
}
const b64 = (b: Uint8Array) => btoa(String.fromCharCode(...b));
async function sha256Hex(s: string): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(d)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function sanitizeEmail(x: unknown): string {
  return String(x ?? "").trim().toLowerCase().slice(0, 255);
}
function sanitizeHash(x: unknown): string {
  const h = String(x ?? "").trim().toLowerCase();
  return /^[0-9a-f]{64}$/.test(h) ? h : "";
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return handlePreflight(origin);
  if (!isLoopback(origin)) return new Response("forbidden", { status: 403 });
  if (req.method !== "POST") return new Response("method not allowed", { status: 405, headers: corsHeaders(origin) });

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...corsHeaders(origin), "content-type": "application/json" } });

  let payload: { email?: unknown; payload_hash?: unknown; action_label?: unknown };
  try { payload = await req.json(); } catch { return json({ error: "BAD_REQUEST" }, 400); }

  const email = sanitizeEmail(payload.email);
  const payload_hash = sanitizeHash(payload.payload_hash);
  const action_label = String(payload.action_label ?? "").slice(0, 200);
  if (!email || !payload_hash) return json({ error: "BAD_REQUEST" }, 400);
  if (ALLOWED.length && !ALLOWED.includes(email)) return json({ error: "FORBIDDEN_SUBJECT" }, 403);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Rate-limit ANCORADO EM EMAIL/subject (S-07), não IP.
  const since = new Date(Date.now() - RL_WINDOW_SEC * 1000).toISOString();
  const { count } = await supabase
    .from("otp_codes").select("id", { count: "exact", head: true })
    .eq("email", email).gte("created_at", since);
  if ((count ?? 0) >= RL_MAX) return json({ error: "RATE_LIMIT_EXCEEDED", retryAfterSec: RL_WINDOW_SEC }, 429);

  const code = generateOtp();
  const salt = b64(crypto.getRandomValues(new Uint8Array(16)));
  const code_hash = await sha256Hex(salt + ":" + code); // grava o DIGEST, nunca o código recuperável
  const expires_at = new Date(Date.now() + OTP_TTL_SEC * 1000).toISOString();

  // invalida códigos anteriores deste email+binding e grava o novo (RLS deny-all; só service_role escreve)
  await supabase.from("otp_codes").delete().eq("email", email).is("used_at", null);
  const { error } = await supabase.from("otp_codes").insert({ email, code_hash, salt, payload_hash, expires_at });
  if (error) return json({ error: "INTERNAL" }, 500);

  // Envio do e-mail (a AÇÃO em claro + o código). Sem branding de produto. Falha de envio = fail-closed.
  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (resendKey) {
    const subject = `IdeiaOS Cockpit — aprovação: ${action_label || "ação"}`;
    const html = `<p>Pedido de aprovação para a ação:</p><pre>${action_label}</pre>` +
      `<p>Código (válido 5 min): <strong>${code}</strong></p>` +
      `<p>Se você não pediu isto, ignore — nada acontece sem o código.</p>`;
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Authorization": `Bearer ${resendKey}`, "content-type": "application/json" },
      body: JSON.stringify({ from: Deno.env.get("STEPUP_MAIL_FROM") ?? "cockpit@ideiaos.local", to: email, subject, html }),
    });
    if (!r.ok) return json({ error: "MAIL_FAILED" }, 502); // fail-closed: sem e-mail, sem OTP
  }

  return json({ success: true });
});
