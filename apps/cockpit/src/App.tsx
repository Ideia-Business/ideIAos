// SOURCE: IdeiaOS v14 | kind: spa-shell | targets: apps/cockpit
// Shell mínimo da Espinha — sem UI de valor ainda (plano 07, Wave 3).
// Estrutura Card/CardHeader/CardTitle/CardContent espelhada do nfideia
// (NotaGatewayHealthCard.tsx) — padrão shadcn confirmado em 14.0-PATTERNS.md.
// NÃO lê o read-model SQLite aqui; isso é o plano 07.
import { Activity } from "lucide-react";

export default function App() {
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
        {/* Scaffold placeholder — card de máquina vem no plano 07 (Wave 3) */}
        <div className="rounded-lg border border-border bg-card p-6 text-card-foreground shadow-sm">
          <div className="flex items-center gap-2 mb-2">
            <Activity className="h-4 w-4 text-[oklch(var(--brand))]" />
            <span className="text-sm font-medium">Espinha pronta</span>
            <span className="ml-auto inline-flex items-center rounded-full border border-[oklch(var(--brand)/0.4)] bg-[oklch(var(--brand)/0.15)] px-2.5 py-0.5 text-xs font-medium text-[oklch(var(--brand))]">
              scaffold
            </span>
          </div>
          <p className="text-sm text-muted-foreground">
            SPA do Cockpit servida em loopback 127.0.0.1:5273 sem login.
            Card de máquina (leitura do read-model SQLite) disponível no plano 07.
          </p>
        </div>
      </main>
    </div>
  );
}
