# SOURCE: IdeiaOS v2
# Observations Layout — ~/.ideiaos/observations/

Layout de armazenamento das observações capturadas pelos hooks de Aprendizado Contínuo (Phase 05).

---

## Árvore de diretórios

```
~/.ideiaos/
└── observations/
    └── <projeto-slug>/
        └── observations.jsonl     # append-only, 1 evento por linha
```

- `<projeto-slug>`: basename do `cwd` da sessão, normalizado para `[a-z0-9-]`, máx 40 chars.
  Exemplo: `/Users/dev/IdeiaOS` → `ideiaos`.
- `observations.jsonl`: arquivo JSONL (uma linha JSON por evento). Criado sob demanda pelo primeiro evento da sessão.
- `~/.ideiaos/` **não é versionado em git** de projeto — é estado local da máquina, sincronizado via autosync/iCloud se configurado.

---

## Schema de uma linha de observação

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `ts` | string (ISO 8601) | Timestamp do evento, precisão de segundos |
| `session_id` | string (≤64 chars) | ID da sessão Claude Code |
| `project` | string | Slug do projeto derivado do cwd |
| `tool` | string | Nome da tool (Edit, Write, Bash, etc.) ou `"session_end"` |
| `file` | string | Path do arquivo modificado, **relativo ao cwd** (sem conteúdo) |
| `ext` | string | Extensão do arquivo sem ponto (ex: `"ts"`, `"py"`) |
| `bash_verb` | string | **Apenas o 1º token** do comando Bash (ex: `"npm"`, `"git"`). Vazio para outras tools. |
| `ok` | boolean | Heurística de sucesso/erro (defensivo — baseado em `tool_response`) |

**Marcador especial de fim de sessão** (gerado por `observe-session-end.sh`):

```json
{"ts": "...", "session_id": "...", "project": "...", "tool": "session_end", "event": "session_end"}
```

### Exemplo de linha de evento Edit

```json
{"ts": "2026-06-12T02:40:00", "session_id": "abc123", "project": "ideiaos", "tool": "Edit", "file": "source/hooks/observe-tool-use.sh", "ext": "sh", "bash_verb": "", "ok": true}
```

### Exemplo de linha de evento Bash

```json
{"ts": "2026-06-12T02:40:01", "session_id": "abc123", "project": "ideiaos", "tool": "Bash", "file": "", "ext": "", "bash_verb": "npm", "ok": true}
```

---

## Privacidade — O que NUNCA entra na jsonl

Conforme `docs/security/memory-hygiene.md` Regra 1, os hooks **nunca** registram:

- Conteúdo de arquivos (parâmetro `content` do tool_input)
- Diffs ou patches
- Comando Bash completo (só o 1º token — `bash_verb`)
- Variáveis de ambiente ou valores de secrets
- Tokens JWT, API keys, senhas ou qualquer credencial
- Output de comandos (stderr/stdout)

Qualquer adição futura ao schema deve ser submetida à revisão de privacidade antes de ser implementada.

---

## Sync multi-máquina

Os arquivos JSONL são **append-only por projeto** — amigáveis ao mecanismo de autosync/iCloud existente no IdeiaOS (sem banco de dados, sem locks de arquivo). Características:

- Conflitos de merge são raros: cada máquina escreve em sequência temporal diferente.
- Se ocorrerem conflitos de merge, `/instinct-analyze` (plan 05-02) deduplica por `(session_id, ts, tool, file)` antes de processar.
- `~/.ideiaos/` **não deve ser adicionado ao .gitignore** — é um diretório fora do repositório por design (home do usuário).

---

## Ciclo de vida / Rotação

- `observations.jsonl` é **efêmera** — não há retenção infinita por design.
- `/extract-learnings` (plan 05-03) consome as observações e pode truncar ou arquivar o arquivo após processar.
- Instincts maduros derivados das observações vão para `~/.ideiaos/instincts/` (plan 05-02).
- Sem necessidade de rotação manual — o ciclo extract-learnings → instincts gerencia o tamanho.

---

## Quem escreve / Quem lê

| Papel | Componente | Plan |
|-------|-----------|------|
| **Escreve** | `source/hooks/observe-tool-use.sh` (PostToolUse) | 05-01 (esta plan) |
| **Escreve** | `source/hooks/observe-session-end.sh` (Stop) | 05-01 (esta plan) |
| **Lê** | `/instinct-analyze` (skill) | 05-02 |
| **Lê** | `/learn` (skill) | 05-02 |
| **Lê + Trunca** | `extract-learnings` (skill) | 05-03 |

> O schema desta jsonl é o **contrato** consumido por 05-02. Mudanças nos campos `tool`, `file`, `ext`, `bash_verb`, `ok`, `session_end` exigem atualização coordenada com 05-02.
