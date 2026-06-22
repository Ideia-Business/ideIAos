// SOURCE: IdeiaOS v14 | kind: spa-shell | targets: apps/cockpit
// App.tsx — Espinha conecta substrato->UI.
// Plano 07 (Wave 3): lê o read-model SQLite via server local (read.js em 127.0.0.1:3073)
// e renderiza >=1 MachineCard com machine_id + last_doctor.
// Loopback 127.0.0.1, sem login — local-first por design (ADR v14).
import { useEffect, useState } from "react";
import { Activity } from "lucide-react";
import { MachineCard, MachineData } from "@/components/MachineCard";

// Porta do read.js server (env VITE_READ_PORT override; default 3073)
const READ_PORT = (import.meta as { env?: Record<string, string> }).env?.VITE_READ_PORT ?? "3073";
const API_BASE  = `http://127.0.0.1:${READ_PORT}`;

export default function App() {
  const [machines, setMachines]   = useState<MachineData[]>([]);
  const [loading, setLoading]     = useState(true);
  const [error, setError]         = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function fetchMachines() {
      try {
        const res  = await fetch(`${API_BASE}/machines`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = (await res.json()) as MachineData[];
        if (!cancelled) {
          setMachines(data);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e));
          setLoading(false);
        }
      }
    }
    fetchMachines();
    return () => { cancelled = true; };
  }, []);

  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Header */}
      <header className="border-b border-border px-6 py-4">
        <div className="flex items-center gap-3">
          <Activity className="h-5 w-5 text-[oklch(var(--brand))]" />
          <h1 className="text-lg font-semibold tracking-tight">
            IdeiaOS Cockpit
          </h1>
          <span className="ml-auto text-xs text-muted-foreground">
            v14.0 · local-first
          </span>
        </div>
      </header>

      {/* Main */}
      <main className="container mx-auto px-6 py-8">
        {loading && (
          <p className="text-sm text-muted-foreground">
            Carregando máquinas...
          </p>
        )}

        {error && (
          <div className="rounded-lg border border-red-700/40 bg-red-900/20 p-4 text-sm text-red-400">
            Erro ao carregar read-model: {error}
            <br />
            <span className="text-xs text-muted-foreground">
              Certifique-se que read.js está rodando:{" "}
              <code>node apps/cockpit/server/read.js</code>
            </span>
          </div>
        )}

        {!loading && !error && machines.length === 0 && (
          <p className="text-sm text-muted-foreground">
            Nenhuma máquina no read-model. Rode:{" "}
            <code className="text-xs">node source/console/ingest.js</code>
          </p>
        )}

        {/* Grid de MachineCards — >=1 card com machine_id e last_doctor */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {machines.map((m) => (
            <MachineCard key={m.machine_id} machine={m} />
          ))}
        </div>
      </main>
    </div>
  );
}
