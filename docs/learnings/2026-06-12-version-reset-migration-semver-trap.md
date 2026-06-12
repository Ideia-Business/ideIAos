---
date: 2026-06-12
session_type: infra
incident: n/a (pin GSD revertido 3× em versions.lock, 2026-06-05 → 2026-06-11)
commit: 7a4f54b
tags: [semver, package-migration, lockfile, version-pinning, multi-machine]
applies_to_projects: [global]
promote_to_vault: true
---

# Migração de pacote com reset de versionamento inverte a semântica de semver — guardas devem ser package-aware

## Trigger (quando reler isso)

Qualquer componente pinado (lockfile, `versions.lock`, pin de plugin) cujo upstream migrou de
pacote/fork e o versionamento **recomeçou do zero** — ou drift de versão onde o valor "maior"
parece ser o mais novo mas a instalação real diz o contrário.

## O padrão (abstrato)

Quando um pacote migra para um novo nome/fork e o versionamento reseta (ex.: 1.36.0 → novo pacote
em 1.1.0), o número de versão **deixa de ser ordenável** entre as duas linhagens: o valor menor é
o mais novo. Toda comparação ingênua (humano, agente de IA, script com `sort -V` ou igualdade de
string) passa a "corrigir" na direção errada — restaurando o valor legado por parecer maior.
Cópias antigas do valor legado (working trees stale, máquinas não migradas, históricos de git)
viram vetores de reinfecção: qualquer processo que escreva "o que está instalado aqui" propaga o
legado de volta ao pin compartilhado.

## Evidência (concreta — desta sessão)

- Pin `gsd=` do `versions.lock` revertido 3× de `1.1.0` (redux, atual) para `1.36.0` (pré-redux,
  legado): commits `c7fc184` (autosync com árvore stale), `3724ee9` (agente Cursor "corrigindo"
  drift), além do caso da sessão 36 do nfideia.
- `scripts/update-upstream.sh:180` (versão antiga) — `--bump` gravava cegamente a versão instalada
  da máquina local, sem validar a linhagem do pacote.
- Correção: `scripts/check-versions-lock.sh` (guarda anti-legado 1.30–1.99 + anti-edição-manual no
  pre-commit), `--bump` recusa valor pré-redux, autosync exclui `versions.lock` do `git add -A`.

## Regra prática derivada

Ao pinar componente cujo upstream resetou versionamento: (1) **bloquear por faixa** os valores da
linhagem antiga em todo ponto de escrita do pin (pre-commit, script de bump, CI) — com nota de
obsolescência dizendo quando remover a guarda; (2) processos automáticos (cron, autosync) **nunca**
commitam o arquivo de pin — escritor sancionado único; (3) documentar a inversão no próprio
arquivo, na linha do pin, não em doc separada. Comparação de igualdade simples não basta: o
perigo não é "diferente", é "diferente na direção errada".

## Falsos positivos / armadilhas

- Drift legítimo "instalado mais novo que o pin" após update intencional — esse caso é resolvido
  com o bump sancionado, não é a armadilha.
- A guarda por faixa de versão tem prazo de validade: quando a nova linhagem alcançar a faixa
  bloqueada (anos), a guarda vira falso positivo — por isso a nota de obsolescência é obrigatória.

## Cross-references

- `[[2026-06-12-ambiguous-drift-warning-induces-agent-revert]]` — o outro modo de falha do mesmo incidente
- `[[learning-protocol-discipline-needs-hooks-not-guidelines]]` — barreira ativa > documentação passiva (princípio aplicado aqui)
- `scripts/check-versions-lock.sh` — implementação da guarda
- `STATE.md` (seção "RESOLVIDO 2026-06-12") — diagnóstico completo do incidente

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-12 — motivo: padrão se aplica a `[global]`
- [x] Promovido para Obsidian vault em 2026-06-12 — motivo: síntese cross-projeto (stack-agnóstico)
- [ ] Aplicado retroativamente em outros learnings (refinou regra)
