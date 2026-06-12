# Memory Hygiene — IdeiaOS

> Derivado de: ECC the-security-guide.md (github.com/affaan-m/ECC, MIT). Adaptado para o contexto IdeiaOS + vault Obsidian.

Regras formais de higiene de memória para todas as sessões que usam o IdeiaOS.

---

## Regra 1 — Sem secrets em memória ou vault

**Nunca gravar** API keys, service_role keys, tokens JWT, senhas ou qualquer credencial em:
- `~/.claude/projects/` (memória de projeto do Claude Code)
- Vault Obsidian (Second Brain)
- `STATE.md`, `CONTINUATION_HANDOFF.md`, `SUMMARY.md` ou qualquer arquivo de contexto GSD
- Mensagens de commit

**Como registrar em vez disso:** use referências descritivas — "a chave está no 1Password, item 'Supabase prod service_role'" — nunca o valor em si.

**Verificação:** `bash scripts/idea-doctor.sh` executa a Seção 7c que faz grep de padrões `sk-*`, `ANTHROPIC_API_KEY` e `service_role` na memória de projeto.

---

## Regra 2 — Memória de projeto ≠ global

`~/.claude/projects/<projeto>/` é isolada por projeto por design. Esta regra formaliza que:
- Contexto sensível de um projeto (credenciais, dados de cliente, lógica proprietária) **não deve ser copiado** para a memória global (`~/.claude/`)
- Ao usar `/recall-learnings` ou `/extract-learnings`, verificar que o conteúdo é genérico o suficiente para ser global

Já funciona assim por design — esta regra documenta a expectativa explicitamente.

---

## Regra 3 — Reset após runs não-confiáveis

Depois de absorver, testar ou interagir com conteúdo de terceiros (skills ECC em `security/quarantine/`, MCPs desconhecidos, prompts externos), **limpar o contexto da sessão** antes de continuar trabalho confiável:

1. Encerrar a sessão atual do Claude Code
2. Abrir nova sessão — memória de projeto persiste mas o contexto da conversa é zerado
3. Opcional: revisar `~/.claude/projects/<projeto>/` para remover observações/memórias geradas durante o run não-confiável

**Motivo:** conteúdo de quarentena pode ter tentado injetar instruções no contexto da sessão. Uma sessão nova previne que essas instruções contaminem trabalho posterior.

---

## Como verificar

```bash
bash scripts/idea-doctor.sh   # Seção 7a-7d: deny rules, hooks, secrets, quarentena
```

Saída esperada em ambiente saudável:
- `✓ Memória de projeto sem secrets aparentes`
- `✓ pipeline de quarentena (security/scan-absorbed.sh) presente`
- `✓ Hooks sem curl|bash pipe`
- `✓ deny: Read(~/.ssh/**)` (e demais 5 deny rules)
