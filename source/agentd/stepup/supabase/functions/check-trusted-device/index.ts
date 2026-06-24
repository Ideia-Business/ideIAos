// check-trusted-device — consulta de remember-device do step-up (v14.4 · B3 / S-05).
//
// Retorna {trusted, max_tier, expires_at} para um device same-machine. NÃO decide o skip — só reporta
// a confiança; o veredito de pular OTP é do agentd (stepup-tier-policy.sh: só `sensível` same-machine
// ≤7d). Sempre HTTP 200 (trusted:false em vez de erro). Sem roles de produto. Scaffold F0a (deploy F0b).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handlePreflight, isLoopback } from "../_shared/cors.ts";

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
  if (!subject || !device_id || !machine_id) return json({ trusted: false });

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data } = await supabase
    .from("trusted_devices").select("max_tier, expires_at, is_active, machine_id")
    .eq("subject", subject).eq("device_id", device_id).eq("machine_id", machine_id) // same-machine obrigatório
    .eq("is_active", true).gt("expires_at", new Date().toISOString()).maybeSingle();

  if (!data) return json({ trusted: false });
  return json({ trusted: true, max_tier: data.max_tier ?? "sensível", expires_at: data.expires_at });
});
