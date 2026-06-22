// SOURCE: IdeiaOS v14.1 | kind: spa-page | targets: apps/cockpit
// =============================================================================
// Frota.tsx — tela de pilar (R14-05; spec "Frescor honesto"). Card por máquina +
// tabela densa de heartbeat + version-drift por IGUALDADE DE STRING (nunca
// comparação numérica de versão).
//
// Compõe:
//   - Um <MachineCard/> (reuso do substrato) por máquina.
//   - Uma TABELA DENSA de heartbeat: machine_id, canonical_name, os_version,
//     agentd_version, last_doctor, "último sinal há Xh" (frescor honesto).
//   - Painel de version-drift: por chave de `installed_versions`, drift = strings
//     DIFERENTES entre máquinas (===), NUNCA parse/ordenação numérica de versão.
//
// HONESTIDADE / INVARIANTES (spec + learnings):
//   - VERSION-DRIFT por IGUALDADE DE STRING: compara `installed_versions[key]`
//     entre máquinas por igualdade de string. NUNCA por valor numérico de versão —
//     `1.1.0` (redux) não "perde" para `1.36.0` (pré-redux) (learning
//     version-reset-migration-trap).
//   - Drift => Badge âmbar `--status-warning` + LABEL textual "drift" (cor nunca é
//     o único sinal — WCAG / color-is-never-the-sole-signal).
//   - Frescor honesto: remoto mostra "último sinal há Xh" de `last_seen_epoch`
//     (texto), nunca animação/fluxo simulado.
// =============================================================================
import { useEffect, useState } from "react";
import { Boxes, GitCompareArrows } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { MachineCard } from "@/components/MachineCard";

// Porta do read.js (env VITE_READ_PORT override; default 3073) — loopback (ADR v14).
const READ_PORT =
  (import.meta as { env?: Record<string, string> }).env?.VITE_READ_PORT ?? "3073";
const API_BASE = `http://127.0.0.1:${READ_PORT}`;

interface FleetMachine {
  machine_id: string;
  canonical_name: string | null;
  os_version: string | null;
  agentd_version: string | null;
  last_seen_epoch: number | null;
  last_doctor: string;
  daemons: { label: string; pid: number | null; status_code: number | null }[];
  // Objeto { [key]: version_string } — comparado por igualdade de string, nunca
  // por valor numérico de versão.
  installed_versions: Record<string, string>;
}

// "último sinal há Xh" — idade HONESTA e TEXTUAL de last_seen_epoch (nunca fluxo simulado).
function ageLabel(epoch: number | null): string {
  if (epoch == null) return "sem sinal";
  const secs = Math.floor(Date.now() / 1000) - epoch;
  if (secs < 0) return "agora";
  if (secs < 60) return `último sinal há ${secs}s`;
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `último sinal há ${mins}min`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `último sinal há ${hours}h`;
  const days = Math.floor(hours / 24);
  return `último sinal há ${days}d`;
}

// VERSION-DRIFT por IGUALDADE DE STRING: para uma chave, drift = >1 string DISTINTA
// entre as máquinas que a reportam. NUNCA parse / ordenação numérica de versão.
// `1.1.0` ≠ `1.36.0` é só "duas strings diferentes" — sem juízo de "mais novo".
function detectDrift(machines: FleetMachine[]): { key: string; values: string[] }[] {
  const keys = new Set<string>();
  for (const m of machines) {
    for (const k of Object.keys(m.installed_versions ?? {})) keys.add(k);
  }
  const drifts: { key: string; values: string[] }[] = [];
  for (const key of keys) {
    const distinct = new Set<string>();
    for (const m of machines) {
      const v = m.installed_versions?.[key];
      if (v != null && v !== "") distinct.add(v); // igualdade de string pura
    }
    // drift = mais de uma string distinta (===), independente de qual "parece" maior.
    if (distinct.size > 1) drifts.push({ key, values: [...distinct] });
  }
  return drifts;
}

export default function Frota() {
  const [machines, setMachines] = useState<FleetMachine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mesmo padrão useEffect/cancelled do App.tsx/Overview (loopback fetch canônico).
  useEffect(() => {
    let cancelled = false;
    async function fetchFleet() {
      try {
        const res = await fetch(`${API_BASE}/fleet`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = (await res.json()) as FleetMachine[];
        if (!cancelled) {
          setMachines(json);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e));
          setLoading(false);
        }
      }
    }
    fetchFleet();
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return <p className="text-sm text-muted-foreground">Carregando frota...</p>;
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-700/40 bg-red-900/20 p-4 text-sm text-red-400">
        Erro ao carregar /fleet: {error}
        <br />
        <span className="text-xs text-muted-foreground">
          Confirme o read.js rodando: <code>node apps/cockpit/server/read.js</code>
        </span>
      </div>
    );
  }

  if (machines.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-border p-8 text-center text-sm text-muted-foreground">
        Nenhuma máquina na federação ainda — aguardando o primeiro snapshot do
        agentd (ref <span className="font-mono">cockpit</span>).
      </div>
    );
  }

  const drifts = detectDrift(machines);

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Boxes className="h-5 w-5 text-[oklch(var(--brand))]" aria-hidden />
        <h2 className="text-base font-semibold tracking-tight">Frota</h2>
        <span className="text-xs text-muted-foreground">
          {machines.length === 1 ? "1 máquina" : `${machines.length} máquinas`}
        </span>
      </div>

      {/* ── Card por máquina (reuso MachineCard do substrato) ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {machines.map((m) => (
          <MachineCard
            key={m.machine_id}
            machine={{ machine_id: m.machine_id, last_doctor: m.last_doctor }}
          />
        ))}
      </div>

      {/* ── Version-drift por igualdade de string (nunca comparação numérica) ── */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center gap-2">
            <GitCompareArrows
              className="h-4 w-4 text-[oklch(var(--brand))]"
              aria-hidden
            />
            <CardTitle>Version-drift (igualdade de string)</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          {drifts.length === 0 ? (
            <p className="text-xs text-muted-foreground">
              Sem drift — todas as máquinas reportam as mesmas strings de versão.
            </p>
          ) : (
            <ul className="space-y-2">
              {drifts.map((d) => (
                <li key={d.key} className="flex flex-wrap items-center gap-2 text-xs">
                  <span className="font-mono text-foreground">{d.key}</span>
                  {/* Badge âmbar + LABEL textual "drift" — cor NUNCA é o único sinal */}
                  <Badge
                    variant="warn"
                    className="border-[oklch(var(--status-warning)/0.4)] bg-[oklch(var(--status-warning)/0.15)] text-[oklch(var(--status-warning))]"
                  >
                    drift
                  </Badge>
                  <span className="font-mono text-muted-foreground">
                    {d.values.join(" ≠ ")}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      {/* ── Tabela DENSA de heartbeat (frescor honesto: "último sinal há Xh") ── */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle>Heartbeat</CardTitle>
        </CardHeader>
        <CardContent className="overflow-x-auto px-0">
          <table className="w-full text-left text-xs">
            <thead className="text-muted-foreground">
              <tr className="border-b border-border">
                <th className="px-4 py-2 font-medium">machine_id</th>
                <th className="px-4 py-2 font-medium">nome</th>
                <th className="px-4 py-2 font-medium">os_version</th>
                <th className="px-4 py-2 font-medium">agentd_version</th>
                <th className="px-4 py-2 font-medium">doctor</th>
                <th className="px-4 py-2 font-medium">frescor</th>
              </tr>
            </thead>
            <tbody className="font-mono">
              {machines.map((m) => (
                <tr key={m.machine_id} className="border-b border-border/50">
                  <td className="px-4 py-2 text-[oklch(var(--brand))]">
                    {m.machine_id}
                  </td>
                  <td className="px-4 py-2">{m.canonical_name ?? "—"}</td>
                  <td className="px-4 py-2">{m.os_version ?? "—"}</td>
                  <td className="px-4 py-2">{m.agentd_version ?? "—"}</td>
                  <td className="px-4 py-2">
                    <Badge
                      variant={
                        m.last_doctor === "ok"
                          ? "ok"
                          : m.last_doctor === "warn"
                            ? "warn"
                            : m.last_doctor === "fail"
                              ? "fail"
                              : "default"
                      }
                    >
                      {m.last_doctor}
                    </Badge>
                  </td>
                  {/* Frescor HONESTO e TEXTUAL — nunca animação de fluxo contínuo */}
                  <td className="px-4 py-2 text-muted-foreground">
                    {ageLabel(m.last_seen_epoch)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}
