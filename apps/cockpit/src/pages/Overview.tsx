// SOURCE: IdeiaOS v14.1 | kind: spa-page | targets: apps/cockpit
// =============================================================================
// Overview.tsx — a primeira tela de valor (R14-05; spec). Bento grid + banda
// Flight Recorder.
//
// Compõe:
//   - System Pulse hero (heartbeat LOCAL-vivo; remoto = idade honesta).
//   - StatCards: MÁQUINAS / PROJETOS / CHECKS OK (de GET /overview).
//   - Card Frota (resumo), card Segurança, card Releases-SOAK LEAN, card Atenção-Agora.
//   - Banda Flight Recorder (<FlightRecorder/> de 14.1-05).
//
// HONESTIDADE (spec):
//   - Releases-SOAK é LEAN: "PRONTO PARA TAG" + `v## n/2 ✓ span x/1d`, sem o
//     relógio decorativo (doc 71 — cede o slot ao Flight Recorder).
//   - Saúde-por-produto onde idea-doctor não roda (Lovable) => `n/a`, nunca nota
//     fabricada. checks.unknown NÃO conta como falha.
//   - Monousuário (sem 2º nó) => "aguardando segundo ator", nunca card-fantasma.
// =============================================================================
import { useEffect, useState } from "react";
import {
  Server,
  FolderGit2,
  ShieldCheck,
  Boxes,
  Tag,
  Bell,
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

export interface OverviewProps {
  /** Base loopback do read.js (http://127.0.0.1:3073). */
  apiBase: string;
}

export default function Overview({ apiBase }: OverviewProps) {
  const [data, setData] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mesmo padrão useEffect/cancelled do App.tsx (loopback fetch canônico).
  useEffect(() => {
    let cancelled = false;
    async function fetchOverview() {
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
    }
    fetchOverview();
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

  // SOAK lean (honesto): precisa de ≥2 máquinas para haver "segundo ator". Sem
  // isso, não há tag possível e o card diz a verdade — nunca um relógio fake.
  const soakReady = machines >= 2;

  // Saúde-por-produto honesta: `unknown` (idea-doctor n/a, ex.: Lovable) é
  // renderizado como n/a, jamais somado como falha.
  const naCount = checks.unknown;

  return (
    <div className="space-y-6">
      {/* ── Hero: System Pulse (local-vivo; remoto idade honesta) ── */}
      <SystemPulse apiBase={apiBase} />

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

        {/* Segurança */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-[oklch(var(--brand))]" aria-hidden />
              <CardTitle>Segurança</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-1">
            <div className="flex items-center gap-2">
              <Badge variant={checks.fail > 0 ? "fail" : checks.warn > 0 ? "warn" : "ok"}>
                {checks.fail > 0 ? "fail" : checks.warn > 0 ? "warn" : "ok"}
              </Badge>
              <span className="text-xs text-muted-foreground">doctor agregado</span>
            </div>
            {naCount > 0 && (
              <p className="text-xs text-muted-foreground">
                {naCount} produto(s) <span className="font-mono">n/a</span>
              </p>
            )}
          </CardContent>
        </Card>

        {/* Releases-SOAK — LEAN: sem o relógio decorativo (doc 71) */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <Tag className="h-4 w-4 text-[oklch(var(--brand))]" aria-hidden />
              <CardTitle>Releases-SOAK</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-1">
            {soakReady ? (
              <>
                <Badge variant="ok">PRONTO PARA TAG</Badge>
                {/* forma lean: v## n/2 ✓ span x/1d — só o estado, sem relógio */}
                <p className="font-mono text-xs text-muted-foreground">
                  {machines}/2 ✓ · span —/1d
                </p>
              </>
            ) : (
              <>
                <Badge variant="warn">aguardando segundo ator</Badge>
                <p className="text-xs text-muted-foreground">
                  SOAK exige ≥2 máquinas + span ≥1d
                </p>
              </>
            )}
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

      {/* ── Banda Flight Recorder (de 14.1-05) ── */}
      <FlightRecorder />
    </div>
  );
}
