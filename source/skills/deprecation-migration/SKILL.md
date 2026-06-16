---
name: deprecation-migration
description: "Deprecação & migração — remove sistemas/APIs/features antigos e move usuários com segurança do velho para o novo. Ative quando o usuário disser: 'remover sistema antigo', 'deprecar API', 'migrar usuários', 'consolidar implementações duplicadas', 'código zumbi', 'strangler pattern', 'manter ou aposentar legado', ou digitar /deprecation-migration. OPT-IN (catálogo via /ideiaos-catalog — não empacotada por default). Absorvido de agent-skills (Osmani). PT-BR."
---

# SOURCE: agent-skills MIT addyosmani/agent-skills | adapted: IdeiaOS v8

# Skill: /deprecation-migration — Deprecação & Migração

**Idioma:** Português brasileiro.

> Código é **passivo, não ativo**. Cada linha tem custo contínuo (testes, docs, patches
> de segurança, onboarding). O valor é a funcionalidade, não o código. Organizações sabem
> construir; poucas sabem **remover** — esta skill cobre esse gap.

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/deprecation-migration` |
| Pela Deia | `Deia, quero deprecar o serviço antigo de pagamento` |
| Linguagem natural | `como migro os usuários sem quebrar?` · `tem código zumbi aqui` |

## Quando usar
- Substituir sistema/API/lib antigo por novo; aposentar feature; consolidar duplicações
- Remover código morto que ninguém possui mas todos dependem
- Planejar o ciclo de vida de um sistema novo (deprecação começa no design)

## Quando NÃO usar
- Refactor interno sem mudança de interface pública → trabalho normal de `@dev`
- Otimização de performance → `performance-optimizer`

## Princípios
- **Hyrum's Law torna a remoção difícil:** com usuários suficientes, todo comportamento observável (inclusive bugs e quirks) vira dependência → deprecação exige **migração ativa**, não só anúncio.
- **Deprecação começa no design:** "como removeríamos isto em 3 anos?" Interfaces limpas + feature flags são mais fáceis de aposentar.
- **Advisory por default; compulsory só** quando há risco de segurança / bloqueio / custo insustentável (e com tooling de migração fornecido).

## A decisão de deprecar (responda antes)
1. Ainda provê valor único? (sim → mantenha)
2. Quantos consumidores dependem? (quantifique o escopo)
3. Existe substituto? (não → construa primeiro; não deprecar sem alternativa)
4. Custo de migração por consumidor? (trivial-automatizável → faça; manual-caro → pese)
5. Custo de **não** deprecar? (risco de segurança, tempo de eng, complexidade)

## Processo de migração
1. **Construa o substituto** (cobre casos críticos, tem guia, provado em produção).
2. **Anuncie & documente** (status, substituto, data de remoção, razão, guia de migração com passos concretos).
3. **Migre incremental** — um consumidor por vez: identificar touchpoints → atualizar → verificar paridade → remover referências → confirmar sem regressão. **Churn Rule:** quem é dono da infra deprecada é responsável por migrar os usuários (ou prover update retrocompatível) — não jogue no colo deles.
4. **Remova o velho** só após **zero uso ativo** (métricas/logs/análise de dependência): remova código + testes + docs + config + avisos de deprecação.

**Patterns:** Strangler (rotear tráfego 0→100% e remover), Adapter (interface antiga → implementação nova), Feature Flag (trocar consumidores um a um).

## Código zumbi
Ninguém possui, todos dependem; sem commits há 6+ meses mas com consumidores ativos; sem mantenedor; testes quebrados ignorados; deps com CVE não-atualizadas. **Resposta:** atribua dono e mantenha, **ou** depreque com plano concreto. Zumbi não fica em limbo.

## Tabela anti-racionalização

| Racionalização | Realidade |
|---|---|
| "Ainda funciona, por que remover?" | Código sem manutenção acumula dívida de segurança e complexidade — o custo cresce em silêncio. |
| "Alguém pode precisar depois" | Se precisar, reconstrói. Manter código não-usado "por via das dúvidas" custa mais que reconstruir. |
| "A migração é cara demais" | Compare com o custo de manutenção por 2–3 anos. Migrar costuma ser mais barato a longo prazo. |
| "Deprecamos depois que o novo ficar pronto" | Deprecação começa no design. Quando o novo ficar pronto, já haverá novas prioridades. |
| "Os usuários migram sozinhos" | Não migram. Forneça tooling/docs/incentivo — ou migre você (Churn Rule). |
| "Mantemos os dois indefinidamente" | Dois sistemas iguais = dobro de manutenção, teste, doc e onboarding. |

## Red flags
- Sistema deprecado sem substituto disponível; anúncio sem tooling/doc de migração
- Deprecação "soft" advisory há anos sem progresso; código zumbi sem dono com consumidores ativos
- Feature nova adicionada a sistema deprecado (invista no substituto)
- Deprecar sem medir uso atual; remover código sem verificar zero consumidores

## Verificação
- [ ] Substituto provado em produção, cobre casos críticos
- [ ] Guia de migração com passos e exemplos concretos
- [ ] Todos os consumidores ativos migrados (verificado por métricas/logs)
- [ ] Código + testes + docs + config do velho totalmente removidos
- [ ] Nenhuma referência ao sistema deprecado resta na codebase
- [ ] Avisos de deprecação removidos (cumpriram seu papel)
