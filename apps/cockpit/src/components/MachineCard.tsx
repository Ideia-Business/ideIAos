// SOURCE: IdeiaOS v14 | kind: component | targets: apps/cockpit
// MachineCard — health-card de máquina lendo o read-model (machine_id, last_doctor).
// Estrutura: Card/CardHeader/CardTitle/CardContent + Badge de status + ícone lucide.
// Padrão do nfideia (NotaGatewayHealthCard.tsx): Card/CardHeader/CardTitle/CardContent
//   + Badge + Activity/CheckCircle2/XCircle (lucide-react).
// Espinha conecta substrato->UI: recebe dados via props (fetch em App.tsx).
import { Activity, CheckCircle2, XCircle, AlertTriangle } from "lucide-react";
import { Badge, BadgeVariant } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export interface MachineData {
  machine_id: string;
  last_doctor: string; // "ok" | "warn" | "fail" | "unknown"
}

function doctorVariant(status: string): BadgeVariant {
  switch (status) {
    case "ok":
      return "ok";
    case "warn":
      return "warn";
    case "fail":
      return "fail";
    default:
      return "default";
  }
}

function DoctorIcon({ status }: { status: string }) {
  switch (status) {
    case "ok":
      return <CheckCircle2 className="h-4 w-4 text-green-400" />;
    case "warn":
      return <AlertTriangle className="h-4 w-4 text-yellow-400" />;
    case "fail":
      return <XCircle className="h-4 w-4 text-red-400" />;
    default:
      return <Activity className="h-4 w-4 text-[oklch(var(--brand))]" />;
  }
}

interface MachineCardProps {
  machine: MachineData;
}

export function MachineCard({ machine }: MachineCardProps) {
  const { machine_id, last_doctor } = machine;
  const variant = doctorVariant(last_doctor);

  return (
    <Card className="w-full max-w-sm">
      <CardHeader className="pb-2">
        <div className="flex items-center gap-2">
          <DoctorIcon status={last_doctor} />
          <CardTitle className="font-mono text-[oklch(var(--brand))]">
            {machine_id}
          </CardTitle>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground">doctor:</span>
          <Badge variant={variant}>{last_doctor}</Badge>
        </div>
      </CardContent>
    </Card>
  );
}
