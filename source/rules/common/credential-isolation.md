<!--SOURCE: IdeiaOS v12 | kind: rule | targets: claude,cursor-->
# Credential Isolation — Segredo nunca transita pelo contexto do LLM

<!-- Conceito absorvido (conceito-only): TalEliyahu/Awesome-AI-Security (MIT) §Tools
     (padrão OneCLI/Cerbos: o agente nunca vê a credencial em claro) + OWASP LLM02
     Sensitive Information Disclosure / LLM06 Excessive Agency (genai.owasp.org,
     CC BY-SA 4.0). Zero código/prosa de terceiros. -->

## Princípio

A **autoridade para executar uma operação** (quem pode `git push`, aplicar migration,
chamar uma API) é coisa distinta da **posse do segredo** que a operação usa. O
`agent-authority.md` governa a primeira; esta rule governa a segunda — eixo ortogonal.

**Regra-piso:** um segredo (API key, token, senha, `service_role`) **nunca deve
transitar pelo contexto do LLM** — nem no prompt, nem no output, nem num arquivo que o
agente lê para "saber o valor". O agente referencia o segredo por **nome**
(`$ASAAS_API_KEY`); a injeção do valor acontece **fora** do contexto — variável de
ambiente lida pelo processo, secret manager, ou gateway/policy-layer que injeta no
request server-side e autoriza por política fine-grained.

## Por que — o vão que o ferramental atual deixa

Hoje o IdeiaOS é **reativo** quanto a segredo:

- `idea-doctor` (§7c) escaneia segredo em texto plano na memória — **detecta post-hoc**.
- o gate de `memory-export` (R5-06) barra export com segredo — **detecta post-hoc**.
- o agent `security-reviewer` aponta secret vazado num diff — **detecta post-hoc**.

Nenhum é **preventivo**: nada diz, antes do fato, "o segredo não entra no contexto".
Esta rule é essa doutrina preventiva. Liga direto ao incidente
`IDEIA_CHAT_SYSADMIN_PASSWORD` (memória `project-ideia-chat-test-secret-acceptable`): o
problema não era a autoridade, era a **posse** do segredo no lugar errado.

## Como aplicar

- **Referencie por nome, nunca por valor.** Código e prompts citam `$VAR`; o valor vive
  em `.env`/secret-store lido pelo runtime — nunca colado no chat nem hardcoded.
- **Anti-padrão a deprecar:** o workaround de `mcp-usage.md` que manda **hardcodar**
  `value: 'actual-token-value'` em YAML de catálogo MCP é exatamente o que esta rule
  proíbe como padrão. Tolerável só como gambiarra local efêmera de bug de terceiro —
  nunca commitada, nunca propagada.
- **Output também é superfície (OWASP LLM02):** a saída do LLM não pode ecoar segredo —
  trate o output como não-confiável antes de logar/renderizar (cross-link
  `antifragile-gates` e o anti-injection de `context-engineering`).
- **Least-privilege de posse (OWASP LLM06 — Excessive Agency):** dê ao agente o **mínimo**
  de acesso a segredo que a tarefa exige; janelas de privilégio temporário
  (learning `temp-privilege-window-teardown-grants`) valem para posse-de-segredo também.

## Fronteira

Esta rule é **doutrina**, não how-to de secrets-management (não prescreve Vault vs Cerbos
vs OneCLI — isso é decisão product-layer). Diz **o que nunca fazer** (segredo no contexto
do LLM) e **por quê**, deixando o COMO para cada produto. Não substitui
`agent-authority.md` (autoridade de operação) — complementa-a no eixo de **posse de
segredo**.
