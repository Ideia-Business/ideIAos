// SOURCE: IdeiaOS v14.1 | kind: spa-component | targets: apps/cockpit
// =============================================================================
// FlightRecorder.tsx — Flight Recorder v0 (R14-05).
//
// UMA reconstrução read-only do flip-flop real do pin `gsd` em versions.lock,
// derivada do git LOCAL do IdeiaOS (build-flight-recorder.mjs -> flight-recorder.json).
// Fita SVG de DOIS níveis (1.36.0 no topo / 1.1.0 na base), color-by-state.
//
// LAW vs INTERPRETED:
//   - LAW (git show, exit-code): pin value / ordem / reversão do daemon. É o que
//     a fita desenha e o que o gate test:recorder re-deriva SET-to-SET.
//   - INTERPRETED: a narrativa ("o daemon reverteu o human") aparece SÓ como
//     annotation ROTULADA (tag "interpretação"), nunca asserida como fato.
//
// WCAG (A10) — cor NUNCA é o único sinal: cada nó carrega o texto do pin (gsd=…)
//   + um ícone por estado (reversão / estável / normal). A entrada draw-left-to-right
//   (~600ms) é gated por @media (prefers-reduced-motion: reduce).
//
// NENHUM array literal de pins aqui — a fita vem 100% de flight-recorder.json,
// que é derivado do git no prebuild. O gate proíbe um flip-flop hard-coded.
// =============================================================================
import { useMemo, useState } from "react";
import { RotateCcw, CheckCircle2, GitCommitHorizontal } from "lucide-react";
import tape from "@/flight-recorder.json";

// ── Forma de um nó da fita (espelha flight-recorder.json) ────────────────────
export interface RecorderNode {
  hash8: string;
  iso: string;
  gsd: string; // '<absent>' onde git não tem linha gsd= — nunca null
  actor: string; // 'autosync' | 'human' | 'bot'
  host: string | null;
  subject: string;
  reversal: boolean;
}

const NODES = tape as RecorderNode[];

// ── Geometria (HealthScore technique: SVG hand-rolled, cor injetada por estado) ─
const PAD_X = 48;
const STEP_X = 64;
const Y_TOP = 40; // nível 1.36.0
const Y_BOTTOM = 120; // nível 1.1.0
const HEIGHT = 168;

// Os dois níveis são os DOIS valores de pin distintos presentes na fita (LAW —
// derivados, não hard-coded). topPin = o pin "alto" cronologicamente inicial.
function levelOf(gsd: string, topPin: string): number {
  return gsd === topPin ? Y_TOP : Y_BOTTOM;
}

// MM-DD a partir do ISO (sem dep de data — credential/dep discipline)
function mmdd(iso: string): string {
  // 2026-06-08T09:02:29-03:00 -> 06-08
  const m = iso.match(/^\d{4}-(\d{2})-(\d{2})/);
  return m ? `${m[1]}-${m[2]}` : iso.slice(0, 10);
}

// Tooltip mono: "06-08 · gsd=1.36.0 · autosync (Mac-mini-de-Gustavo) · "subject""
function tooltipOf(n: RecorderNode): string {
  const host = n.host ? ` (${n.host})` : "";
  return `${mmdd(n.iso)} · gsd=${n.gsd} · ${n.actor}${host} · "${n.subject}"`;
}

interface NodeState {
  kind: "reversal" | "stable" | "normal";
  colorVar: string; // OKLCH token (cor injetada por estado, nunca decoração)
  label: string;
}

function stateOf(n: RecorderNode, isLast: boolean): NodeState {
  if (n.reversal) {
    // âmbar — o daemon re-pinou (o flip-flop real)
    return { kind: "reversal", colorVar: "var(--status-warning)", label: "reversão" };
  }
  if (isLast) {
    // verde discreto no fim estável (✓) — NUNCA ouro ("Ouro ≠ estado")
    return { kind: "stable", colorVar: "var(--status-success)", label: "estável" };
  }
  return { kind: "normal", colorVar: "var(--muted-foreground)", label: "commit" };
}

function NodeIcon({ kind }: { kind: NodeState["kind"] }) {
  // Ícone além da cor (WCAG — cor nunca é o único sinal)
  if (kind === "reversal") return <RotateCcw className="h-3.5 w-3.5" aria-hidden />;
  if (kind === "stable") return <CheckCircle2 className="h-3.5 w-3.5" aria-hidden />;
  return <GitCommitHorizontal className="h-3.5 w-3.5" aria-hidden />;
}

export function FlightRecorder() {
  const [selected, setSelected] = useState<number | null>(null);

  const topPin = useMemo(() => (NODES.length ? NODES[0].gsd : ""), []);
  const width = PAD_X * 2 + Math.max(0, NODES.length - 1) * STEP_X;

  const points = useMemo(
    () =>
      NODES.map((n, i) => ({
        n,
        i,
        x: PAD_X + i * STEP_X,
        y: levelOf(n.gsd, topPin),
        state: stateOf(n, i === NODES.length - 1),
      })),
    [topPin],
  );

  // Linha step (orthogonal): conecta nós alternando entre os dois níveis.
  const pathD = useMemo(() => {
    if (!points.length) return "";
    let d = `M ${points[0].x} ${points[0].y}`;
    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const cur = points[i];
      const midX = (prev.x + cur.x) / 2;
      d += ` L ${midX} ${prev.y} L ${midX} ${cur.y} L ${cur.x} ${cur.y}`;
    }
    return d;
  }, [points]);

  const reversalCount = points.filter((p) => p.state.kind === "reversal").length;
  const sel = selected !== null ? points[selected] : null;

  return (
    <section
      className="fr-recorder rounded-lg border border-border bg-card p-4"
      aria-label="Flight Recorder: histórico do pin gsd em versions.lock"
    >
      {/* Motion discipline: entrada draw-left-to-right (~600ms) gated por
          prefers-reduced-motion. Quem pede menos movimento vê a fita estática. */}
      <style>{`
        .fr-pin  { font-family: ui-monospace, monospace; font-size: 10px; font-weight: 600; }
        .fr-date { font-family: ui-monospace, monospace; font-size: 9px; }
        @keyframes fr-draw-in { from { opacity: 0; transform: translateX(-6px); } to { opacity: 1; transform: none; } }
        .fr-node { cursor: pointer; outline: none; animation: fr-draw-in 600ms ease-out both; }
        .fr-node:focus-visible circle:last-of-type { stroke: oklch(var(--brand)); stroke-width: 2; }
        @media (prefers-reduced-motion: reduce) {
          .fr-node { animation: none; opacity: 1; transform: none; }
        }
      `}</style>
      {/* 1ª-classe (R15-13): título proeminente + microcopy que torna LAW vs
          INTERPRETED VISÍVEL ao usuário (antes vivia só em comentário de código). */}
      <header className="mb-3">
        <div className="flex items-baseline gap-2">
          <h2 className="text-base font-semibold tracking-tight text-[oklch(var(--brand))]">
            Flight Recorder
          </h2>
          <span className="font-mono text-xs text-muted-foreground">
            gsd · versions.lock · {NODES.length} commits · {reversalCount} reversões
          </span>
        </div>
        <p className="mt-1 max-w-prose text-xs leading-relaxed text-muted-foreground">
          Replay determinístico do pin <code className="font-mono">gsd</code>. A fita desenha só o
          que o git <strong className="font-semibold text-foreground">prova</strong> —{" "}
          <span className="font-semibold text-foreground">LAW</span> (valor do pin, ordem e reversão,
          por exit-code). A leitura narrativa ("o daemon reverteu o humano") aparece apenas no nó
          selecionado, rotulada{" "}
          <span className="rounded bg-[oklch(var(--status-warning)/0.18)] px-1 font-semibold uppercase tracking-wide text-[oklch(var(--status-warning))]">
            interpretação
          </span>{" "}
          — nunca asserida como fato.
        </p>
      </header>

      {/* Rótulos dos dois níveis (texto do pin — sinal textual, não só posição) */}
      <div className="mb-1 flex justify-between font-mono text-[11px] text-muted-foreground">
        <span>nível ◤ {topPin}</span>
        <span>nível ◣ {NODES.find((n) => n.gsd !== topPin)?.gsd ?? "—"}</span>
      </div>

      <div className="fr-scroll overflow-x-auto">
        <svg
          className="fr-svg"
          width={width}
          height={HEIGHT}
          viewBox={`0 0 ${width} ${HEIGHT}`}
          role="img"
          aria-label={`Fita de dois níveis com ${NODES.length} nós e ${reversalCount} nós de reversão`}
        >
          {/* Step-line conectando os nós (cor neutra; o ESTADO está nos nós) */}
          <path
            className="fr-line"
            d={pathD}
            fill="none"
            stroke="oklch(var(--border))"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {points.map((p) => {
            const isSel = selected === p.i;
            return (
              <g
                key={p.n.hash8}
                className="fr-node"
                style={{ animationDelay: `${p.i * 45}ms` }}
                tabIndex={0}
                role="button"
                aria-label={tooltipOf(p.n)}
                onClick={() => setSelected(isSel ? null : p.i)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    setSelected(isSel ? null : p.i);
                  }
                }}
              >
                {/* hover tooltip mono nativo (SVG <title>) */}
                <title>{tooltipOf(p.n)}</title>

                {/* anel de seleção em OURO (frame/seleção — NUNCA estado) */}
                {isSel && (
                  <circle
                    cx={p.x}
                    cy={p.y}
                    r={9}
                    fill="none"
                    stroke="oklch(var(--brand))"
                    strokeWidth={1.5}
                  />
                )}

                {/* o nó — cor INJETADA pelo estado (reversão=âmbar / estável=verde) */}
                <circle
                  cx={p.x}
                  cy={p.y}
                  r={p.state.kind === "reversal" ? 6 : 4.5}
                  fill={`oklch(${p.state.colorVar})`}
                  stroke="oklch(var(--background))"
                  strokeWidth={1.5}
                />

                {/* TEXTO do pin em cada nó (WCAG — cor não é o único sinal) */}
                <text
                  x={p.x}
                  y={p.y === Y_TOP ? p.y - 12 : p.y + 18}
                  textAnchor="middle"
                  className="fr-pin"
                  fill="oklch(var(--foreground))"
                >
                  {p.n.gsd}
                </text>
                {/* data MM-DD (segundo sinal textual) */}
                <text
                  x={p.x}
                  y={HEIGHT - 8}
                  textAnchor="middle"
                  className="fr-date"
                  fill="oklch(var(--muted-foreground))"
                >
                  {mmdd(p.n.iso)}
                </text>
              </g>
            );
          })}
        </svg>
      </div>

      {/* Painel lateral do nó selecionado — ícone + texto + cor (3 sinais) */}
      {sel && (
        <aside className="mt-3 rounded-md border border-border bg-muted/30 p-3 text-xs">
          <div className="flex items-center gap-2">
            <span style={{ color: `oklch(${sel.state.colorVar})` }}>
              <NodeIcon kind={sel.state.kind} />
            </span>
            <span className="font-mono">
              {sel.n.hash8} · gsd={sel.n.gsd} · {sel.state.label}
            </span>
          </div>
          <p className="mt-1 font-mono text-muted-foreground">{tooltipOf(sel.n)}</p>
          {sel.state.kind === "reversal" && (
            <p className="mt-2 text-[11px] text-muted-foreground">
              <span className="mr-1 rounded bg-[oklch(var(--status-warning)/0.18)] px-1 py-0.5 font-semibold uppercase tracking-wide text-[oklch(var(--status-warning))]">
                interpretação
              </span>
              o daemon de autosync re-pinou gs=
              {sel.n.gsd}, divergindo do commit anterior. (LAW = a mudança de pin no
              git; esta leitura narrativa é uma anotação, não um fato asserido.)
            </p>
          )}
        </aside>
      )}
    </section>
  );
}

export default FlightRecorder;
