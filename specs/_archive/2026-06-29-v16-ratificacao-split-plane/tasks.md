# Tasks: v16-ratificacao-split-plane

Checklist consumível pelo GSD quando a CONSTRUÇÃO do v16 for destravada (todas gated; a ratificação
do contrato em si NÃO depende delas).

## Ratificação (esta mudança — pure-design, sem código)

- [x] Extrair os SHALL de R16-01/R16-02 dos designs 80/81 + ADR (workflow `wf_1d7ecdf6`, 0 invenção)
- [x] Redigir o delta `delta/cockpit.md` (4 requisitos ADICIONADOS)
- [ ] `spec-validate.sh` PASS (4 hashtags, ≥1 cenário/requisito, sem header duplicado)
- [ ] Revisão adversarial anti-invenção (cada SHALL rastreia a fonte; nada além do que o design sustenta)
- [ ] `spec-merge.sh` → `specs/cockpit/spec.md` (21 → 25 reqs) + arquivar em `specs/_archive/`

## Construção F1 (GATED — não fazer agora)

- [ ] **R16-03 decidido** (transporte GitHub: FG-PAT-bot na service account + contas pessoais por dev) — pré-req de habilitar push multi-dev
- [ ] Motor multi-usuário escolhido (migrar read-model SQLite → Supabase `xdikjgpkiqzgebcjgqmu`) — pré-req da RLS
- [ ] Implementar RLS deny-all + mascaramento por-campo (com o teste NEGATIVO do contrato como gate)
- [ ] Implementar fluxo de Admissão (enrollment TOFU → PENDENTE → aprovação admin = re-pin local)
- [ ] Read-fan-out F1 (P3 read-only) com prova de incapacidade estrutural (sem `value`, exit 9 ALERT)

## Pós-gate (parqueado por necessidade comprovada)

- [ ] R16-04 claims anti-colisão — só após "2º dev real + colisão medida ≥1×"
- [ ] R16-05 fila-de-Publish advisory — gated em R15-17 + F1-F3 + ratificação
