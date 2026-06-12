# SOURCE: IdeiaOS v2

# Instincts Layout — `~/.ideiaos/instincts/`

Este documento define o **contrato central** do sistema de instincts atômicos do IdeiaOS.
Consumido por: `/instinct-analyze`, `/learn`, `/instinct-status`, `/evolve` (05-03), e `recall-learnings` Passo 6.

---

## Árvore de diretórios

```
~/.ideiaos/
└── instincts/
    ├── project/
    │   └── <projeto-slug>--<instinct-slug>.md   # scope=project
    └── global/
        └── <instinct-slug>.md                    # scope=global
```

- `scope=project` → arquivo em `project/`, prefixado com o slug do projeto para evitar colisão entre projetos.
- `scope=global` → arquivo em `global/`, sem prefixo.
- Slug derivado de: `slugify(trigger)` — kebab-case, sem acentos, sem pontuação especial.

---

## Schema do instinct (contrato de frontmatter)

```markdown
---
trigger: "ao editar arquivo .ts/.tsx"
action: "rodar tsc --noEmit antes de assumir que compila"
confidence: 0.6          # 0.3 (fraco) .. 0.9 (forte). Nunca 1.0.
domain: "typescript"     # área: typescript, supabase, git, testing, shell, nextjs, ...
scope: "project"         # project | global
project: "ideiapartner"  # presente SOMENTE se scope=project
evidence_count: 3        # quantas observações/sessões sustentam este instinct
created: "2026-06-11"
updated: "2026-06-11"
source: "instinct-analyze"  # instinct-analyze | learn
---
# SOURCE: IdeiaOS v2

## Evidência
- <bullets abstratos: padrão observado, sem conteúdo de arquivo nem secrets>

## Falsos positivos
- <quando NÃO aplicar — se conhecido>
```

---

## Regras de confidence

| Situação | Valor inicial |
|----------|---------------|
| Análise automática, 2 evidências | 0.3 |
| Análise automática, 3–4 evidências | 0.5 |
| Análise automática, 5+ evidências | 0.6 |
| Entrada manual via `/learn` | 0.5 |
| Reforço de instinct existente | `+~0.1` por ciclo, cap 0.9 |
| Teto absoluto (qualquer fonte) | 0.9 |

**Maturidade:** confidence ≥ 0.7 = instinct maduro, elegível a `/evolve` (promoção para skill ou regra).

Nunca usar 1.0 — instinct é probabilístico, não lei.

---

## Dedup por slug(trigger)

Chave de identidade = `slugify(trigger)`. Algoritmo de dedup (compartilhado por `/instinct-analyze` e `/learn`):

1. Computar `slug = slugify(trigger)` do novo instinct.
2. Verificar se `~/.ideiaos/instincts/<scope>/<prefix><slug>.md` já existe.
3. Se **existe**: incrementar `evidence_count += 1`; recalcular `confidence = min(confidence + 0.1, 0.9)`; atualizar `updated`; preservar `created` e `trigger`/`action` originais (ou atualizar se a formulação melhorou).
4. Se **não existe**: criar arquivo novo com `evidence_count: 1`.

Nunca criar dois arquivos com o mesmo slug — duplicata é sempre um bug.

---

## Decay e curadoria

O campo `updated` habilita curadoria temporal:

- Instinct não reforçado há muito tempo pode ter `confidence` reduzida na próxima análise.
- A aplicação efetiva do decay fica em `/evolve` (plano 05-03), que lê `updated` e decide.
- Aqui apenas registramos: `updated` deve ser atualizado em **todo** reforço ou edição manual.

---

## Sync multi-máquina

- **1 arquivo por instinct** (não índice monolítico) — merges de iCloud/autosync raramente colidem.
- Quando colisão ocorre, é num único arquivo, fácil de resolver manualmente.
- `~/.ideiaos/instincts/` propaga pelo mesmo mecanismo de sync já existente (iCloud Drive ou autosync LaunchAgent).
- **Não versionar em git de projeto** — instincts são estado de aprendizado da máquina/usuário, não do repositório.

---

## Quem escreve e quem lê

| Ator | Papel |
|------|-------|
| `/instinct-analyze` | Escreve instincts em lote (agente haiku background) |
| `/learn` | Escreve 1 instinct manual (mid-session, confidence 0.5) |
| `/instinct-status` | Lê e exibe com barras de confidence |
| `/evolve` (05-03) | Lê instincts maduros (≥0.7) e promove para skills/regras |
| `recall-learnings` Passo 6 | Lê instincts do projeto antes de planejar |

---

## Exemplos de instincts válidos

**project/ideiapartner--ao-editar-ts-rodar-tsc.md**
```
trigger: "ao editar arquivo .ts/.tsx"
action: "rodar tsc --noEmit antes de assumir que compila"
confidence: 0.7
domain: "typescript"
scope: "project"
project: "ideiapartner"
evidence_count: 5
```

**global/ao-usar-git-stash-verificar-stash-list.md**
```
trigger: "ao usar git stash"
action: "verificar git stash list antes — stash silenciosamente empilha"
confidence: 0.5
domain: "git"
scope: "global"
evidence_count: 2
```
