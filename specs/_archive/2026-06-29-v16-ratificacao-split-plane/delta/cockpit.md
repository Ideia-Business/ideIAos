# Delta: cockpit — v16-ratificacao-split-plane

**Capability alvo:** cockpit
**Change slug:** v16-ratificacao-split-plane
**Data do delta:** 2026-06-29

Ratificação pure-design do v16 (Plataforma de Time): merge no contrato vivo dos SHALL de R16-01
(R-WP12 — view read-only, divergência = alerta + incapacidade estrutural de P3) e R16-02 (RLS-por-campo
por papel + Admissão de estação por pin O2). NÃO constrói F1/RLS — materializa só o CONTRATO de
comportamento. Toda cláusula rastreia a `docs/ideiaos-console/{80,81}` + ADR `v15-cockpit-split-plane-control-plane.md`.

---

## ADICIONADO Requisitos

### Requisito: Plano de View read-only — divergência vira alerta, nunca autoridade (R-WP12)

O Plano de View (P3) DEVE ser read-only metadata e NUNCA autoridade: o fluxo é unidirecional
(ref/disco → ingest → push assinado → P3 → SELECT da UI) e P3 NUNCA escreve de volta no ref nem no
read-model local. Toda divergência entre a view e o disco/ref autoritativo DEVE ser tratada como
ALERTA, jamais como atualização do estado autoritativo local.

#### Cenário: view diverge do disco autoritativo

- **QUANDO** o conteúdo projetado no Plano de View (ex.: linha de ledger / `security_seal`) diverge do que o `--verify` recomputa do disco/ref local autoritativo
- **ENTÃO** o sistema DEVE emitir um ALERTA (a view mente) e DEVE preservar o estado autoritativo local intacto, NUNCA reescrevendo a fonte (ref/disco) a partir do Plano de View

#### Cenário: tentativa de fluxo reverso para mutar o ref

- **QUANDO** chega ao Plano de View um dado que tentaria mutar o ref `cockpit` ou o read-model local (ingest de volta / fluxo reverso)
- **ENTÃO** a operação DEVE ser recusada por construção — o fluxo é unidirecional e o ref permanece source-of-truth do transporte; P3 NUNCA escreve de volta

### Requisito: Plano de View estruturalmente incapaz de autoridade (R-WP12)

O Plano de View (P3) DEVE permanecer estruturalmente incapaz de autoridade: NENHUMA tabela DEVE ter
coluna `value` (sem valor de segredo, por construção); P3 NÃO DEVE assinar nada; P3 NÃO DEVE pinar nem
mutar a lista pinada autoritativa-local; P3 NÃO DEVE abrir nenhum verbo de execução; e o projeto de
view DEVE ser um Supabase distinto do projeto de step-up (P3 ≠ P4).

#### Cenário: comando "autorizado pelo Supabase" sem assinatura O2

- **QUANDO** um comando chega ao `agentd`-alvo "autorizado pelo Supabase" (Plano de View) porém sem assinatura O2 verificável contra o pin local
- **ENTÃO** o `agentd`-alvo DEVE RECUSAR (`verify-payload.sh` exit≠0) — um `sha256` ou booleano-de-backend NUNCA autoriza comando; a autoridade vive só no `agentd` local

#### Cenário: sinal de revogação/adição de peer vindo do Plano de View

- **QUANDO** o Plano de View recebe um sinal de revogação/adição de peer (`process-supabase-revocation` / `process-supabase-addition`)
- **ENTÃO** o sistema DEVE retornar exit 9 ALERT e NÃO DEVE alterar a lista pinada local — re-pin de peer é sempre out-of-band local, espelhando `process-ref-*`

#### Cenário: veto-de-design do schema do Plano de View

- **QUANDO** o schema do Plano de View é avaliado (revisão de contrato / veto-de-design)
- **ENTÃO** NENHUMA tabela DEVE ter coluna `value`, NÃO DEVE existir policy de INSERT/UPDATE para a UI (só o UPSERT da função de ingestão por-`machine_id`), e o projeto de view DEVE ser distinto do projeto de step-up (P3 ≠ P4)

### Requisito: RLS deny-all com mascaramento de reconnaissance por papel (R16-02)

O Plano de View DEVE aplicar RLS deny-all-por-default e DEVE mascarar campos sensíveis de
reconnaissance por papel/escopo: o `admin` (CTO/TechLead) DEVE ver tudo, enquanto o `dev` DEVE ver
apenas os projetos do seu `user_project_scope`. Nomes de chave `risk_tier=critical` e a cadência de
rotação NÃO DEVEM ser expostos a um `dev` fora do seu escopo — mascaramento por-campo via
view/security-definer, não apenas deny-all binário. A UI DEVE ler somente por anon-key sob RLS
(SERVICE_ROLE NUNCA no browser), sem policy de INSERT/UPDATE para a UI. A IMPLEMENTAÇÃO RLS fica
gated na escolha do motor multi-usuário; este requisito materializa apenas o CONTRATO.

#### Cenário: dev consulta projeto fora do seu escopo (teste negativo)

- **QUANDO** um usuário com `role=dev` faz SELECT sobre metadata de um projeto fora do seu `user_project_scope`
- **ENTÃO** o SELECT NÃO DEVE retornar nomes de chave `risk_tier=critical` nem a cadência de rotação (teste NEGATIVO de RLS por-campo) — projeto/capacidade não-listado = negado (default-deny)

#### Cenário: admin consulta a mesma metadata

- **QUANDO** um usuário com `role=admin` (CTO/TechLead) consulta a mesma metadata
- **ENTÃO** o sistema DEVE retornar a visão completa, pois o escopo de leitura de admin abrange todos os projetos

#### Cenário: leitura da UI sob RLS

- **QUANDO** a UI lê o Plano de View
- **ENTÃO** DEVE ler somente por anon-key sob RLS (SERVICE_ROLE NUNCA no browser) e NÃO DEVE existir policy de INSERT/UPDATE exposta à UI

### Requisito: Admissão de estação por pin O2 com escopo de leitura default-deny (R16-02)

A admissão de uma estação DEVE seguir o fluxo de pin O2 (enrollment TOFU + pin out-of-band): a estação
gera o hash de enrollment {`machine_id`, `signing_fingerprint`, `enc_pubkey`} e o publica como
PENDENTE; um `admin` DEVE aprovar comparando o fingerprint out-of-band, e a aprovação DEVE ser um
re-pin AUTORITATIVO-LOCAL na lista pinada de cada `agentd` (NUNCA pelo ref/P3, que apenas ESPELHA o
status APROVADA como metadata). A autorização de leitura/escopo do `dev` DEVE ser definida por `admin`
em `user_project_scope`, default-deny.

#### Cenário: admin aprova uma estação pendente

- **QUANDO** uma estação publica seu hash de enrollment {`machine_id`, `signing_fingerprint`, `enc_pubkey`} como PENDENTE e o `admin` confirma a aprovação no Cockpit comparando o fingerprint out-of-band
- **ENTÃO** a entrada {`machine_id`, `fingerprint`, `enc_pubkey`, `role`} DEVE ser gravada na lista pinada LOCAL de cada `agentd` (re-pin out-of-band) e o Plano de View DEVE apenas refletir o status APROVADA — o pin NUNCA é adicionado pelo ref nem por P3

#### Cenário: dev tenta acessar projeto fora do seu escopo

- **QUANDO** um `dev` autenticado tenta ver ou trabalhar em um projeto não atribuído no seu `user_project_scope`
- **ENTÃO** o acesso DEVE ser negado (default-deny); e a autorização-de-leitura NÃO DEVE conferir poder de mutação — a autorização de COMANDO é re-provada no alvo pela assinatura+pin
