---
date: 2026-06-26
session_type: bug-fix
incident: n/a
commit: 9d9e129
tags: [daemon, launchd, cwd, path-resolution, partial-fix, verification]
applies_to_projects: [global]
promote_to_vault: true
---

# Fix de dependência-de-cwd num daemon: corrigir UM ponto não basta — varra o arquivo inteiro

> O comentário que justifica o fix de um ponto É a pista de que existem outros pontos com o mesmo bug.

## Trigger (quando reler isso)

Quando um processo que roda como daemon (launchd / systemd / cron / serviço) falha ou degrada
porque o **cwd não é o diretório do projeto**, e você encontra UM ponto já corrigido (ancorado em
`__dirname`/`__file__`) mas o sintoma persiste.

## O padrão (abstrato)

Um daemon não herda o cwd interativo do desenvolvedor — roda com cwd = `/` ou home. Todo acesso a
recurso por **path relativo** ou `process.cwd()`/`os.getcwd()` quebra silenciosamente nesse regime.
Quando alguém corrige UM desses pontos, costuma deixar **um comentário** explicando o porquê
("ancorado em X porque sob o daemon o cwd não é o repo"). Esse comentário é simultaneamente a
correção de um ponto **e a evidência de que o arquivo inteiro tem a mesma classe de bug** — mas o
autor original raramente varre os demais pontos. O fix fica parcial: o ponto comentado funciona, os
irmãos silenciosos continuam quebrados até alguém rodar o daemon de verdade.

A regra: ao tocar qualquer cwd-dependência num código que roda como daemon, **trate como defeito de
arquivo, não de linha** — extraia uma constante de raiz `__dirname`-based e aplique a TODOS os
`cwd()`/paths-relativos do arquivo de uma vez.

## Evidência (concreta — desta sessão)

- Commit principal: `9d9e129` (IdeiaOS, `source/agentd/collect.js`)
- Arquivos-chave:
  - `source/agentd/collect.js:292` (pré-fix) — só o `versions.lock` fora ancorado em `__dirname`
    (R15-12), com comentário condenando "depender de cwd num daemon".
  - `source/agentd/collect.js:58` — `path.join(process.cwd(), '.planning','soak')` **ainda** dependia
    de cwd (irmão silencioso #1).
  - `source/agentd/collect.js:149` — `bash scripts/check-security-freshness.sh` (path relativo) →
    `safeExec warn` no stderr do daemon + `security_freshness` ausente do snapshot (irmão #2).
  - Fix: constante `const ROOT = path.resolve(__dirname,'..','..')` no topo, aplicada aos 3 pontos;
    a chamada ao script passou a path absoluto + `{ cwd: ROOT }`.
- Prova: rodar `agentd.js --once` e `ingest.js` de `cwd=/tmp` (simula launchd) → sem warn + `tier: ok`;
  depois `launchctl kickstart` do daemon real com err-log truncado → run fresco sem warn.

## Regra prática derivada

1. Ao corrigir cwd/path-relativo num código que roda como daemon, **grep o arquivo inteiro** por
   `process.cwd()`/`getcwd()`/paths relativos e ancore TODOS numa constante raiz `__dirname`-based.
2. Para subprocessos (exec de script), use **path absoluto E** passe `cwd` explícito — o script-filho
   pode ter a própria dependência de cwd (ex: `git diff`).
3. **Verifique no regime real do daemon**, não só interativo: rodar de `cwd=/tmp` simula; um
   `launchctl kickstart`/`systemctl start` prova. "Funciona quando eu rodo do repo" não vale.

## Falsos positivos / armadilhas

- **Warn em log de daemon pode ser resíduo, não bug vivo.** Logs de daemon são *append*; a última
  linha pode ser de um run **pré-fix**. Não conclua "ainda quebrado" pela última linha — **trunque o
  log, force um run fresco (kickstart) e observe o run novo**. Confirme também que o warn aparece só
  1× (resíduo) vs N× (recorrente).
- Nem todo `process.cwd()` é bug: se o programa SÓ roda interativamente (CLI invocada pelo dev),
  cwd-relativo é correto e intencional. O padrão vale para o **regime daemon**.

## Cross-references

- `[[project-cockpit-daemon-nvm-install-and-cwd]]` — o gotcha de domínio IdeiaOS desta mesma sessão
  (plist do cockpit hardcoda `/usr/local/bin/node`; máquina nvm exige symlink `~/.local/bin/node`).
- `[[autosync-durability-hardening]]` — mesmo eixo "launchd não herda PATH (gotcha nvm)".
- Memória global: `learning_daemon-cwd-fix-needs-whole-file-sweep.md`

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-26 — motivo: padrão `[global]`, stack-agnóstico
- [x] Promovido para Obsidian vault em 2026-06-26 — motivo: síntese cross-projeto
- [ ] Aplicado retroativamente em outros learnings (refinou regra)
