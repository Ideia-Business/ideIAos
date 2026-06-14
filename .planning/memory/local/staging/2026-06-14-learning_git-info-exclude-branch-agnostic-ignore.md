---
name: git-info-exclude-branch-agnostic-ignore
description: "Para ignorar um arquivo gerado em QUALQUER branch (não só o atual), use .git/info/exclude — .gitignore é per-branch e vaza"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6894cb82-2e04-4b3c-8682-fa14d0531c0f
---

Quando um hook gera um arquivo no working tree que NUNCA pode ser commitado num branch protegido (ex.: `.cursor/rules/memory-bridge.mdc` que não pode chegar ao `main` lido pela Lovable), `.gitignore` sozinho é frágil: ele é versionado **por branch**, então um branch sem a entrada deixa o arquivo passar.

**Defesa branch-agnóstica:** o hook adiciona o padrão a `.git/info/exclude` (local ao clone, vale em todos os branches, impossível de commitar). Idempotente:
```bash
grep -qxF "$pat" "$gitdir/info/exclude" 2>/dev/null || printf '%s\n' "$pat" >> "$gitdir/info/exclude"
```
Use os DOIS: `.gitignore` para o padrão time-wide + `.git/info/exclude` como cinto-e-suspensório local. Origem: v5 memory-sync, invariante Lovable. Ver [[learning_version-reset-migration-semver-trap]] (mesmo espírito de barreira determinística > documentação passiva).
