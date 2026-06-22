// SOURCE: IdeiaOS v14.1 | kind: spa-page | targets: apps/cockpit
// =============================================================================
// CofreEspelho.tsx — tela de pilar (R14-05; spec "Isolamento absoluto de
// credenciais / Zero-Leak"). Matriz var × project METADATA-ONLY.
//
// DOUTRINA (credential-isolation, materializada estruturalmente):
//   A representação de uma credencial contém APENAS referência — nome, presença,
//   idade, classe de risco, e se está commitada. JAMAIS o valor (nem parcial, nem
//   derivado do valor real). O endpoint /vault não tem coluna `value` (schema.sql
//   api_key — credential-isolation provada por estrutura, não por disciplina).
//
//   Esta tela é um ESPELHO de metadados: nenhum controle de UI lê/copia/escreve um
//   valor de segredo. Não há botão de inspeção de valor, não há campo mascarado a
//   partir de um valor real — porque o valor simplesmente não existe nesta camada.
//
// HONESTIDADE / WCAG:
//   - risk_tier `critical` => destaque com LABEL textual (Badge "critical"), nunca
//     só cor (color-is-never-the-sole-signal).
//   - Empty-state CELEBRADO: quando nada está faltando nem exposto, é estado BOM
//     ("cofre íntegro"), não um vazio triste.
// =============================================================================
import { useEffect, useMemo, useState } from "react";
import { KeyRound, ShieldCheck } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge, BadgeVariant } from "@/components/ui/badge";

// Porta do read.js (env VITE_READ_PORT override; default 3073) — loopback (ADR v14).
const READ_PORT =
  (import.meta as { env?: Record<string, string> }).env?.VITE_READ_PORT ?? "3073";
const API_BASE = `http://127.0.0.1:${READ_PORT}`;

// Linha do /vault — METADATA-ONLY. NOTE: nenhum campo de valor de credencial; o
// schema api_key não expõe a coluna correspondente (credential-isolation estrutural).
interface VaultRow {
  project_slug: string;
  var_name: string;
  present: number; // 0/1 — existe no arquivo .env?
  expected: number; // 0/1 — esperada (ex.: em .env.example)?
  risk_tier: "critical" | "sensitive" | "low" | "none";
  file_mtime_epoch: number | null;
  committed: number; // 0/1 — a chave aparece commitada (risco se present+committed)
}

// classe de risco => variante de Badge (cor) + o PRÓPRIO texto do tier (label).
function riskVariant(tier: VaultRow["risk_tier"]): BadgeVariant {
  switch (tier) {
    case "critical":
      return "fail";
    case "sensitive":
      return "warn";
    case "low":
      return "ok";
    default:
      return "default";
  }
}

// idade textual e HONESTA a partir do mtime do arquivo (nunca um valor de segredo).
function ageLabel(epoch: number | null): string {
  if (epoch == null) return "—";
  const secs = Math.floor(Date.now() / 1000) - epoch;
  if (secs < 0) return "agora";
  if (secs < 3600) return `${Math.floor(secs / 60)}min`;
  if (secs < 86400) return `${Math.floor(secs / 3600)}h`;
  return `${Math.floor(secs / 86400)}d`;
}

export default function CofreEspelho() {
  const [rows, setRows] = useState<VaultRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mesmo padrão useEffect/cancelled do App.tsx/Overview (loopback fetch canônico).
  useEffect(() => {
    let cancelled = false;
    async function fetchVault() {
      try {
        const res = await fetch(`${API_BASE}/vault`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = (await res.json()) as VaultRow[];
        if (!cancelled) {
          setRows(json);
          setLoading(false);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e));
          setLoading(false);
        }
      }
    }
    fetchVault();
    return () => {
      cancelled = true;
    };
  }, []);

  // "saúde" do cofre por metadata: faltando (expected & !present) ou exposta
  // (present & committed). Tudo derivado de metadata — nunca do valor.
  const { missing, exposed } = useMemo(() => {
    let missing = 0;
    let exposed = 0;
    for (const r of rows) {
      if (r.expected === 1 && r.present === 0) missing++;
      if (r.present === 1 && r.committed === 1) exposed++;
    }
    return { missing, exposed };
  }, [rows]);

  if (loading) {
    return <p className="text-sm text-muted-foreground">Carregando cofre...</p>;
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-700/40 bg-red-900/20 p-4 text-sm text-red-400">
        Erro ao carregar /vault: {error}
        <br />
        <span className="text-xs text-muted-foreground">
          Confirme o read.js rodando: <code>node apps/cockpit/server/read.js</code>
        </span>
      </div>
    );
  }

  const cofreIntegro = missing === 0 && exposed === 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <KeyRound className="h-5 w-5 text-[oklch(var(--brand))]" aria-hidden />
        <h2 className="text-base font-semibold tracking-tight">Cofre-Espelho</h2>
      </div>

      {/* ── Banner de DOUTRINA (credential-isolation) ── */}
      <div
        role="note"
        className="rounded-lg border border-[oklch(var(--brand)/0.4)] bg-[oklch(var(--brand)/0.08)] p-4 text-sm"
      >
        <div className="flex items-start gap-2">
          <ShieldCheck
            className="mt-0.5 h-4 w-4 shrink-0 text-[oklch(var(--brand))]"
            aria-hidden
          />
          <p className="text-muted-foreground">
            <span className="font-medium text-[oklch(var(--brand))]">
              Espelho de metadados.
            </span>{" "}
            O valor de um segredo jamais transita por aqui — só nome, presença, idade
            e classe de risco. A matriz é metadata-only por construção (a camada de
            dados não carrega o valor); esta é a doutrina de isolamento de credenciais.
          </p>
        </div>
      </div>

      {/* ── Empty-state CELEBRADO: cofre íntegro é estado BOM, não vazio triste ── */}
      {rows.length === 0 || cofreIntegro ? (
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-[oklch(var(--status-success))]" aria-hidden />
              <CardTitle>Cofre íntegro</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <Badge
              variant="ok"
              className="border-[oklch(var(--status-success)/0.4)] bg-[oklch(var(--status-success)/0.15)] text-[oklch(var(--status-success))]"
            >
              nada faltando, nada exposto
            </Badge>
            {rows.length > 0 && (
              <p className="mt-2 text-xs text-muted-foreground">
                {rows.length} referência(s) de credencial — todas presentes e nenhuma
                commitada. Nenhuma ação necessária.
              </p>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="flex flex-wrap gap-2 text-xs">
          {missing > 0 && (
            <Badge variant="warn">{missing} faltando</Badge>
          )}
          {exposed > 0 && (
            <Badge variant="fail">{exposed} commitada(s)</Badge>
          )}
        </div>
      )}

      {/* ── Matriz var × project METADATA-ONLY ── */}
      {rows.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle>Matriz var × project (metadata-only)</CardTitle>
          </CardHeader>
          <CardContent className="overflow-x-auto px-0">
            <table className="w-full text-left text-xs">
              <thead className="text-muted-foreground">
                <tr className="border-b border-border">
                  <th className="px-4 py-2 font-medium">project</th>
                  <th className="px-4 py-2 font-medium">var_name</th>
                  <th className="px-4 py-2 font-medium">presença</th>
                  <th className="px-4 py-2 font-medium">risco</th>
                  <th className="px-4 py-2 font-medium">idade</th>
                  <th className="px-4 py-2 font-medium">commitada</th>
                </tr>
              </thead>
              <tbody className="font-mono">
                {rows.map((r) => (
                  <tr
                    key={`${r.project_slug}:${r.var_name}`}
                    className="border-b border-border/50"
                  >
                    <td className="px-4 py-2">{r.project_slug}</td>
                    <td className="px-4 py-2 text-[oklch(var(--brand))]">
                      {r.var_name}
                    </td>
                    <td className="px-4 py-2">
                      {r.present === 1 ? (
                        <Badge variant="ok">presente</Badge>
                      ) : r.expected === 1 ? (
                        <Badge variant="warn">faltando</Badge>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="px-4 py-2">
                      {/* risk_tier critical => LABEL textual (o próprio tier), nunca só cor */}
                      <Badge variant={riskVariant(r.risk_tier)}>{r.risk_tier}</Badge>
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">
                      {ageLabel(r.file_mtime_epoch)}
                    </td>
                    <td className="px-4 py-2">
                      {r.committed === 1 ? (
                        <Badge variant="fail">sim</Badge>
                      ) : (
                        <span className="text-muted-foreground">não</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
