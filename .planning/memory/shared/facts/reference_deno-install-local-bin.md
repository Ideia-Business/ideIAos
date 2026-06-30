---
name: reference-deno-install-local-bin
description: "Deno instalado em ~/.local/bin (v2.9.0) — o aviso \"Deno não está instalado\" era o fallback de `deno test` em edge functions; método replicável cross-máquina"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

O aviso recorrente "**Deno não está instalado nesta máquina**" NÃO vinha de hook do IdeiaOS — era o **fallback de verificação estática** disparado quando uma IA tenta rodar `deno test` em edge functions (Supabase/Lovable rodam em Deno) e o binário está ausente. Causa raiz = Deno ausente do PATH.

**Resolvido em 2026-06-30** (MacBook-Air-2, arm64, macOS 26.5) instalando o binário oficial em `~/.local/bin/deno` — diretório que **já está no PATH** de todas as máquinas do Gustavo, então funciona em todo shell/projeto novo sem editar `.bashrc`/`.zprofile`.

**Método replicável (cross-máquina, CLI-First, evita `curl | sh`):**

```bash
ARCH=$(uname -m); case "$ARCH" in arm64) A=aarch64;; x86_64) A=x86_64;; esac
V=$(curl -fsSL https://dl.deno.land/release-latest.txt)   # ex: v2.9.0
curl -fL "https://dl.deno.land/release/$V/deno-$A-apple-darwin.zip" -o /tmp/deno.zip
unzip -o /tmp/deno.zip -d /tmp && mv -f /tmp/deno ~/.local/bin/deno && chmod +x ~/.local/bin/deno
# Gatekeeper: se baixado via browser, `xattr -d com.apple.quarantine ~/.local/bin/deno`
deno --version   # verificação binária (exit 0)
```

**Verificação:** `deno --version`, `deno eval`, e `deno test` todos exit-code 0; resolve via PATH em login shell novo (`bash -lc 'command -v deno'`). Sem Homebrew na máquina (não era necessário).

**Automação AGORA durável para TODA a frota (2026-06-30, "de vez"):** o instalador `scripts/install-deno.sh` (idempotente, checksum, portável arm/x86×macOS/Linux) NÃO estava órfão — já rodava no **bootstrap `setup-dev-machine.sh §3.5`** (one-time, máquina nova do zero). O gap era o **refresh recorrente**: `setup.sh --global-only` (rodado pelo `sync-all.sh` e pelo branch global da propagação `propagate-if-changed.sh:226`) NÃO instalava o Deno → máquinas JÁ EXISTENTES ficavam sem. Fix: cabeado no `setup.sh` **step 6.3 (fase global)** → o refresh recorrente passa a instalar também, cobrindo a frota inteira (nova via bootstrap §3.5, existente via propagação/sync-all). Fail-soft (Deno é runtime opcional; falha de rede não aborta o setup). Não toquei `install-global-patches.sh` (evitei renumerar 15 patches) porque a propagação já passa pelo `setup.sh --global-only` antes dele. **Furo de propagação que precisei fechar junto:** `setup.sh` estava só em `PROJECT_PATHS` → mudança na fase global dele acionava só `--project-only` (que pula o step 6.3); o branch global (`--global-only`) só dispara quando um `GLOBAL_PATH` muda, e a fase global do setup vive NO arquivo, não em `source/`. Adicionei `setup.sh` a `GLOBAL_PATHS` também → propagação do step 6.3 à frota agora é determinística, não "carona" de outro global-path no mesmo range. **Lição geral:** lógica de fase-global que vive DENTRO do orquestrador (não em `source/`) precisa que o próprio arquivo esteja no gatilho de propagação global — senão muda local mas não propaga.

Se o aviso reaparecer numa máquina, é porque ela ainda não rodou um ciclo de sync/setup pós-2026-06-30 — rodar `bash scripts/install-deno.sh` (ou `setup.sh --global-only`) resolve; não re-investigar. Cross-link [[project-multi-os-install-architecture]].
