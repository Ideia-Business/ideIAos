// SOURCE: IdeiaOS v14.1 | kind: spa-component | targets: apps/cockpit
// =============================================================================
// SystemPulse.tsx — hero de heartbeat do Overview (R14-05; spec "Frescor honesto").
//
// FRESCOR HONESTO (a regra-piso desta tela):
//   - O pulso ANIMA SOMENTE no heartbeat LOCAL: um fetch curto (~3s) do snapshot
//     da PRÓPRIA máquina (GET /fleet -> a máquina cujo last_seen é o mais recente
//     e fresco). Enquanto o sinal local está fresco, o coração bate.
//   - Nós REMOTOS nunca animam: mostram IDADE HONESTA "último sinal há Xh"
//     derivada de last_seen_epoch. NUNCA simulamos fluxo contínuo sobre um lote.
//
// COR NÃO É O ÚNICO SINAL (WCAG 2.1 AA — A10):
//   - Estado crítico => vermelho/arrítmico COM um LABEL textual ("CRÍTICO") e
//     aria-label. A cor é reforço, jamais o único indicador.
//   - A animação `pulse-warn` é gated por @media (prefers-reduced-motion: reduce):
//     quem pede menos movimento vê o estado estático (texto + ícone continuam).
// =============================================================================
import { useEffect, useState } from "react";
import { HeartPulse, AlertTriangle, WifiOff } from "lucide-react";

// Limiares de frescor (segundos). Local fresco => bate; senão => idade honesta.
const FRESH_LOCAL_S = 300; // ≤5min do snapshot local = "vivo"
const STALE_WARN_S = 1800; // 30min sem sinal = atenção
const CRITICAL_S = 7200; // ≥2h sem sinal = crítico
const POLL_MS = 3000; // heartbeat local: fetch curto ~3s

export interface PulseNode {
  machine_id: string;
  canonical_name: string | null;
  last_seen_epoch: number | null;
  last_doctor: string; // "ok" | "warn" | "fail" | "unknown"
}

type PulseStatus = "alive" | "stale" | "critical" | "offline";

interface PulseState {
  status: PulseStatus;
  /** LABEL textual — o sinal não-cor (WCAG). */
  label: string;
  colorVar: string;
}

// Deriva o estado do nó LOCAL a partir da idade + do doctor (LAW, não decoração).
function statusOf(ageSeconds: number | null, lastDoctor: string): PulseState {
  if (ageSeconds === null) {
    return { status: "offline", label: "SEM SINAL", colorVar: "var(--muted-foreground)" };
  }
  if (lastDoctor === "fail" || ageSeconds >= CRITICAL_S) {
    return { status: "critical", label: "CRÍTICO", colorVar: "var(--status-warning)" };
  }
  if (lastDoctor === "warn" || ageSeconds >= STALE_WARN_S) {
    return { status: "stale", label: "ATENÇÃO", colorVar: "var(--status-warning)" };
  }
  return { status: "alive", label: "VIVO", colorVar: "var(--status-success)" };
}

// Idade honesta legível: "agora", "há Xm", "há Xh", "há Xd". NUNCA inventa frescor.
function humanAge(ageSeconds: number | null): string {
  if (ageSeconds === null) return "sem registro de sinal";
  if (ageSeconds < 60) return "último sinal agora";
  if (ageSeconds < 3600) return `último sinal há ${Math.floor(ageSeconds / 60)}m`;
  if (ageSeconds < 86400) return `último sinal há ${Math.floor(ageSeconds / 3600)}h`;
  return `último sinal há ${Math.floor(ageSeconds / 86400)}d`;
}

export interface SystemPulseProps {
  /** Base loopback do read.js (http://127.0.0.1:3073). */
  apiBase: string;
}

export function SystemPulse({ apiBase }: SystemPulseProps) {
  const [nodes, setNodes] = useState<PulseNode[]>([]);
  const [nowEpoch, setNowEpoch] = useState(() => Math.floor(Date.now() / 1000));
  const [err, setErr] = useState<string | null>(null);

  // HEARTBEAT LOCAL: poll curto ~3s do /fleet — o pulso vivo vem do snapshot da
  // própria máquina (o nó mais recente), não de uma animação fabricada sobre lote.
  useEffect(() => {
    let cancelled = false;
    async function beat() {
      try {
        const res = await fetch(`${apiBase}/fleet`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = (await res.json()) as PulseNode[];
        if (!cancelled) {
          setNodes(data);
          setNowEpoch(Math.floor(Date.now() / 1000));
          setErr(null);
        }
      } catch (e) {
        if (!cancelled) setErr(e instanceof Error ? e.message : String(e));
      }
    }
    beat();
    const id = window.setInterval(beat, POLL_MS);
    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, [apiBase]);

  // Nó LOCAL = o de last_seen_epoch mais recente (o que esta máquina acabou de gravar).
  const local =
    nodes.length > 0
      ? nodes.reduce((a, b) =>
          (b.last_seen_epoch ?? 0) > (a.last_seen_epoch ?? 0) ? b : a,
        )
      : null;

  const localAge =
    local && local.last_seen_epoch !== null ? nowEpoch - local.last_seen_epoch : null;
  const localState = statusOf(localAge, local?.last_doctor ?? "unknown");

  // O coração ANIMA só quando o sinal local está FRESCO (≤FRESH_LOCAL_S). Caso
  // contrário fica estático (frescor honesto: nada de batida sobre dado velho).
  const localIsLive =
    localState.status === "alive" && localAge !== null && localAge <= FRESH_LOCAL_S;

  // Nós REMOTOS = todos menos o local; cada um mostra idade honesta (não anima).
  const remotes = local ? nodes.filter((n) => n.machine_id !== local.machine_id) : nodes;

  return (
    <section
      className="rounded-lg border border-border bg-card p-6"
      aria-label={`System Pulse — sinal local ${localState.label}`}
    >
      {/* Animação pulse-warn gated por prefers-reduced-motion (A10). Só o nó
          LOCAL e fresco anima; crítico bate em ritmo arrítmico (mais rápido). */}
      <style>{`
        @keyframes sp-beat { 0%,100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.18); opacity: 0.7; } }
        @keyframes sp-arrhythmic { 0% { transform: scale(1); } 12% { transform: scale(1.25); } 24% { transform: scale(1); } 40% { transform: scale(1.1); } 100% { transform: scale(1); } }
        .sp-beat { animation: sp-beat 1.6s ease-in-out infinite; }
        .sp-arrhythmic { animation: sp-arrhythmic 0.9s ease-in-out infinite; }
        @media (prefers-reduced-motion: reduce) {
          .sp-beat, .sp-arrhythmic { animation: none; }
        }
      `}</style>

      <header className="mb-4 flex items-center gap-3">
        <span
          style={{ color: `oklch(${localState.colorVar})` }}
          className={
            !localIsLive
              ? ""
              : localState.status === "critical"
                ? "sp-arrhythmic"
                : "sp-beat"
          }
        >
          {localState.status === "offline" ? (
            <HeartPulse className="h-7 w-7 opacity-40" aria-hidden />
          ) : localState.status === "critical" ? (
            <AlertTriangle className="h-7 w-7" aria-hidden />
          ) : (
            <HeartPulse className="h-7 w-7" aria-hidden />
          )}
        </span>
        <div>
          <h2 className="text-sm font-semibold tracking-tight text-[oklch(var(--brand))]">
            System Pulse
          </h2>
          {/* LABEL textual do estado — cor NUNCA é o único sinal (WCAG/A10) */}
          <p className="flex items-center gap-2 text-xs">
            <span
              className="rounded px-1.5 py-0.5 font-semibold uppercase tracking-wide"
              style={{
                color: `oklch(${localState.colorVar})`,
                backgroundColor: `oklch(${localState.colorVar} / 0.15)`,
              }}
            >
              {localState.label}
            </span>
            <span className="text-muted-foreground">
              {local
                ? `${local.canonical_name ?? local.machine_id} · ${humanAge(localAge)}`
                : "sem máquina no read-model"}
            </span>
          </p>
        </div>
      </header>

      {err && (
        <p className="mb-3 text-xs text-[oklch(var(--status-warning))]">
          heartbeat indisponível: {err}
        </p>
      )}

      {/* Nós REMOTOS — idade honesta textual, SEM animação (frescor honesto) */}
      <ul className="space-y-1.5">
        {remotes.length === 0 && (
          <li className="text-xs text-muted-foreground">
            nenhum nó remoto — operação monousuário
          </li>
        )}
        {remotes.map((n) => {
          const age = n.last_seen_epoch !== null ? nowEpoch - n.last_seen_epoch : null;
          const st = statusOf(age, n.last_doctor);
          return (
            <li
              key={n.machine_id}
              className="flex items-center gap-2 text-xs"
              aria-label={`${n.canonical_name ?? n.machine_id}: ${st.label}, ${humanAge(age)}`}
            >
              {/* ponto estático (NÃO anima — remoto mostra idade, não fluxo) */}
              {age === null ? (
                <WifiOff className="h-3.5 w-3.5 text-muted-foreground" aria-hidden />
              ) : (
                <span
                  className="inline-block h-2.5 w-2.5 rounded-full"
                  style={{ backgroundColor: `oklch(${st.colorVar})` }}
                  aria-hidden
                />
              )}
              <span className="font-mono text-foreground">
                {n.canonical_name ?? n.machine_id}
              </span>
              {/* LABEL textual do estado remoto — segundo sinal além da cor */}
              <span
                className="font-semibold uppercase tracking-wide"
                style={{ color: `oklch(${st.colorVar})` }}
              >
                {st.label}
              </span>
              <span className="ml-auto text-muted-foreground">{humanAge(age)}</span>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

export default SystemPulse;
