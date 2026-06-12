# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
---
name: two-instance-kickoff
description: "Kickoff de projeto novo com 2 instâncias em paralelo: uma faz scaffold/setup, outra faz research do domínio. Use proactively ao iniciar projeto do zero."
---

# Skill: Two-Instance Kickoff

## Quando usar

- Projeto **novo do zero** (primeiro sprint, nenhum código existente).
- Contexto incerto: domínio desconhecido ou stack não definida ainda.
- Você quer scaffold pronto E research de domínio em paralelo, sem bloquear um no outro.

## Quando NÃO usar

- Projeto **existente** com código em produção — use `/gsd-plan-phase` direto.
- Mudança incremental (feature nova, bugfix) — uma instância é suficiente.
- Domínio já bem mapeado pela equipe — o research não agrega.

## Princípio ECC: minimum viable parallelization

Usar só **2 instâncias**, cada uma com objetivo claro. Mais do que isso gera overhead de coordenação maior do que o ganho. O valor está na separação clean de responsabilidades, não na quantidade de instâncias.

## Processo

### Instância A — Scaffold & Setup

Responsabilidade: estrutura técnica do projeto.

1. Inicializar repositório e estrutura de pastas conforme stack escolhida.
2. Configurar dependências principais (`package.json`, `requirements.txt`, etc.).
3. Rodar `/ideiaos-setup` (ou `/dev-setup`) para habilitar as camadas IdeiaOS.
4. Criar `AGENTS.md`, `CLAUDE.md`, `STATE.md` iniciais.
5. Fazer primeiro commit limpo.

Output da Instância A: **projeto scaffoldado e commitado**, pronto para receber código de produto.

### Instância B — Deep Research do Domínio

Responsabilidade: mapear o problema antes de codar.

1. Ativar `/deep-research` com o domínio do projeto como input.
2. Pesquisar: concorrentes, padrões arquiteturais do domínio, armadilhas conhecidas.
3. Produzir um documento de research: `.planning/research/<domínio>-research.md`.
4. Identificar as 3-5 decisões técnicas mais críticas (banco, auth, infra, modelo de dados).

Output da Instância B: **documento de research** + lista de decisões a tomar no planejamento.

### Convergência

Após as 2 instâncias concluírem:

1. Revisar o output da Instância B com o contexto do scaffold (Instância A).
2. Registrar as decisões técnicas em `.planning/research/decisions.md`.
3. Rodar `/gsd-plan-phase` com o documento de research como contexto (`--context .planning/research/`).

## Dicas operacionais

- As instâncias rodam em janelas/sessões separadas do Claude Code.
- Não deixe Instância A esperando Instância B para fazer qualquer decisão de scaffold — scaffold não requer o research.
- Se o research revelar que a stack escolhida é errada, faça o ajuste no scaffold **antes** do primeiro sprint de produto.
- Documente em `STATE.md` qual instância está rodando o quê para evitar conflito.

## Output final esperado

| Artefato | Gerado por |
|----------|------------|
| Projeto scaffoldado + setup IdeiaOS | Instância A |
| `.planning/research/<domínio>-research.md` | Instância B |
| `.planning/research/decisions.md` | Convergência |
| `.planning/` pronto para `/gsd-plan-phase` | Convergência |
