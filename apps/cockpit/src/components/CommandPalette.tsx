// SOURCE: IdeiaOS v14.1 | kind: spa-component | targets: apps/cockpit
// =============================================================================
// CommandPalette.tsx — Command Palette ⌘K (R14-05, plano 14.1-04).
//
// Overlay cmdk (portado do nfideia) com um ALLOWLIST FIXO de 6 verbos locais-e-
// reversíveis (B1–B6, doc 77 §B.1). Cada verbo faz POST /command ao read.js
// loopback (:3073) enviando o TOKEN EFÊMERO por-boot no header X-Cockpit-Token
// (FIX S-01) — o token é obtido same-origin via GET /command-token (gated por
// Origin+Host; uma aba cross-origin recebe 403 e NÃO lê o token). O resultado
// (exitCode/stdout já varrido pelo Zero-Leak) aparece INLINE.
//
// Armar-antes-de-disparar (B1/B3): a UI exige um 2º passo de confirmação antes
// de enviar confirmed:true (defesa-em-profundidade; o server JÁ exige — Open Q4).
//
// FOREVER-OUT (A8): nenhum verbo de mutação de produção, cross-máquina ou de
// autoridade @devops — essas operações no máximo GERARIAM o comando, nunca
// executam (agent-authority; ver doc 77 §B.2). O default-deny é server-side;
// aqui o allowlist é estrutural (array fechado de 6 verbos locais-reversíveis).
// =============================================================================
import { useState, useEffect, useCallback, useRef } from "react";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  PauseCircle,
  PlayCircle,
  ShieldCheck,
  RefreshCw,
  Power,
  Stethoscope,
  type LucideIcon,
} from "lucide-react";

// Porta do read.js (env VITE_READ_PORT override; default 3073) — mesmo padrão de App.tsx.
const READ_PORT =
  (import.meta as { env?: Record<string, string> }).env?.VITE_READ_PORT ?? "3073";
const API_BASE = `http://127.0.0.1:${READ_PORT}`;

// ── Allowlist FIXO de 6 verbos (B1–B6 — doc 77 §B.1). `arm:true` = destrutivo-
// mas-reversível (exige confirmação na UI antes de enviar confirmed:true). Os
// nomes de verbo casam EXATAMENTE o enum server-side (default-deny no read.js).
interface Verb {
  verb: string;
  label: string;
  icon: LucideIcon;
  arm: boolean;
  daemon?: string; // só B5
  keywords: string;
}

const VERBS: Verb[] = [
  { verb: "pause_autosync",  label: "Pausar autosync",      icon: PauseCircle, arm: true,  keywords: "autosync pausar parar sync" },          // B1
  { verb: "resume_autosync", label: "Retomar autosync",     icon: PlayCircle,  arm: false, keywords: "autosync retomar resume voltar sync" }, // B2
  { verb: "reseal_security", label: "Re-selar segurança",   icon: ShieldCheck, arm: true,  keywords: "segurança selo freshness security ledger" }, // B3
  { verb: "force_sync",      label: "Forçar sync agora",    icon: RefreshCw,   arm: false, keywords: "forçar sync agora kickstart autosync" }, // B4
  { verb: "kickstart_daemon",label: "Kickstart daemon cockpit", icon: Power,   arm: false, daemon: "cockpit", keywords: "daemon kickstart cockpit launchctl" }, // B5
  { verb: "run_doctor",      label: "Rodar idea-doctor",    icon: Stethoscope, arm: false, keywords: "doctor saúde diagnóstico health" },     // B6
];

interface CmdResult {
  verb: string;
  exitCode: number;
  stdout: string;
  zeroleak: string;
}

export function CommandPalette() {
  const [open, setOpen] = useState(false);
  const [armed, setArmed] = useState<string | null>(null); // verbo aguardando confirmação (armar-antes-de-disparar)
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<CmdResult | { error: string } | null>(null);
  const tokenRef = useRef<string | null>(null);

  // ── ⌘K (ou Ctrl+K) → toggle do overlay ──
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((prev) => !prev);
      }
    };
    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  // Reset do estado de armar/resultado ao fechar.
  useEffect(() => {
    if (!open) {
      setArmed(null);
      setResult(null);
    }
  }, [open]);

  // ── Obtém o token efêmero same-origin (cacheia por sessão; /command-token é
  // gated por Origin+Host — uma aba cross-origin recebe 403 e não lê o token).
  const getToken = useCallback(async (): Promise<string | null> => {
    if (tokenRef.current) return tokenRef.current;
    try {
      const r = await fetch(`${API_BASE}/command-token`);
      if (!r.ok) return null;
      const j = (await r.json()) as { token?: string };
      tokenRef.current = j.token ?? null;
      return tokenRef.current;
    } catch {
      return null;
    }
  }, []);

  // ── Dispara o verbo: POST /command com X-Cockpit-Token + Content-Type JSON.
  const fire = useCallback(
    async (v: Verb) => {
      setBusy(true);
      setResult(null);
      try {
        const token = await getToken();
        if (!token) {
          setResult({ error: "token efêmero indisponível (canal não autenticado)" });
          return;
        }
        const payload: Record<string, unknown> = { verb: v.verb };
        if (v.arm) payload.confirmed = true; // armado pela UI; o server também exige
        if (v.daemon) payload.daemon = v.daemon;
        const r = await fetch(`${API_BASE}/command`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Cockpit-Token": token,
          },
          body: JSON.stringify(payload),
        });
        const j = await r.json();
        setResult(j as CmdResult | { error: string });
      } catch (e) {
        setResult({ error: e instanceof Error ? e.message : "falha de rede" });
      } finally {
        setBusy(false);
        setArmed(null);
      }
    },
    [getToken],
  );

  // ── onSelect: B1/B3 (arm) exigem 2 passos (armar → confirmar); resto dispara direto.
  const onSelect = useCallback(
    (v: Verb) => {
      if (v.arm && armed !== v.verb) {
        setArmed(v.verb); // 1º passo: arma (não envia ainda)
        return;
      }
      void fire(v);
    },
    [armed, fire],
  );

  // Remove códigos de escape ANSI (cor de terminal) do stdout p/ render limpo no
  // <pre> — idea-doctor & co. emitem \x1b[..m; sem strip apareciam literais ([0;36m).
  // eslint-disable-next-line no-control-regex
  const stripAnsi = (s: string) => s.replace(/\x1b\[[0-9;]*m/g, "");

  return (
    <CommandDialog open={open} onOpenChange={setOpen}>
      <CommandInput placeholder="Comando local (autosync, segurança, doctor)…" />
      <CommandList>
        <CommandEmpty>Nenhum verbo no allowlist.</CommandEmpty>
        <CommandGroup heading="Comandos locais reversíveis (B1–B6)">
          {VERBS.map((v) => {
            const Icon = v.icon;
            const isArmed = armed === v.verb;
            return (
              <CommandItem
                key={v.verb}
                value={`${v.label} ${v.keywords}`}
                onSelect={() => onSelect(v)}
              >
                <Icon className="mr-2 h-4 w-4" aria-hidden />
                <span>{v.label}</span>
                {v.arm && (
                  <span className="ml-auto text-xs text-[oklch(var(--brand))]">
                    {isArmed ? "Confirmar?" : "armar antes de disparar"}
                  </span>
                )}
              </CommandItem>
            );
          })}
        </CommandGroup>
      </CommandList>

      {/* ── Resultado INLINE (exitCode/stdout já varrido pelo Zero-Leak) ── */}
      {(busy || result) && (
        <div className="border-t border-border px-3 py-2 text-xs">
          {busy && <span className="text-muted-foreground">executando…</span>}
          {!busy && result && "error" in result && (
            <span className="text-red-400">erro: {result.error}</span>
          )}
          {!busy && result && !("error" in result) && (
            <pre className="max-h-32 overflow-auto whitespace-pre-wrap">
              <span className={result.exitCode === 0 ? "text-emerald-400" : "text-red-400"}>
                {result.verb} → exit {result.exitCode} ({result.zeroleak})
              </span>
              {result.stdout ? "\n" + stripAnsi(result.stdout) : ""}
            </pre>
          )}
        </div>
      )}
    </CommandDialog>
  );
}

export default CommandPalette;
