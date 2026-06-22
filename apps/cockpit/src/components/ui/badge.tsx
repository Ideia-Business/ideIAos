// SOURCE: IdeiaOS v14 | kind: ui-component | targets: apps/cockpit
// Badge primitivo — estrutura shadcn/ui, tema black-gold OKLCH do cockpit.
import * as React from "react";

function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(" ");
}

type BadgeVariant = "default" | "ok" | "warn" | "fail";

const variantClass: Record<BadgeVariant, string> = {
  default:
    "border-[oklch(var(--brand)/0.4)] bg-[oklch(var(--brand)/0.15)] text-[oklch(var(--brand))]",
  ok: "border-green-700/40 bg-green-900/30 text-green-400",
  warn: "border-yellow-700/40 bg-yellow-900/30 text-yellow-400",
  fail: "border-red-700/40 bg-red-900/30 text-red-400",
};

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
}

const Badge = React.forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant = "default", ...props }, ref) => (
    <span
      ref={ref}
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
        variantClass[variant],
        className
      )}
      {...props}
    />
  )
);
Badge.displayName = "Badge";

export { Badge };
export type { BadgeVariant };
