---
name: instinct-status
description: Lista os instincts aprendidos em ~/.ideiaos/instincts/ com barras de confidence, agrupados por domínio e scope (project/global). Use quando o usuário perguntar "o que você já aprendeu?", "quais instincts temos?", ou quiser revisar antes de /evolve.
---

# SOURCE: IdeiaOS v2

# Skill: instinct-status

Você exibe os **instincts aprendidos** do projeto atual (e globais), com barras visuais de confidence, ordenados por domínio e força. Entrada rápida antes de `/evolve` ou ao revisitar um projeto.

**Idioma:** Português brasileiro.

---

## Quando usar

- Usuário pergunta "o que você já aprendeu?", "quais instincts temos?", "mostra os instincts".
- Antes de executar `/evolve` — para selecionar candidatos maduros.
- Ao retomar projeto após longa pausa — revisar base de instincts antes de planejar.
- Explicitamente via `/instinct-status`.

---

## Pipeline

### Passo 1 — Localizar instincts

```bash
PROJETO_SLUG=$(basename "$PWD")
INSTINCTS_DIR="$HOME/.ideiaos/instincts"
```

Se `$INSTINCTS_DIR` não existir ou estiver vazio:
```
Nenhum instinct ainda. Rode /instinct-analyze após algumas sessões.
```
Encerrar.

### Passo 2 — Varrer e parsear

Varrer os dois diretórios de scope:

```bash
# Instincts de projeto (prefixados com <projeto-slug>--)
find "$INSTINCTS_DIR/project" -name "${PROJETO_SLUG}--*.md" 2>/dev/null

# Instincts globais
find "$INSTINCTS_DIR/global" -name "*.md" 2>/dev/null
```

Para cada arquivo `.md`, ler o frontmatter YAML. Parse via `python3` inline (sem jq):

```bash
python3 - "$arquivo" <<'PYEOF'
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
# Extrair bloco frontmatter entre --- e ---
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if m:
    for line in m.group(1).splitlines():
        print(line)
PYEOF
```

Campos a extrair: `trigger`, `action`, `confidence`, `domain`, `scope`, `evidence_count`, `updated`.

### Passo 3 — Renderizar com barras de confidence

Barra de confidence (escala 0.0–1.0, 10 blocos):

```python
def barra(conf):
    preenchidos = round(conf * 10)
    return "[" + "█" * preenchidos + "░" * (10 - preenchidos) + f"] {conf:.1f}"
```

Exemplo: confidence 0.6 → `[██████░░░░] 0.6`

Marcador de maturidade: confidence ≥ 0.7 → marcar com `★ elegível /evolve`.

### Passo 4 — Saída agrupada e ordenada

Estrutura da saída:

```
## Instincts — <projeto> (project)

### domain: typescript
- [██████░░░░] 0.6  ao editar .ts → rodar tsc --noEmit  (evidências: 3 | atualizado: 2026-06-11)
- [████░░░░░░] 0.4  ao usar any → documentar o motivo   (evidências: 2 | atualizado: 2026-06-10)

### domain: git
- [████████░░] 0.8 ★  ao fazer rebase → verificar stash antes  (evidências: 6 | atualizado: 2026-06-11)

## Instincts globais

### domain: shell
- [█████░░░░░] 0.5  ao criar script .sh → chmod +x imediatamente  (evidências: 2 | atualizado: 2026-06-09)

---
Total: N project, M global  |  Maduros (≥0.7): K  |  Elegíveis /evolve: K
```

**Regras de ordenação:**
- Dentro de cada domínio: order by `confidence` DESC, depois `evidence_count` DESC.
- Domínios com mais instincts ficam primeiro.

### Passo 5 — Resumo final

```
---
Total: N project, M global  |  Maduros (≥0.7): K  |  Elegíveis /evolve: K
```

Se houver instincts maduros (★), sugerir:
```
Há K instinct(s) maduro(s). Use /evolve para promovê-los a skills ou regras.
```

---

## Anti-padrões

- Listar instincts de todos os projetos — filtrar pelo projeto atual (`basename $PWD`).
- Mostrar campos internos desnecessários (ex.: `source`, `created`) — foco em trigger/action/confidence.
- Não mostrar a barra visual — a barra é a UI principal, não um detalhe.
- Esconder os maduros — destacar ★ é o ponto central da skill.

---

## Relações

- **Lê:** `~/.ideiaos/instincts/<scope>/<slug>.md`
- **Pré-condição:** `/instinct-analyze` ou `/learn` já rodaram ao menos uma vez
- **Próximo passo natural:** `/evolve` para instincts com ★
- **Schema dos arquivos:** `docs/instincts/instincts-layout.md`
