// register-trusted-device — remember-device do step-up (v14.4 · B3 / S-05).
//
// Tiering: um device confiável só pode PULAR OTP no tier `sensível`, same-machine, janela ≤7d.
// Grava {subject, device_id, machine_id, max_tier:'sensível', expires_at: now+7d}. A decisão FINAL de
// skip é do agentd (stepup-tier-policy.sh) — este backend só registra a confiança. Sem roles de produto.
// Scaffold F0a (deploy em F0b).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handlePreflight, isLoopback } from "../_shared/cors.ts";

const TRUST_WINDOW_SEC = 7 * 24 * 3600; // ≤7d (S-05)

serve(async (req) => {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return handlePreflight(origin);
  if (!isLoopback(origin)) return new Response("forbidden", { status: 403 });
  const json = (b: unknown, s = 200) =>
    new Response(JSON.stringify(b), { status: s, headers: { ...corsHeaders(origin), "content-type": "application/json" } });

  let p: { subject?: unknown; device_id?: unknown; machine_id?: unknown };
  try { p = await req.json(); } catch { return json({ error: "BAD_REQUEST" }, 400); }
  const subject = String(p.subject ?? "").trim().toLowerCase().slice(0, 255);
  const device_id = String(p.device_id ?? "").trim().slice(0, 128);
  const machine_id = String(p.machine_id ?? "").trim().slice(0, 128);
  if (!subject || !device_id || !machine_id) return json({ error: "BAD_REQUEST" }, 400);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const expires_at = new Date(Date.now() + TRUST_WINDOW_SEC * 1000).toISOString();
  const { error } = await supabase.from("trusted_devices").upsert(
    { subject, device_id, machine_id, max_tier: "sensível", expires_at, is_active: true },
    { onConflict: "device_id" },
  );
  if (error) return json({ error: "INTERNAL" }, 500);
  return json({ success: true, max_tier: "sensível", expires_at, trustWindowDays: 7 });
});
