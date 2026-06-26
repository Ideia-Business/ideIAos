# v15 — Comando de tag PREPARADO (rodar quando o SOAK fechar)

**Status no momento da preparação (2026-06-26):** Onda 1+2+3 DONE (6/6 não-gated na Fase C);
`idea-doctor` 0 FAIL; **SOAK = 1/2 máquinas, span 0d** (heartbeat #1 do Mac-mini gravado).
**NÃO tagear ainda** — falta o heartbeat do MacBook + re-record após ≥1 dia.

---

## Passo 0 — pré-condição do SOAK (só prosseguir quando ESTE der exit 0)

```bash
cd ~/dev/IdeiaOS && git checkout work && git pull
bash scripts/check-soak.sh v15        # DEVE dar "SOAK satisfeito" / exit 0 (≥2 máquinas, span ≥1d)
```

Se ainda não passar, faltam heartbeats:
```bash
bash scripts/check-soak.sh v15 --status     # ver quantas máquinas / qual span
bash scripts/check-soak.sh v15 --record     # gravar/re-gravar nesta máquina (após ≥24h p/ o span)
```

## Passo 1 — os dois gates irmãos pré-tag (procedimento security-freshness.md)

```bash
bash scripts/check-soak.sh v15                        # durabilidade cross-máquina (exit 0)
bash scripts/check-security-freshness.sh --gate       # frescor de segurança (advisory no 1º ciclo — não bloqueia)
```

## Passo 2 — alinhamento final

```bash
git checkout work && git pull
git rev-parse work origin/main        # os dois SHAs devem ser IGUAIS antes de tagear
bash scripts/idea-doctor.sh           # confirmar FAIL: 0
```

## Passo 3 — criar a tag anotada v15.0 (@devops)

```bash
AIOX_ACTIVE_AGENT=devops git tag -a v15.0 -m "v15.0 — DX & Frota: instalação fácil + gerência da própria frota (single-operator, own-fleet)

Onda 1 (A) destravar & estancar · Onda 2 (B) governança visível + Cockpit rico ·
Onda 3 (C) write-path own-fleet + consolidação + prevenção.

Fase C (6/6 não-gated):
- R15-18 allowlist write-path LOCAL (reseal neutralizado + ledger wired ao /command)
- R15-19 idea update (comando único + redeploy-daemon canônico; in-place deprecados)
- R15-20 auto-cura visível (ledger de propagação + heartbeat no doctor §16)
- R15-21 gerador de hooks data-driven (lista única + gate de igualdade de SET)
- R15-22 pre-op guard anti-autosync-race (sentinela com stale-guard falha-segura)
- R15-23 proof-gate de re-pin local O2 (teardown own-fleet, ref fail-closed)

ESCOPO PARCIAL (como v10/v14): R15-17 — write-path CROSS-máquina (push_cmd_ref) +
cerimônia N=2 das ENC-KEYS — fica GATED por decisão do dono e NÃO entra nesta tag.

SOAK: >=2 maquinas reais, span >=1d, idea_doctor=PASS."
```

## Passo 4 — push da tag (@devops)

```bash
AIOX_ACTIVE_AGENT=devops git push origin v15.0
```

## Passo 5 — pós-tag (fechamento)

- README: a memória `feedback-readme-update-no-final` pede atualizar o README com os recursos novos
  da v15 ao final da implantação (já feito p/ `idea-update.sh`; revisar se algo da Onda 3 falta).
- Vault Changelog: já tem a entrada da Onda 3 (2026-06-26 noite/2).
- Housekeeping aberto: branch stale remota `sec/lovable-mcp-deny` em cfoai/nfideia (deletar quando autorizar).

---

**Lembrete do invariante:** `git tag`/`git push --tags` são operações **@devops** — prefixe com
`AIOX_ACTIVE_AGENT=devops` (o hook constitucional bloqueia por substring senão). IdeiaOS é repo
próprio (não-Lovable) → tag direto na origem é OK.
