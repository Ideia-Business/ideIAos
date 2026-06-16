# SOURCE: IdeiaOS v2

# ADR: Avaliação do gsd-browser como substituto do chrome-devtools MCP

**Data:** 2026-06-16
**Status:** Avaliação — Piloto hipotético (nenhuma instalação realizada)
**Reavaliar em:** próxima fase visual com necessidade real de visual-diff ou auth-vault

---

## O que é o gsd-browser

CLI Rust com daemon persistente que expõe 92 comandos via CDP (Chrome DevTools Protocol). Principais características:

- **Daemon auto-start:** o daemon sobe automaticamente na primeira chamada; não requer inicialização manual.
- **Sessões nomeadas:** múltiplas sessões paralelas com nomes descritivos.
- **Versioned refs (`@v1:e1`):** cada snapshot congela referências de elementos; re-snapshot gera nova versão, eliminando fragilidade de seletores.
- **Assertions determinísticas:** `assert` e `batch` para sequências atômicas de verificações com output JSON estruturado.
- **Visual-diff nativo:** compara screenshots entre snapshots para detectar regressões visuais.
- **Auth vault:** armazena credenciais criptografadas para fluxos atrás de login.
- **Output JSON:** `--json` em todos os comandos produz saída compacta e parseável.

**Instalação:** binário pré-compilado por plataforma (darwin-arm64 disponível). Dois vetores:
- Script: `curl -fsSL https://install.gsd.build/browser | bash`
- Binário direto: GitHub Releases do org `gsd-build/gsd-browser`

**Status de publicação:** npm e crates.io ainda não publicados — depende exclusivamente do GitHub Releases.

---

## Skill Piloto Avaliada

Referência: [`source/skills/frontend-visual-loop/SKILL.md`](../../source/skills/frontend-visual-loop/SKILL.md)

**Motor atual:** `mcp__chrome-devtools__*` — ferramentas: `list_pages`, `navigate_page`, `take_snapshot`, `take_screenshot`, `resize_page`, `list_console_messages`, `lighthouse_audit`.

**Papel hipotético do gsd-browser nesta skill:**

| Comando gsd-browser | Equivalente atual | Diferencial |
|---------------------|-------------------|-------------|
| `navigate + snapshot + click-ref` | `navigate_page + take_snapshot` | refs versionadas, sem fragilidade de seletor |
| `screenshot` | `take_screenshot` | output JSON, integrável em pipeline |
| `assert` | ausente no chrome-devtools MCP | verificação determinística nativa |
| `visual-diff` | ausente no chrome-devtools MCP | detecção de regressão entre iterações |
| `vault-login` | ausente / workaround manual | fluxos autenticados sem credencial exposta |

O `visual-diff` é particularmente relevante para o loop de 3 iterações da skill: hoje não há como detectar automaticamente se uma iteração introduziu regressão visual — o agente compara mentalmente screenshots. Com o gsd-browser, a comparação seria programática.

---

## Análise por Critério

### 1. Custo de token

**chrome-devtools MCP:** cada chamada MCP carrega overhead de round-trip e a definição do schema da ferramenta na janela de contexto. O accessibility-tree produzido por `take_snapshot` gera 2–5KB por página.

**gsd-browser:** é chamado via `Bash` — não adiciona ferramentas ao contexto visível do modelo. O output (`--json`) é compacto e estruturado. A definição das ferramentas MCP do chrome-devtools não entra na janela quando o gsd-browser está no papel.

**Vantagem potencial:** eliminar o overhead de definição de ferramentas do chrome-devtools MCP da janela de contexto (estimativa estrutural: ~500–1500 tokens por sessão com o MCP ativo).

**Incerteza:** sem medição real no contexto IdeiaOS. A vantagem é arquitetural (CLI vs MCP), não medida empiricamente. Nenhum benchmark comparativo foi executado.

---

### 2. Determinismo

**chrome-devtools MCP:** seletores de elementos dependem do estado instantâneo da página. Sem sistema de refs versionadas. Interações sensíveis a timing e estado implícito de renderização.

**gsd-browser:** versioned refs (`@v1:e1`) — cada snapshot congela os refs. Re-snapshot cria nova versão, evitando colisão. Assertions via JSON de checks. `batch` para sequências atômicas. Mecanismo de determinismo explícito e documentado na API.

**Vantagem clara:** gsd-browser é arquiteturalmente mais determinístico para automação de UI. Não depende de timing implícito.

---

### 3. Esforço de instalação (binário Rust)

**Sem toolchain Rust necessária** — binário pré-compilado para darwin-arm64.

**Riscos identificados:**

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| curl/bash sem hash | script de instalação executa código remoto sem verificação de integridade | baixar binário direto do release tag + verificar hash antes de executar |
| npm/crates.io ausentes | não há pino de versão via gerenciador de pacotes; depende do GitHub Releases | aguardar publicação oficial antes de adotar |
| Versão não fixada no installer | o script `install.gsd.build/browser` sempre baixa latest | fixar release tag explicitamente |

**Mitigação recomendada (se adotar):** baixar binário `gsd-browser-darwin-arm64` diretamente do release tag específico no GitHub, verificar hash SHA-256 divulgado na release, executar somente após verificação. NUNCA via `curl | bash` sem validação.

---

### 4. Risco de churn de org

**Org:** `gsd-build` (github.com/gsd-build/gsd-browser).

**Atenção — orgs distintas:**
- `gsd-build` — org do gsd-browser (este ADR)
- `open-gsd` — org do GSD Redux (o que o IdeiaOS usa como workflow)
- `gsd-pi` — outra linha não relacionada

São organizações separadas no GitHub. A confusão de nomes é um risco real de avaliação.

**Fatores de risco:**

| Fator | Avaliação |
|-------|-----------|
| Histórico de manutenção | Desconhecido — ferramenta nova |
| Pacotes em registros públicos | Ausentes (npm/crates.io) |
| Ponto único de falha | GitHub Releases do `gsd-build` |
| Consequência de arquivamento | Quebra total da dependência |

**Nível de risco:** Médio. Org desconhecida além deste repositório; ausência de publicação em registros públicos impede pino de versão seguro.

---

## Decisão

**Adiar — condição objetiva para reavaliar:**

> Adiar a adoção do gsd-browser até que **ambas** as condições sejam satisfeitas simultaneamente:
>
> 1. **Pacotes publicados em npm ou crates.io** — permitindo pino de versão via gerenciador de pacotes e eliminando a dependência exclusiva do GitHub Releases.
> 2. **Caso real de regressão visual não detectada pelo chrome-devtools MCP** — isto é, uma situação concreta no IdeiaOS onde o `visual-diff` do gsd-browser teria capturado um problema que o loop atual não capturou.

**Fundamentação:**

- **Risco de curl/bash sem hash:** o único vetor atual de instalação apresenta risco de supply chain não mitigado adequadamente para ambiente de produção.
- **Churn de org desconhecida:** `gsd-build` não tem histórico de manutenção verificável; sem publicação em registros públicos, não há como fixar versão de forma segura.
- **Zero medição de token real:** a vantagem de custo de token é estrutural e plausível, mas não medida no contexto IdeiaOS. Adotar com base em estimativa não é suficiente para justificar substituição de motor funcionando.
- **chrome-devtools MCP é suficiente para o caso atual:** o loop de 3 iterações da `frontend-visual-loop` funciona sem `visual-diff` programático; o upgrade seria incremental, não crítico.

---

## Como ativar o piloto (se Adotar no futuro)

Quando as condições acima forem satisfeitas, o fluxo de ativação é exclusivo de `@devops`:

1. Baixar binário `gsd-browser-darwin-arm64` diretamente do release tag específico no GitHub (`gsd-build/gsd-browser/releases/tag/vX.Y.Z`). NÃO usar `curl -fsSL https://install.gsd.build/browser | bash` sem verificação de hash.
2. Verificar hash SHA-256 do binário contra o digest publicado na release antes de qualquer execução.
3. Criar `gsd-browser.toml` na raiz do projeto-alvo:
   ```toml
   headless = true
   [artifacts]
   dir = ".gsd-browser-artifacts"  # adicionar ao .gitignore
   ```
4. Adaptar `source/skills/frontend-visual-loop/SKILL.md`: adicionar bloco "Motor alternativo (gsd-browser)" condicionado à presença do binário, sem remover o bloco do chrome-devtools MCP.
5. Rodar um loop visual real num componente do IdeiaOS e comparar saída vs. chrome-devtools MCP para o mesmo componente e mesma URL.
6. Registrar resultado como atualização deste ADR (seção "Resultado do piloto real").

---

## Fora do Escopo deste ADR

- Instalação real de qualquer binário nesta fase
- Troca do motor das skills `frontend-visual-loop` ou `web-quality`
- Avaliação do gsd-browser fora do contexto de skills visuais do IdeiaOS
- Comparação com Playwright MCP (coberta separadamente na skill)
