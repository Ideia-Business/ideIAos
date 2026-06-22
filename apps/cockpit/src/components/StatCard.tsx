// SOURCE: IdeiaOS v14.1 | kind: spa-component | targets: apps/cockpit
// =============================================================================
// StatCard.tsx — tile de métrica do bento grid (MÁQUINAS / PROJETOS / CHECKS OK).
//
// Forma title/value/subtitle/icon adaptada do nfideia KPICard.tsx — mas SEM
// framer-motion (zero-motion por design; o cockpit prefere CSS nativo +
// prefers-reduced-motion, não uma dep de animação). Estilo black-gold OKLCH,
// reusa o primitivo Card/shadcn já no scaffold.
//
// WCAG (A10): o ícone e o texto (title/subtitle) carregam o sinal; a cor de
// `accent` é REFORÇO, nunca o único indicador.
// =============================================================================
import type { LucideIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

export type StatAccent = "neutral" | "success" | "warning";

const accentText: Record<StatAccent, string> = {
  // Ouro != estado (50-ux): neutro usa a marca só como hierarquia, não "tudo certo".
  neutral: "text-[oklch(var(--brand))]",
  success: "text-[oklch(var(--status-success))]",
  warning: "text-[oklch(var(--status-warning))]",
};

export interface StatCardProps {
  /** Rótulo curto, ex.: "MÁQUINAS". */
  title: string;
  /** Valor principal — número ou "n/a" (nunca uma nota fabricada). */
  value: string | number;
  /** Linha de apoio opcional (ex.: "checks ok / total"). */
  subtitle?: string;
  /** Ícone lucide (segundo sinal além da cor — WCAG). */
  icon: LucideIcon;
  /** Realce de cor; default neutro. NUNCA o único sinal de estado. */
  accent?: StatAccent;
}

export function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  accent = "neutral",
}: StatCardProps) {
  return (
    <Card className="w-full">
      <CardContent className="flex items-center gap-4 p-5">
        <Icon className={`h-6 w-6 shrink-0 ${accentText[accent]}`} aria-hidden />
        <div className="min-w-0">
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {title}
          </p>
          <p className={`font-mono text-2xl font-semibold ${accentText[accent]}`}>
            {value}
          </p>
          {subtitle && (
            <p className="mt-0.5 truncate text-xs text-muted-foreground">{subtitle}</p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export default StatCard;
