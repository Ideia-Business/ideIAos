# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Proposta de Mudança: v14-cockpit-foundation

**Data:** 2026-06-20
**Autor:** Deia (orquestração multi-agente — blueprint em `docs/ideiaos-console/`)
**Status:** rascunho

---

## Por quê

O ecossistema IdeiaOS já se auto-telemetra cross-máquina (SOAK, security-freshness,
idea-doctor, git-autosync, instincts) há 13 milestones, mas não existe uma **visão única
de CTO/Tech-Lead** sobre o todo: quais máquinas estão vivas, quais produtos/contas/IAs
estão conectados, onde cada chave existe (e sua idade/rotação), quais MCPs estão ligados, e
quanto tempo de IA virou entrega verificada. Hoje responder "a frota está saudável?" ou "essa
chave existe e qual a idade?" exige abrir um terminal e cruzar ledgers à mão.

O risco de fazer isso errado é grave: um console que centraliza chaves e conexões é a maior
superfície de ataque imaginável. A regra-piso `credential-isolation` exige que o **valor** de
um segredo nunca transite pelo contexto do LLM nem do browser. Logo o produto precisa nascer
como **control-plane (metadata + comando local reversível), não cofre**.

## O que muda

Introduz a capability **`cockpit`**: o contrato de comportamento durável de um console
local-first (o **IdeiaOS Cockpit**) que faz *surfacing* sobre o substrato existente e executa
apenas comando **local e reversível**. Comportamentos observáveis contratados:

- O Cockpit nunca expõe o valor de um segredo (invariante Zero-Leak).
- A coleta é read-only e não muta o working tree; a federação cross-máquina usa um ref git
  dedicado (`cockpit`) fora do alcance do `git add -A` do autosync, preservando o pull-only do `main`.
- O frescor é honesto: local-vivo vs cross-máquina-eventual, sem simular fluxo contínuo sobre lote.
- O comando é restrito a um allowlist fixo de verbos locais reversíveis; mutação de produção e
  ação cross-máquina ficam fora até um `/spec` de segurança com threat-model aprovado (v14.4).
- A autoridade exclusiva de @devops (push/PR/MCP) é respeitada — o Cockpit no máximo gera o comando.
- Saúde por produto com sub-sinal honesto (`n/a` onde idea-doctor não roda).
- Toda afirmação é verificável contra o disco no instante da pergunta (Time-to-Truth).

## Capabilities afetadas

### Novas

- `cockpit` — contrato de comportamento do console CTO local-first do IdeiaOS (read-only + comando local).

### Modificadas

- (nenhuma)

### Removidas

- (nenhuma)

---

## Impacto

| Dimensão | Descrição |
|----------|-----------|
| Usuários afetados | Operador-CTO (P0, monousuário hoje); P1/P2 rotulados vaporware até segundo ator |
| Compatibilidade | Aditivo — nova capability; nenhum contrato existente muda. Substrato muda só de forma aditiva (flag `--json`, novo LaunchAgent, ref órfão) |
| Risco | médio — superfície de credenciais e comando; mitigado por design estrutural (Zero-Leak, allowlist fixo, gating de v14.4) |
| Dependências | git-autosync (push do ref), idea-doctor (`--json`), SOAK ledger, security-freshness; threat-model `/spec` para v14.4 |
