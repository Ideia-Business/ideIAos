# SOURCE: IdeiaOS v2 | derivado da avaliação de chopratejas/headroom (Apache-2.0)

# Tasks: tool-output-compressor

**Change:** tool-output-compressor
**Capability(ies):** tool-output-compressor
**Gerado em:** 2026-06-21

Estas tasks derivam do delta e são consumíveis pelo GSD (`/gsd-execute-phase`) ou pelo `@dev` do AIOX.
Formato: `- [ ] N.M <descrição>` onde N = grupo, M = subtask sequencial.

---

## 1. Preparação

- [ ] 1.1 Ler a proposta em `specs/_changes/tool-output-compressor/proposta.md` e confirmar escopo
- [ ] 1.2 Verificar dependências: `antifragile-gates`, `token-economy`, `context-packet-handoffs` estão estáveis
- [ ] 1.3 Decidir o veículo: skill `source/skills/tool-output-compressor/` + lib bash/python determinística (CLI-First), sem dependência externa
- [ ] 1.4 Definir o formato de sentinela CCR e o store local de originais (arquivo/sqlite local com TTL configurável; default conservador)

---

## 2. Implementação — detecção e compressores

- [ ] 2.1 Detector de tipo de conteúdo (log / JSON-array-uniforme / search-results / diff / texto / desconhecido) — determinístico, fence-aware
- [ ] 2.2 Compressor de log: template-ização de linhas repetidas + contagem/variações (alvo medido: ~90%+)
- [ ] 2.3 Compressor de JSON tabular: schema-header único + linhas compactas, preservando todos os valores (alvo medido: ~40–60%)
- [ ] 2.4 Compressor de search-results: dedup de contexto repetido + ranking truncável
- [ ] 2.5 Passthrough garantido para tipo desconhecido/incompressível (redução 0%, bytes intactos)
- [ ] 2.6 Guarda de proteção da intenção do usuário: recusar comprimir conteúdo marcado como mensagem de usuário

## 3. Implementação — reversibilidade (CCR) e integridade

- [ ] 3.1 Modo reversível: substituir conteúdo derrubado por sentinela `<<ccr:HASH …>>` + gravar original no store
- [ ] 3.2 Operação de retrieve por hash; miss retorna erro explícito (nunca conteúdo vazio/silencioso)
- [ ] 3.3 Verificação de round-trip por sha256 (original == recuperado) como gate de aceitação
- [ ] 3.4 Idempotência: marcar saída comprimida e tornar recompressão um no-op
- [ ] 3.5 Fail-open: ausência/falha do componente repassa o original sem erro fatal

## 4. Implementação — medição honesta e CLI

- [ ] 4.1 Medir tokens antes/depois com tokenizer real; reportar % derivado da medição
- [ ] 4.2 Rotular explicitamente qualquer valor estimado como estimativa
- [ ] 4.3 Interface CLI/skill local: zero rede, zero `*_BASE_URL`, zero telemetria; exit-code binário por operação

---

## 5. Testes (verificação por exit-code — `antifragile-gates`)

- [ ] 5.1 Cobrir os 7 requisitos ADICIONADOS com testes automatizados (1+ por cenário do delta)
- [ ] 5.2 Round-trip lossless por sha256 em log/JSON/search (fixtures determinísticas)
- [ ] 5.3 Teste de proteção: mensagem de usuário sai byte-idêntica
- [ ] 5.4 Teste de fail-open (componente ausente) e de passthrough (tipo desconhecido)
- [ ] 5.5 Teste de idempotência (recompressão = no-op) e determinismo (mesma entrada = mesma saída)
- [ ] 5.6 Sandbox `/tmp` limpo (não testar só no repo vivo — cf. learning de sandbox)

---

## 6. Merge e Archive

- [ ] 6.1 Validar delta: `bash source/skills/spec/lib/spec-validate.sh specs/_changes/tool-output-compressor`
- [ ] 6.2 Aplicar merge: `bash source/skills/spec/lib/spec-merge.sh . tool-output-compressor --yes`
- [ ] 6.3 Confirmar archive em `specs/_archive/2026-MM-DD-tool-output-compressor/` e source-of-truth em `specs/tool-output-compressor/spec.md`
- [ ] 6.4 Rodar `bash source/skills/spec/lib/spec-analyze.sh . tool-output-compressor` (gate da spec viva)
- [ ] 6.5 Commit: `spec(tool-output-compressor): apply tool-output-compressor delta`
