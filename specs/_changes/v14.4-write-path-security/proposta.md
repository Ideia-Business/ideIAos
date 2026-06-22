# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Proposta de Mudança: v14.4-write-path-security

**Data:** 2026-06-22
**Autor:** Deia (orquestração multi-agente — precursor em `docs/ideiaos-console/70-security-v14_4-threat-model-precursor.md` + `77-atalaia-alerts-command-allowlist.md`)
**Status:** rascunho
**Criticidade:** MÁXIMA (write-path: comando cross-máquina + mutação de produção)

---

## Por quê

A capability `cockpit` (v14.0–v14.1, SHIPPED) é **read-only + comando local-e-reversível** por
construção. O requisito vivo **"Comando cross-máquina e mutação de produção gated"** já existe e
**barra** todo o write-path até que exista *"um contrato `/spec` de segurança com threat-model
(STRIDE + OWASP-LLM) aprovado"*. **Esta proposta é esse contrato.**

A v14.4 reabre de propósito as brechas que a v14.1 fechara estruturalmente:

1. **Comando cross-máquina** — o `agentd` deixa de ser coletor read-only e vira **executor com
   posse de segredo** ("a chave do reino": comprometê-lo = comprometer tudo).
2. **Mutação de produção** — `rotate`/`revoke`/`deploy` são **RCE-equivalentes** sobre 4 bancos
   Supabase, Vercel, Railway e a org GitHub.
3. **Fila propagada por git** — o canal de comando viaja pelo mesmo bus (`git`) que o
   `git-autosync` faz `git add -A` + push cego a cada ~900s.

O problema-núcleo, cru (doc 70 §2-bis): **`sha256` do conteúdo ≠ assinatura.** Hash é checksum de
integridade contra corrupção, **não** prova de origem — qualquer processo que escreva o conteúdo
recomputa o hash. Sem **autenticação de origem verificável**, o RBAC inteiro é falsificável (o
papel é auto-declarado) e o comando cross-máquina não tem prova de quem o emitiu.

## O que muda

Adiciona à capability **`cockpit`** **11 requisitos de comportamento do write-path** (R-WP1…R-WP11)
que definem **o que o gate de v14.4 exige** antes de qualquer linha de código. O contrato:

- **Define o COMPORTAMENTO contratado** (SHALL/DEVE), não o mecanismo. A direção recomendada é
  **assinatura por-máquina** (O2, via keychain do SO; O3/SSH-signing como implementação concreta
  se o signing-git for bootstrapado) **+ out-of-band (O4)** para o tier crítico — mas a **escolha
  do mecanismo** e a **resolução das questões Q1–Q3** permanecem **decisão do operador** e ficam
  fora desta proposta.
- **Mantém o write-path DESLIGADO** enquanto as 3 questões críticas não forem resolvidas — e o
  **merge deste contrato NÃO as resolve**: ratificar o `/spec` cria as exigências, não as satisfaz.
  "Contrato de segurança aprovado" (o gate vivo) significa contrato **+ Q1–Q3 cravadas em ADR**:
  - **Q1** — bootstrap/distribuição de confiança das chaves de máquina (sem CA);
  - **Q2** — revogação de uma chave de máquina comprometida;
  - **Q3** — onde a passkey/Touch ID assina sem relying-party server (alternativa
    LocalAuthentication-via-agentd a ser provada).
- **Habilitação incremental** (espírito SOAK): primeiro `rotate sensível` na **própria máquina**
  (sem cross-máquina), maturado por um ciclo; cross-máquina só **depois** de Q1–Q3 cravadas;
  `deploy` e `revoke critical` por último, sempre com confirmação out-of-band.
- **Fronteira permanente** (doc 70 §6, doc 77 §B.2): `reveal`/cópia de valor, `exec`/shell,
  `git push`/`gh pr`, (re)config de MCP, rotação/deploy **automáticos** sem ator humano, custódia
  de chave-mestra central, e `revoke`/`rotate` em massa atômico **NUNCA** entram no allowlist —
  nem com threat-model aprovado. São risco estrutural, não falta de auth.

Nenhum requisito existente da `cockpit` é alterado — a mudança é **aditiva**. O gate vivo continua
intacto; estes requisitos passam a ser o **conteúdo** que ele exigia.

## Capabilities afetadas

### Novas

- (nenhuma)

### Modificadas

- `cockpit` — **aditivo**: 11 novos requisitos do write-path (R-WP1…R-WP11). Nenhum requisito
  existente é modificado, removido ou renomeado.

### Removidas

- (nenhuma)

---

## Impacto

| Dimensão | Descrição |
|----------|-----------|
| Usuários afetados | Operador-CTO (P0, monousuário hoje). RBAC `cto`/`dev` é provisão para o 2º ator (`desenvolvimento@`), não necessidade atual — fail-closed, dois papéis, escopo binário (sem ABAC/tenancy granular) |
| Compatibilidade | Aditivo — nenhum contrato existente muda; o read-path de v14.0–v14.1 permanece intacto |
| Risco | **MÁXIMA** — write-path é RCE-equivalente sobre produção. Mitigado **estruturalmente**: autenticação fail-closed, Zero-Leak estendido ao canal de comando, janela-com-teardown, fronteira permanente, habilitação incremental gated em Q1–Q3 |
| Dependências | Capacidade de **assinatura por-máquina** (keychain do SO) a bootstrapar; estado de `commit.gpgsign`/`gpg.format=ssh` (A4/Q7) **não-verificado** — tratado como aberto. Resolução de Q1–Q3 (decisão do operador) bloqueia o cross-máquina. ref `cockpit` (canal), ledger encadeado, `security-freshness` (frescor da revisão) |
| Zero código nesta proposta | Esta proposta é **contrato de comportamento**. A implementação é a fase GSD da v14.4, **gated** por este contrato + Q1–Q3 |

---

*Precursor: `docs/ideiaos-console/70-security-v14_4-threat-model-precursor.md` (§8 = lista de
questões; §9 = veredito "gate, não milestone"). Allowlist/fronteira: doc 77 §B.2.*
*Regra-piso: `credential-isolation`. Autoridade: `agent-authority`. Frescor: `security-freshness`.
Eixo determinístico: `antifragile-gates`. Higiene MCP/Excessive Agency: `mcp-hygiene`.*
