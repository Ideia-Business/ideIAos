// SOURCE: IdeiaOS v14.1 | kind: spa-shell | targets: apps/cockpit
// =============================================================================
// App.tsx — SHELL de navegação das 3 telas + o SEAM de integração da Wave 3.
//
// O SEAM (este plano, 14.1-02):
//   App.tsx registra AS TRÊS rotas (Overview/Frota/Cofre) por ESTADO LOCAL — sem
//   router lib, sem dep nova — e monta UMA VEZ o ponto-de-montagem ESTÁVEL do
//   ⌘K (<CommandPalette/>) fora do switch de tela. Os planos 14.1-03 (Frota/Cofre)
//   e 14.1-04 (⌘K) PREENCHEM os corpos de pages/Frota.tsx, pages/CofreEspelho.tsx
//   e components/CommandPalette.tsx — SEM editar este App.tsx (evita colisão de
//   file-ownership na mesma wave).
//
// Local-first: API_BASE em loopback 127.0.0.1, sem login (ADR v14).
// =============================================================================
import { useState } from "react";
import {
  Activity,
  LayoutDashboard,
  Boxes,
  KeyRound,
  type LucideIcon,
} from "lucide-react";
import Overview from "@/pages/Overview";
import Frota from "@/pages/Frota";
import CofreEspelho from "@/pages/CofreEspelho";
import { CommandPalette } from "@/components/CommandPalette";

// Porta do read.js server (env VITE_READ_PORT override; default 3073)
const READ_PORT =
  (import.meta as { env?: Record<string, string> }).env?.VITE_READ_PORT ?? "3073";
const API_BASE = `http://127.0.0.1:${READ_PORT}`;

// As TRÊS rotas registradas agora (Overview montada; Frota/Cofre = stubs de 14.1-03).
type Screen = "overview" | "frota" | "cofre";

interface NavItem {
  id: Screen;
  label: string;
  icon: LucideIcon;
}

const NAV: NavItem[] = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "frota", label: "Frota", icon: Boxes },
  { id: "cofre", label: "Cofre", icon: KeyRound },
];

export default function App() {
  // Nav por ESTADO LOCAL (sem router lib / sem dep nova).
  const [screen, setScreen] = useState<Screen>("overview");

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      {/* ── Sidebar thin: ícones + barra ativa ouro 2px (50-ux §sidebar) ── */}
      <nav
        className="flex w-16 flex-col items-center gap-1 border-r border-border py-4"
        aria-label="Navegação principal"
      >
        <Activity
          className="mb-4 h-6 w-6 text-[oklch(var(--brand))]"
          aria-label="IdeiaOS Cockpit"
        />
        {NAV.map((item) => {
          const Icon = item.icon;
          const active = screen === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => setScreen(item.id)}
              aria-current={active ? "page" : undefined}
              title={item.label}
              className={[
                "relative flex h-11 w-11 items-center justify-center rounded-md transition-colors",
                active
                  ? "text-[oklch(var(--brand))]"
                  : "text-muted-foreground hover:text-foreground",
              ].join(" ")}
            >
              {/* barra ativa ouro 2px à esquerda (frame/seleção — não estado) */}
              {active && (
                <span
                  className="absolute left-0 top-1/2 h-6 w-0.5 -translate-y-1/2 rounded-full bg-[oklch(var(--brand))]"
                  aria-hidden
                />
              )}
              <Icon className="h-5 w-5" aria-hidden />
              <span className="sr-only">{item.label}</span>
            </button>
          );
        })}
      </nav>

      <div className="flex min-w-0 flex-1 flex-col">
        {/* ── Header black-gold (preservado do scaffold) ── */}
        <header className="border-b border-border px-6 py-4">
          <div className="flex items-center gap-3">
            <h1 className="text-lg font-semibold tracking-tight">IdeiaOS Cockpit</h1>
            <span className="ml-auto text-xs text-muted-foreground">
              v14.1 · local-first · ⌘K
            </span>
          </div>
        </header>

        {/* ── Main: switch de tela (as 3 rotas registradas) ── */}
        <main className="container mx-auto flex-1 px-6 py-8">
          {screen === "overview" && <Overview apiBase={API_BASE} />}
          {screen === "frota" && <Frota />}
          {screen === "cofre" && <CofreEspelho />}
        </main>
      </div>

      {/* ── SEAM ⌘K: ponto-de-montagem ESTÁVEL (preenchido por 14.1-04) ── */}
      <CommandPalette />
    </div>
  );
}
