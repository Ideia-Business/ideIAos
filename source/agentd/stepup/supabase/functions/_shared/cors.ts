// _shared/cors.ts — CORS LOOPBACK-ONLY do backend dedicado de step-up (v14.4 · S-08).
//
// Decisão: v14.4-step-up-without-relying-party.md — o backend só atende o Cockpit em loopback.
// NUNCA `Access-Control-Allow-Origin: *`. Só http://127.0.0.1:<porta> ou http://localhost:<porta>
// são refletidos (exato), com Vary: Origin. Origem não-loopback → sem headers CORS (browser bloqueia).
//
// Scaffold F0a: deployado em F0b no projeto dedicado `ideiaos-cockpit-stepup`.

const LOOPBACK = /^http:\/\/(127\.0\.0\.1|localhost)(:\d{1,5})?$/;

export function corsHeaders(origin: string | null): Record<string, string> {
  const base: Record<string, string> = {
    "Vary": "Origin",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "content-type",
  };
  if (origin && LOOPBACK.test(origin)) {
    base["Access-Control-Allow-Origin"] = origin; // exato, nunca '*'
  }
  return base;
}

export function isLoopback(origin: string | null): boolean {
  return !!origin && LOOPBACK.test(origin);
}

// preflight: 204 só p/ loopback; 403 caso contrário (sem Allow-Origin)
export function handlePreflight(origin: string | null): Response {
  if (isLoopback(origin)) return new Response(null, { status: 204, headers: corsHeaders(origin) });
  return new Response(null, { status: 403, headers: { "Vary": "Origin" } });
}
