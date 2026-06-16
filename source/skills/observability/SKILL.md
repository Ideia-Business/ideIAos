---
name: observability
description: "Observabilidade & instrumentação — instrumenta o código para que o comportamento em produção seja visível e diagnosticável. Ative quando o usuário disser: 'adicionar logs/métricas/tracing', 'instrumentar', 'não sei o que aconteceu em produção', 'configurar alertas', 'RED metrics', 'OpenTelemetry', 'log estruturado', ou digitar /observability. OPT-IN (catálogo via /ideiaos-catalog — não empacotada por default). Absorvido de agent-skills (Osmani). PT-BR."
---

# SOURCE: agent-skills MIT addyosmani/agent-skills | adapted: IdeiaOS v8

# Skill: /observability — Observabilidade & Instrumentação

**Idioma:** Português brasileiro.

> Código que você não observa é código que você não opera. Instrumentação não é add-on
> pós-launch — é escrita junto com a feature, igual aos testes. Feature sem telemetria
> transforma o primeiro bug reportado em **arqueologia**, não em query.

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/observability` |
| Pela Deia | `Deia, instrumenta esse endpoint antes de subir` |
| Linguagem natural | `não consigo saber o que falhou em produção` · `preciso de RED metrics aqui` |

## Quando usar
- Qualquer feature que vai rodar em produção; novo serviço/endpoint/job/integração externa
- Incidente que demorou demais para diagnosticar; criar/revisar regras de alerta
- PR que adiciona I/O, retries, filas ou chamadas cross-service

## Quando NÃO usar
- Diagnosticar falha **acontecendo agora** → `debugging` / `silent-failure-hunter`
- Otimizar lentidão medida → `performance-optimizer` / `/benchmark-optimization-loop`
- Checklist de launch/rollback → `/lovable-handoff` / shipping

## Processo (resumo)
1. **Defina "funcionando" antes de instrumentar** — escreva 2–4 perguntas que o on-call fará. Telemetria sem pergunta é ruído.
2. **Sinal certo por pergunta:** métrica diz **que** algo está errado; trace diz **onde**; log diz **por quê**.
3. **Log estruturado** — eventos, não prosa: JSON com `event` estável + campos machine-readable. Níveis consistentes (error/warn/info/debug). **Correlation ID obrigatório** em toda linha/span/chamada. **Nunca logar secrets/tokens/PII** (regra dura de segurança — allowlist de campos).
4. **Métricas RED** por endpoint e dependência externa (Rate/Errors/Duration) e **USE** para recursos. **Cardinalidade é o modo de falha** — labels de conjuntos pequenos e fixos (route template, status class, provider); nunca user_id/URL crua/mensagem de erro. Percentis sempre (p50/p95/p99), média nunca.
5. **Tracing distribuído** com OpenTelemetry (vendor-neutral; auto-instrumentação cobre HTTP/gRPC/DB). Propague contexto em toda fronteira async.
6. **Alertas em sintomas que o usuário sente** (error rate >1% por 5min, p99 >2s), não em causas (CPU 85%). Todo alerta: acionável + link de runbook + threshold justificado + 2 severidades (page/ticket).
7. **Verifique a própria telemetria** — force erro em staging e ache pelo `requestId`; confirme séries/labels; siga 1 request ponta-a-ponta no tracing.

## Tabela anti-racionalização

| Racionalização | Realidade |
|---|---|
| "Adiciono log depois que funcionar" | "Depois" vira "depois do 1º incidente" — o momento mais caro para descobrir que você está cego. |
| "Mais logs = mais observabilidade" | Ruído não-estruturado deixa o incidente mais lento. 3 eventos queryáveis > 300 linhas de prosa. |
| "console.log basta por ora" | Output não-estruturado não filtra, correlaciona nem alerta. Logger estruturado custa 5min uma vez. |
| "User ID como label facilita debug" | E derruba o backend de métricas. Alta cardinalidade vai em logs/traces. |
| "Tracing é overkill p/ 2 serviços" | 2 serviços já geram pergunta de latência cross-service que log não responde. |

## Red flags
- PR com retries/filas/chamadas externas e zero telemetria nova
- Log por interpolação de string em vez de campos estruturados; sem correlation ID
- Métrica com label user_id/URL crua/texto de erro (bomba de cardinalidade)
- Latência como média sem percentis; alerta que dispara diário sem ação
- Alerta em causa (CPU) paginando humano enquanto error rate fica sem monitorar
- Secret/token/body completo aparecendo em log

## Verificação
- [ ] As perguntas do on-call estão escritas e cada sinal mapeia para uma
- [ ] Todo log é estruturado (JSON) com nome de evento estável + correlation ID por linha
- [ ] Nenhum secret/token/PII em log (spot-check do output real)
- [ ] RED em todo endpoint/dependência externa, com label sets limitados
- [ ] Latência é histograma; p95/p99 queryáveis
- [ ] Um request seguível ponta-a-ponta no tracing sem spans quebrados
- [ ] Todo alerta novo é symptom-based, com runbook, e foi disparado uma vez em teste
