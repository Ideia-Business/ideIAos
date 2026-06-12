---
name: benchmark-optimization-loop
description: "Loop medir→otimizar→medir para performance: estabelece baseline, muda uma coisa, re-mede, mantém só se melhorou. Use proativamente antes de qualquer otimização. Pareia com agent performance-optimizer."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: benchmark-optimization-loop

**Idioma:** Português brasileiro.

---

## Quando usar

- Antes de qualquer otimização de performance (nunca otimizar sem baseline).
- Quando há suspeita de gargalo (lentidão, custo alto, latência elevada).
- Para validar que uma mudança de performance realmente melhorou (não só "parece mais rápido").

---

## Processo: MEDIR → OTIMIZAR → MEDIR

### 1. Definir a métrica e o baseline

Escolher **uma métrica específica**:
- Latência de endpoint (p50, p95, p99 em ms).
- Duração de query SQL (ms, explain analyze).
- Tempo de build (segundos).
- Tamanho de bundle (KB).
- Custo de tokens (por operação).

Medir o baseline **antes de qualquer mudança**:
```bash
# Exemplo: medir duração de query
EXPLAIN ANALYZE SELECT ...;
# Registrar: Execution Time: 842 ms
```

Registrar na tabela de resultados.

### 2. Fazer uma mudança por vez

**Regra crítica:** mudar apenas **uma coisa** por iteração.
Mudar várias coisas simultaneamente impossibilita saber o que funcionou.

Exemplos de mudanças isoladas:
- Adicionar índice em coluna X.
- Trocar algoritmo de sort.
- Adicionar cache em função Y.
- Substituir library Z por W.

### 3. Re-medir com a mesma metodologia

Medir nas mesmas condições do baseline (mesmo ambiente, mesmo volume de dados, mesma carga).
Comparar com o baseline.

### 4. Decidir: manter ou descartar

| Resultado | Decisão |
|-----------|---------|
| Melhorou ≥ 10% | Manter + documentar |
| Sem diferença relevante | Descartar (complexidade sem ganho) |
| Piorou | Reverter imediatamente |

### 5. Repetir para próxima oportunidade

Cada iteração começa com o novo baseline (após mudanças mantidas).

---

## Output

Tabela de resultados por iteração:

| Iteração | Mudança | Baseline | Resultado | Delta | Decisão |
|----------|---------|----------|-----------|-------|---------|
| 1 | Índice em `user_id` | 842 ms | 45 ms | -94% | Manter |
| 2 | Cache Redis em listagem | 45 ms | 41 ms | -9% | Descartar |
| 3 | Query reescrita com CTE | 45 ms | 12 ms | -73% | Manter |

---

## Anti-patterns

- Otimizar sem medir baseline ("parece lento").
- Mudar várias coisas de uma vez (não sabe o que ajudou).
- Medir em ambiente diferente do baseline (comparação inválida).
- Manter mudança que não melhorou significativamente (adiciona complexidade sem ganho).
- Considerar otimização "feita" sem re-medir após a mudança.

---

## Relações

- Pareia com `cost-tracking` para otimização de custo de tokens/modelo.
- Pareia com agent `performance-optimizer` para análise automatizada.
- Complementa `tdd` — testes de performance podem ser escritos como asserções de threshold.
