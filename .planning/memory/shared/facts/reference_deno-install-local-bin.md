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

Se o aviso reaparecer em OUTRA máquina do Gustavo, rodar o bloco acima — não re-investigar. Candidato a automação futura no `/ideiaos-setup` ou `idea-doctor` (detectar Deno ausente → instalar/avisar). Cross-link [[project-multi-os-install-architecture]].
