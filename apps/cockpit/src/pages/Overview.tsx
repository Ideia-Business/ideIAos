// SOURCE: IdeiaOS v14.1 | kind: spa-page | targets: apps/cockpit
// =============================================================================
// Overview.tsx — a primeira tela de valor (R14-05; spec). Bento grid + banda
// Flight Recorder.
//
// Compõe (ordem 1ª-classe — R15-13):
//   - System Pulse hero (heartbeat LOCAL-vivo; remoto = idade honesta).
//   - Banda Flight Recorder (<FlightRecorder/>) ELEVADA logo após o hero — é a
//     peça narrativa central (replay determinístico LAW vs INTERPRETED), não um
//     rodapé. R15-13: 1ª-classe + microcopy visível; filtro por máquina DIFERIDO.
//   - StatCards: MÁQUINAS / PROJETOS / CHECKS OK (de GET /overview).
//   - Card "Saúde & Governança" (R15-14): servido por GET read-only
//     (/overview = saúde do doctor · /soak = governança-SOAK real). NUNCA
//     POST /command, NUNCA spawnSync idea-doctor por load, NUNCA --record.
//   - Cards Frota (resumo) e Atenção-Agora.
//
// HONESTIDADE (spec):
//   - Releases-SOAK usa o /soak REAL (span gravado = MAX-MIN epoch), não o proxy
//     `machines>=2`. span_ge_1d é o gate de verdade.
//   - Saúde-por-produto onde idea-doctor não roda (Lovable) => `n/a`, nunca nota
//     fabricada. checks.unknown NÃO conta como falha.
//   - Frescor de segurança (tier): net-new de coleta DIFERIDO — slot honesto
//     "aguardando coleta", nunca um tier fabricado (mesma disciplina do R15-12
//     com doctor.sections=[]). Preenche quando o collect.js coletar o tier.
// =============================================================================
import { useEffect, useState } from "react";
import {
  Server,
  FolderGit2,
  ShieldCheck,
  Boxes,
  Tag,
  Bell,
  Lock,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { StatCard } from "@/components/StatCard";
import { SystemPulse } from "@/components/SystemPulse";
import { FlightRecorder } from "@/components/FlightRecorder";

interface OverviewChecks {
  ok: number;
  warn: number;
  fail: number;
  unknown: number;
}

interface OverviewData {
  machines: number;
  projects: number;
  checks: OverviewChecks;
}

// Forma de uma linha de GET /soak (espelha read.js handleSoak).
interface SoakRow {
  milestone: string;
  heartbeats: number;
  hosts: number;
  span_seconds: number;
  span_ge_1d: boolean;
  last_idea_doctor: string;
}

export interface OverviewProps {
  /** Base loopback do read.js (http://127.0.0.1:3073). */
  apiBase: string;
}

export default function Overview({ apiBase }: OverviewProps) {
  const [data, setData] = useState<OverviewData | null>(null);
  const [soak, setSoak] = useState<SoakRow[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mesmo padrão useEffect/cancelled do App.tsx (loopback fetch canônico).
  // /overview é obrigatório (bloqueia a tela); /soak é best-effort (o card
  // degrada honestamente se faltar — nunca derruba o Overview).
  useEffect(() => {
    let cancelled = false;
    async function fetchAll() {
      try {
        const res = await fetch(`${apiBase}/overview`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = (await res.json()) as OverviewData;
        if (!cancelled) {
          setData(json);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e));
          setLoading(false);
        }
      }
      // /soak — best-effort, independente do overview (governança real).
      try {
        const r = await fetch(`${apiBase}/soak`);
        if (r.ok) {
          const rows = (await r.json()) as SoakRow[];
          if (!cancelled && Array.isArray(rows)) setSoak(rows);
        }
      } catch {
        /* /soak indisponível → card mostra "sem heartbeats", nunca inventa */
      }
    }
    fetchAll();
    return () => {
      cancelled = true;
    };
  }, [apiBase]);

  if (loading) {
    return <p className="text-sm text-muted-foreground">Carregando overview...</p>;
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-700/40 bg-red-900/20 p-4 text-sm text-red-400">
        Erro ao carregar /overview: {error}
        <br />
        <span className="text-xs text-muted-foreground">
          Confirme o read.js rodando: <code>node apps/cockpit/server/read.js</code>
        </span>
      </div>
    );
  }

  const checks = data?.checks ?? { ok: 0, warn: 0, fail: 0, unknown: 0 };
  const machines = data?.machines ?? 0;
  const projects = data?.projects ?? 0;
  const checksTotal = checks.ok + checks.warn + checks.fail + checks.unknown;

  // CHECKS OK accent: success se tudo ok; warning se há warn/fail; neutro se vazio.
  const checksAccent =
    checks.fail > 0 || checks.warn > 0 ? "warning" : checks.ok > 0 ? "success" : "neutral";

  // Saúde-por-produto honesta: `unknown` (idea-doctor n/a, ex.: Lovable) é
  // renderizado como n/a, jamais somado como falha.
  const naCount = checks.unknown;
  const healthVariant = checks.fail > 0 ? "fail" : checks.warn > 0 ? "warn" : "ok";

  // Governança-SOAK do /soak REAL (não o proxy machines>=2): quantos milestones,
  // quantos com span≥1d gravado, e o pico de hosts observado.
  const soakRows = soak ?? [];
  const soakLoaded = soakRows.length > 0;
  const span1dCount = soakRows.filter((s) => s.span_ge_1d).length;
  const maxHosts = soakRows.reduce((m, s) => Math.max(m, s.hosts), 0);

  return (
    <div className="space-y-6">
      {/* ── Hero: System Pulse (local-vivo; remoto idade honesta) ── */}
      <SystemPulse apiBase={apiBase} />

      {/* ── Flight Recorder ELEVADO a 1ª-classe (R15-13): logo após o hero, não
            no rodapé. É a peça narrativa central (replay determinístico). ── */}
      <FlightRecorder />

      {/* ── Bento: StatCards de métrica ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatCard title="Máquinas" value={machines} icon={Server} />
        <StatCard title="Projetos" value={projects} icon={FolderGit2} />
        <StatCard
          title="Checks OK"
          value={checksTotal > 0 ? `${checks.ok}/${checksTotal}` : "n/a"}
          subtitle={naCount > 0 ? `${naCount} n/a (idea-doctor não roda)` : undefined}
          icon={ShieldCheck}
          accent={checksAccent}
        />
      </div>

      {/* ── Bento: cards de resumo ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Frota (resumo) */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <Boxes className="h-4 w-4 text-[oklch(var(--brand))]" aria-hidden />
              <CardTitle>Frota</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <p className="font-mono text-xl">{machines}</p>
            <p className="text-xs text-muted-foreground">
              {machines === 1 ? "1 máquina" : `${machines} máquinas`}
            </p>
          </CardContent>
        </Card>

        {/* ── Saúde & Governança (R15-14) — card consolidado servido por GET
              read-only: /overview (saúde do doctor) + /soak (governança-SOAK
              real). Sem spawnSync, sem POST /command, sem --record. ── */}
        <Card className="sm:col-span-2">
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-[oklch(var(--brand))]" aria-hidden />
              <CardTitle>Saúde &amp; Governança</CardTitle>
              <span className="ml-auto font-mono text-[10px] uppercase tracking-wide text-muted-foreground">
                GET read-only
              </span>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 sm:grid-cols-3">
              {/* Pilar 1 — Saúde (doctor agregado, de /overview) */}
              <div className="space-y-1">
                <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                  <ShieldCheck className="h-3.5 w-3.5" aria-hidden />
                  Saúde · idea-doctor
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant={healthVariant}>{healthVariant}</Badge>
                  <span className="font-mono text-xs">
                    {checksTotal > 0 ? `${checks.ok}/${checksTotal}` : "n/a"}
                  </span>
                </div>
                {naCount > 0 && (
                  <p className="text-xs text-muted-foreground">
                    {naCount} <span className="font-mono">n/a</span> (não roda em Lovable)
                  </p>
                )}
              </div>

              {/* Pilar 2 — Releases-SOAK (do /soak REAL: span gravado, não wall-clock) */}
              <div className="space-y-1">
                <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                  <Tag className="h-3.5 w-3.5" aria-hidden />
                  Releases-SOAK
                </div>
                {soakLoaded ? (
                  <>
                    <p className="font-mono text-sm">
                      {span1dCount}/{soakRows.length}{" "}
                      <span className="text-xs text-muted-foreground">com span≥1d</span>
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {maxHosts} {maxHosts === 1 ? "host" : "hosts"} · gate real (span gravado)
                    </p>
                  </>
                ) : (
                  <p className="text-xs text-muted-foreground">sem heartbeats de SOAK</p>
                )}
              </div>

              {/* Pilar 3 — Frescor de segurança (tier): net-new DIFERIDO, slot
                  honesto. Nunca um tier fabricado (cf. R15-12 doctor.sections=[]). */}
              <div className="space-y-1">
                <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                  <Lock className="h-3.5 w-3.5" aria-hidden />
                  Frescor de segurança
                </div>
                <Badge variant="warn">aguardando coleta</Badge>
                <p className="text-xs text-muted-foreground">
                  tier do <span className="font-mono">check-security-freshness</span> — próximo ciclo
                  do agentd
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Atenção-Agora */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <Bell className="h-4 w-4 text-[oklch(var(--brand))]" aria-hidden />
              <CardTitle>Atenção-Agora</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            {checks.fail + checks.warn > 0 ? (
              <p className="text-xs text-[oklch(var(--status-warning))]">
                {checks.fail} fail · {checks.warn} warn
              </p>
            ) : (
              <p className="text-xs text-muted-foreground">nada exige atenção</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
