<!-- ════════════════════════════════════════════════════════════════════════
     IdeiaOS — Shared Memory Store INDEX
     ────────────────────────────────────────────────────────────────────────
     ⚠️  ESTE STORE VIVE EXCLUSIVAMENTE NO BRANCH `planning`.
         NUNCA faça merge de `.planning/memory/` para `main`.
         O `main` é lido continuamente pela Lovable Cloud — memória ali
         dispara um Lovable Update indevido (vide o leak `.lovable_mem_tmp.md`).

     REGRAS DO STORE:
       • Um arquivo por fato em `facts/` (nome `<type>_<slug>.md`). Nunca
         edite fatos in-place no índice — escreva/atualize o arquivo do fato.
       • ESTE ÍNDICE É GERADO. Reconstruído deterministicamente a partir de
         `facts/` por `memory-export.sh` / `/memory-sync`. Edições manuais
         aqui são sobrescritas no próximo scan. Para mudar uma linha, edite
         o frontmatter (`description`) do arquivo do fato correspondente.
       • Leitura sem checkout:  git show planning:.planning/memory/shared/MEMORY.md
       • Escrita: git plumbing (hash-object→commit-tree→update-ref planning).
         Jamais escreva staging no working tree da branch corrente.
       • `local/` (staging por-máquina) é gitignored no `planning` — não entra
         aqui nem em `shared/`.

     Formato de cada linha (uma por fato, ordenado por nome de arquivo):
       - [<description>](facts/<type>_<slug>.md) — <one-liner>
     ════════════════════════════════════════════════════════════════════════ -->

# MEMORY.md — Shared Store (planning branch)

<!-- BEGIN:facts (gerado por scan de facts/ — não editar manualmente) -->
<!-- END:facts -->
