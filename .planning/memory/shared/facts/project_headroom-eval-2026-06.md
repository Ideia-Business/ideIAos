---
name: headroom-eval-2026-06
description: "Headroom (chopratejas/headroom, Apache-2.0) avaliado 2026-06-21 — veredito: NÃO adotar como proxy/MCP/dependência; minerar 3 padrões nativos. Compressão real mas condicional."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Avaliação sênior (empírica + workflow 62-agentes, verificação adversarial) do **headroom-ai 0.26.0** — camada local de compressão de contexto para agentes LLM (lib Py/TS, proxy HTTP, `wrap` CLI, MCP). Relatório completo: `/tmp/headroom-analysis/HEADROOM-ANALYSIS.md` (efêmero — recriar do repo se preciso).

**Veredito: NÃO adotar como proxy/`wrap`/MCP nem como dependência/delta.** Minerar PADRÕES, não a dep.

**Compressão é REAL mas CONDICIONAL** (medido por mim, tiktoken): logs **99,7%**, JSON tabular **58%**, JSON tool-output alta-cardinalidade **38%**, **código 0% no install base** (precisa extra `[code]`), **mensagem de usuário 0% por design** (`router:protected:user_message` — é por isso que "sem perda de contexto" vale). Default `compress()` só age em mensagens `tool`/proxy, não em prosa.

**Por que não adotar (por superfície):**
- Claude Code/Cursor (dev): só pluga via proxy (`ANTHROPIC_BASE_URL`→loopback). Numa **subscription** economiza ~$0 (ganho é só esticar rate-limit/1M ctx); colide com a LETRA do checklist `mcp-hygiene` (CVE-2026-21852 é sobre redirect REMOTO — aqui é 127.0.0.1, colisão de letra não de espírito); vira SPOF + latência + telemetria default-on. Já temos `/context-engineering`+`/cost-tracking`+compact.
- cfoai/nfideia: Lovable-hosted, saem por `ai.gateway.lovable.dev` / `openrouter.ai` — impossível injetar proxy.
- ideiapartner/lapidai: LLM roda em **Supabase Edge (Deno)**; headroom é Py/Rust e o SDK TS só comprime POSTando p/ um proxy rodando → exigiria infra hospedada nova no caminho de prod, justo onde DeepSeek-V já mira custo.

**Crédito (engenharia honesta):** harness de acurácia é end-to-end real; telemetria default-on MAS payload só numérico (sem prompt/código); `credential-isolation` PASSA (segredo transita processo, nunca o LLM ctx); `headroom learn` que edita CLAUDE.md é gated (`dry_run` default, só com `--apply`); CacheAligner foi DESLIGADO após quebrar cache; open-core fail-open. README mistura acurácia absoluta (GSM8K) com taxa de preservação (SQuAD/BFCL 97%); limitations admitem chat ≈4,8% e prosa net-negativa.

**Minerar p/ o IdeiaOS (CLI-First, sem dep):** (1) skill nativa de compressão de tool-output (JSON→schema+CSV; log→template) — maior ROI — **JÁ IMPLEMENTADO + SHIPPED 2026-06-21** (commit autosync `ddf6bca` em `work`): skill `source/skills/tool-output-compressor/` (`lib/toc_compress.py` stdlib + `lib/toc.sh` fail-open) + spec viva `specs/tool-output-compressor/spec.md` (7 reqs, via `/spec` propose→merge→archive) + `tests/tool-output-compressor-test.sh` (ALL PASS, log 97,8%) + README sync. REGISTRADO + DEPLOYADO + ROTEADO 2026-06-21 (janela autosync-pausada): commit `9f3d02a` (modules.json `skill-tool-output-compressor` + CORE_SKILLS em build-plugins.sh + plugin-membership 30→31 + plugin rebuildado; drift-guard OK) e `f50c022` (linha na matriz da Deia: "comprimir log/JSON gigante / reduzir tokens dessa saída" → `/tool-output-compressor`); copiada p/ `~/.claude/skills/`. NB: skill é INVOCADA sob-demanda (não auto-intercepta — rejeitamos o proxy); **opção (b) hook de auto-compressão por limiar = PARQUEADA por decisão do usuário (2026-06-21): NÃO-bloqueante, não tratar como gap/pendência ativa; reavaliar só se/quando o usuário pedir** (medir ganho real antes de automatizar); (2) padrão CCR (offload reversível + retrieve) p/ handoffs grandes, cf. [[context-packet-handoffs]]; (3) medição counterfactual com IC + holdout em `/cost-tracking`; (4) avaliar RTK/lean-ctx (MIT, CLI puro) isolados p/ o dev surface. Licença Apache-2.0 (não MIT) exige propagar NOTICE — `# SOURCE:` não basta. Pareia com [[project-deepseek-v4-enablement-pending]] e [[feedback-lovable-projects-branch-commit]].
