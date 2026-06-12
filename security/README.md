# security/ — Pipeline de Quarentena IdeiaOS

**Decisão travada (PROJECT.md):** NENHUM conteúdo de terceiros (skills, agents, rules do ECC ou qualquer fonte externa) é absorvido em `source/` sem passar por `scan-absorbed.sh`.

Contexto: estudo ToxicSkills (Snyk, fev/2026) detectou prompt injection em 36% de 3.984 skills públicas. CVE-2025-59536 e CVE-2026-21852 mostram que config de projeto é superfície de ataque.

---

## Fluxo obrigatório de absorção

```
1. Copiar conteúdo de terceiros → security/quarantine/
2. bash security/scan-absorbed.sh security/quarantine/
3. Se exit 0 → promover para source/
   Se exit 1 → BLOQUEADO (revisar findings, não absorver)
   Se exit 2 → erro de invocação (target não existe)
```

## Exit codes

| Código | Significado | Ação |
|--------|-------------|------|
| 0 | PASS (limpo ou só WARNs) | Pode promover para `source/` — revisar WARNs antes |
| 1 | FAIL (unicode invisível ou payload ativo) | **Não absorver.** Inspecionar e descartar ou sanitizar |
| 2 | Erro de invocação | Target não existe — verificar caminho |

## WARN vs FAIL

- **FAIL** (exit 1): unicode invisível (U+200B/202A-E/FEFF etc.) ou payloads HTML/JS/base64 — bloqueio automático.
- **WARN** (exit 0): comandos suspeitos (curl, wget, ssh, nc etc.) ou AgentShield offline — exigem inspeção manual antes de promover, mas não bloqueiam automaticamente pois aparecem em docs legítimas.

## Checks executados

| # | Check | Tecnologia | Resultado se encontrado |
|---|-------|------------|------------------------|
| 1 | Unicode invisível (U+200B, U+202A-E, FEFF, etc.) | Python3 | FAIL |
| 2 | Payloads HTML/JS inline (`<!--`, `data:text/html`, `base64,`) | Python3 | FAIL |
| 3 | Comandos suspeitos (`curl`, `wget`, `ssh`, `nc`, `scp`, `ANTHROPIC_BASE_URL`) | Python3 | WARN |
| 4 | AgentShield scan (github.com/affaan-m/agentshield) | npx ecc-agentshield | WARN se offline |

## Nota sobre AgentShield

Na primeira execução, `npx --yes ecc-agentshield` faz download do pacote (10-30s). Execuções offline resultam em WARN (scan parcial), nunca bloqueiam o fluxo.

## Diretório quarantine/

`security/quarantine/` é a staging area versionada. Coloque aqui o conteúdo de terceiros antes de rodar o scan. Arquivos aprovados devem ser movidos para `source/` manualmente — nunca auto-promovidos.

## Verificação do ambiente

```bash
bash scripts/idea-doctor.sh   # Seção 7d checa presença deste script
```
