# 78 — Estratégia de Testes & Verificação · IdeiaOS Cockpit (v14.0–v14.3)

> **Documento 78 · QA / Test Architect · ESTRATÉGIA consolidada**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Consome (lido do disco):** `00-BLUEPRINT.md` §5/§8/§9, `01-ROADMAP.md` (critérios de PRONTO por fase), `02-PHASE-1-SPEC.md` §5 (A1–A11), `72-phase-v14_0-buildable.md` (tarefas `N.M`), `73-substrate-validation-mac-mini.md` (fatos reais), `.claude/rules/ideiaos-common-antifragile-gates.md`, `source/lib/gates.sh`.
> **Disciplina-piso:** `antifragile-gates`. **Dois regimes:** artefato-de-arquivo (`test -s`/exit-code é **lei**, NUNCA o Read tool) e estado-de-runtime/UI (render + screenshot + critério explícito, `frontend-visual-loop`). Onde existe exit-code, ele manda.

---

## 0. Princípio-mestre — onde há exit-code, ele é lei

Toda asserção desta estratégia é **binária e não-alucinável**: ou um `test -s`/exit-code de script/build/teste, ou — só quando NÃO há exit-code (UI viva) — um screenshot com **critério explícito declarado** (nunca "parece certo"). O gate central do produto (Zero-Leak) é exit-code; o North-Star (TtT) é cronômetro com N≥5; a UI é o único regime-2.

Helper único de gate de arquivo: `source/lib/gates.sh` (`assert_nonempty`/`gate_output`/`require_file`, todos `test -s` bash 3.2, sem jq/python). Hooks saem `exit 0` em falha; scripts de build/teste saem `exit 1`. Mínimo 3 gate-points por script de I/O.

---

## 1. Teste de invariante ZERO-LEAK — o gate de release (P0)

**Tese:** a Bridge é um plano de leitura sobre cofres que ela nunca abre. Um único **valor** de segredo em **qualquer** superfície é incidente P0 e **bloqueia o merge** — gate, não advisory (`00-BLUEPRINT` §5). O browser é ambiente não-confiável, equivalente ao contexto do LLM (`credential-isolation`).

### 1.1 As 7 superfícies varridas (cada uma exit-code)

| # | Superfície | Como obter o texto a varrer (sem alucinar) | Instrumento |
|---|-----------|---------------------------------------------|-------------|
| S1 | **snapshot do ref** (`snapshots/<MID>.json`) | `git show cockpit:snapshots/$MID.json` → stdin do scanner | artefato (`72` tarefa 3.4) |
| S2 | **read-model.db** | `sqlite3 read-model.db '.dump'` → stdin do scanner | artefato |
| S3 | **schema do read-model** | `sqlite3 read-model.db 'PRAGMA table_info(api_key)'` → assert SEM coluna `value` | artefato (`72` tarefa 4.2) |
| S4 | **estado React serializado** | dump do store/props para JSON via `preview_eval`/build-time fixture | runtime→artefato |
| S5 | **DOM renderizado** | `get_page_text` + `outerHTML` capturado para arquivo, depois varrido | runtime→artefato |
| S6 | **tráfego de rede** | `read_network_requests` (loopback) → corpo das respostas para arquivo | runtime→artefato |
| S7 | **logs** (`console-audit.log`, stdout do agentd, console do browser) | concatenar para arquivo, varrer | artefato |

> **Truque de determinismo:** as superfícies de runtime (S4–S6) são **materializadas em arquivo** primeiro (dump→file), e SÓ ENTÃO varridas por exit-code. Isso traz S4–S6 do regime-2 para o regime-1 — o veredito final do Zero-Leak é sempre `test`/exit-code, nunca interpretação de screenshot. O screenshot prova que a tela renderizou; o `grep -E` sobre o dump prova que não vazou.

### 1.2 O detector — regex de chaves conhecidas + entropia

Duas camadas, ambas exit-code (0 matches = pass):

**(a) Padrões literais de chaves reais (do doc 73 §5, fixture real):**
```
sk-[A-Za-z0-9]{20,}          # Anthropic/OpenAI/DeepSeek/OpenRouter
sk-ant-[A-Za-z0-9-]{20,}     # Anthropic explícito
gh[pousr]_[A-Za-z0-9]{36,}   # GitHub token (gho_, ghp_, ghs_…)
eyJ[A-Za-z0-9_-]{20,}\.eyJ   # JWT (service_role/anon têm header eyJ…)
xoxb-|xoxp-                   # Slack
[A-Za-z0-9+/]{40,}={0,2}      # base64 longo (RAILWAY/VERCEL/RESEND/N8N)
```
**(b) Entropia de Shannon por token:** qualquer string ≥20 chars com entropia ≥4.0 bits/char que NÃO esteja numa allowlist de nomes-de-var/hashes-conhecidos → suspeita. Captura chaves novas que a regex (a) ainda não conhece.

**Anti-falso-positivo (crítico para o gate não virar ruído):** a allowlist exclui o que é **legitimamente** alto-entropia e público: `machine_id` (sha256 de hardware-uuid, doc 73 §1), SHAs de commit, `supabase_project_id` público (doc 73 §6), `input_hash` de handoffs, hashes do audit-log encadeado. Sem essa allowlist, o detector reprovaria o próprio snapshot legítimo. **A allowlist é por NOME/forma, nunca por valor** — não se exclui "este valor específico", exclui-se "campo `machine_id` é sha256 esperado".

### 1.3 Prova positiva de que `ApiKey` nunca tem `value` (não só "não encontrei")

Zero-Leak tem duas naturezas: **negativa** (varredura — "não achei segredo") e **positiva** (estrutural — "é impossível haver segredo"). A positiva é mais forte:

```bash
# Guard estrutural — falha se ALGUÉM adicionar a coluna value (72 tarefa 4.2)
sqlite3 /tmp/t.db 'PRAGMA table_info(api_key)' | awk -F'|' '{print $2}' | grep -qix value \
  && { echo "P0: coluna value existe no api_key"; exit 1; } || exit 0
```
Mais o guard no collector (`72` tarefa 3.1): `node -e '...k.every(x=>!("value" in x))...'` — nenhum objeto de credencial tem a chave `value`. A varredura (1.2) é a **rede de segurança**; o guard estrutural (esquema sem coluna + objeto sem chave) é a **prova primária**. Os dois juntos = defesa em profundidade.

### 1.4 O que reprova o build (P0)

`npm run test:zeroleak` → **exit ≠ 0 bloqueia o merge** se: (i) ≥1 match em qualquer S1–S7; OU (ii) coluna `value` existe em `api_key`; OU (iii) algum objeto-credencial tem chave `value`. Regra de bolso (`BLUEPRINT` §5): **se o valor de um segredo pode aparecer num screenshot, o design está errado** — então o teste roda um screenshot da tela Cofre-Espelho e varre o OCR/DOM-dump dela também (S5).

> **Teste do próprio teste (dogfood — evita gate cego):** uma fixture-veneno com um `sk-ant-FAKEKEY...` plantado num snapshot de `/tmp` DEVE fazer `test:zeroleak` sair ≠0. Se o detector não pega o veneno conhecido, o gate é teatro. Assert: `zeroleak <(poison) ; test $? -ne 0`. (Cf. learning `fixture-precreation-masks-bootstrap-bugs` e `dogfood-review-tool-catches-own-defect`.)

---

## 2. Harness de TtT — protocolo cronômetro (North-Star mensurável)

`TtT < 10s` e `Trust Rate 100%` deixam de ser não-falsificáveis via protocolo cravado (`BLUEPRINT` §8, `72` grupo 5).

### 2.1 As 3 jornadas (literais)

- **J1 — "a frota está saudável?"** → cada máquina, último heartbeat, doctor PASS/FAIL, daemons vivos.
- **J4 — "a chave X existe e qual a idade?"** → `present`, `risk_tier`, `age_days` (de `file_mtime_epoch`) — **nunca o valor**.
- **J2 — "está pronto para tag?"** → `soak_satisfied` (≥2 máquinas, span≥1d **sobre epochs gravados**, não wall-clock — `soak-span-is-record-delta-not-wallclock`) + idea-doctor verde + security re-selado.

### 2.2 Protocolo de medição

| Etapa | Quando | Como | Saída (artefato) |
|-------|--------|------|------------------|
| **Baseline** | v14.0, ANTES da Bridge | mesma pergunta respondida via terminal (greps/awk/launchctl manuais), cronometrada `date +%s.%N` | `ttt-baseline.tsv`: `jornada\tmodo=terminal\tsegundos\tepoch` |
| **N≥5** | v14.0 | repetir cada jornada ≥5× | `awk -F'\t' '$1=="J1"' …\| wc -l` ≥ 5 (3 asserts, exit 0) |
| **Mediana** | v14.0 | `ttt-median.sh` (sort + linha do meio, bash puro) | 3 linhas `^J[124]\s+[0-9.]+` |
| **Pós-Bridge** | v14.1 | MESMAS 3 jornadas na UI, MESMO cronômetro, N≥5 | meta: mediana < 10s |

**Gate de mediana (exit-code, não olhômetro):** `ttt-median.sh --mode=bridge | awk '$2>=10{f=1} END{exit f}'` — sai ≠0 se qualquer jornada ≥10s. A comparação baseline-vs-bridge é o que torna o North-Star uma **melhoria provada**, não um número assumido.

### 2.3 Trust-Rate — verify-against-disk (não contra cache)

O perigo é medir confiança contra o snapshot em cache (que pode estar stale). O modo `--verify` recomputa do **disco-agora** no instante da pergunta:
```bash
# célula da Bridge vs disco-agora, por igualdade exata
BRIDGE_VAL=$(curl -sf http://127.0.0.1:PORT/api/verify?cell=J4.SUPABASE_SERVICE_ROLE_KEY.age_days)
DISK_VAL=$(git show cockpit:snapshots/$MID.json | python3 -c '...age_days...')
test "$BRIDGE_VAL" = "$DISK_VAL"   # exit 0 = trust; ≠0 = stale flagrado
```
Trust Rate = (amostras onde Bridge==disco) / (total). Meta 100% sobre o **disco-agora** (A6 da spec). A UI exibe "verificado há Xs"; divergência é sinalizada como stale, nunca silenciada.

---

## 3. Testes do LEDGER de contenção (v14.2)

**Formato (pipe-delimited, irmão do SOAK `.planning/soak/*.log` e do security `.security/review-ledger.log`):** `epoch|iso|produto|deny_count|total|commit`. Append-only, uma linha por amostra do watch (o watch **grava cada amostra**, não só sinaliza). Pré-requisito do Time-Travel da v14.3 (`01-ROADMAP` v14.2).

| Teste | Asserção (exit-code) |
|-------|----------------------|
| **T-LED-1 · formato válido** | toda linha tem 6 campos: `awk -F'\|' 'NF!=6{exit 1}' ledger` exit 0 |
| **T-LED-2 · tipos por campo** | `epoch`=inteiro, `deny_count`/`total`=inteiro, `deny_count`≤`total`: `awk -F'\|' '$1!~/^[0-9]+$/||$4>$5{exit 1}'` |
| **T-LED-3 · append-only (nunca reescreve)** | sha256 das N primeiras linhas é **estável** após nova amostra: grava sha do prefixo, adiciona linha, re-confere prefixo idêntico. `head -n$N old\|shasum` == `head -n$N new\|shasum` |
| **T-LED-4 · idempotência por amostra** | regressão simulada idêntica no mesmo epoch/commit não duplica linha (chave = `epoch+produto+commit`): `sort -u` == `wc -l` original |
| **T-LED-5 · regressão produz linha real** | injetar deny 5/5→2/5 num produto-fixture → exatamente 1 linha nova `…|produto|2|5|<sha>` aparece. `test -s` + `grep -cE '\|2\|5\|'` == 1 |
| **T-LED-6 · sem NL** | o parser do Time-Travel lê SÓ os campos pipe — `grep -v` de qualquer prosa; nenhuma linha derivada de mensagem de commit em texto livre |

> **Por que append-only por sha-prefixo e não por `wc -l`:** contar linhas não pega uma reescrita que mantém a contagem (edição in-place de uma linha antiga). O sha do prefixo imutável é o que prova **append**, não só "cresceu" (cf. `01-ROADMAP` "verificável por `test -s` + parse pipe-delimited, sem NL").

---

## 4. Não-regressão ANSI do `idea-doctor --json` (gate duro — C3)

**O risco-mor (doc 73 §2, doc 72 grupo 1):** ligar `--json` num script vivo de ~593 linhas que **É** o gate de saúde do OS, sem mudar **1 byte** da saída humana ANSI. A abordagem é decorar os 5 emissores (`pass/warn/fail/info/step`) para acumular em buffer **além** do `echo` atual — o sink final decide ANSI-vs-JSON.

| Teste | Asserção (exit-code) |
|-------|----------------------|
| **T-ANSI-1 · diff ANSI-stripped (gate central)** | capturar baseline ANTES das mudanças; depois: `diff <(sed 's/\x1b\[[0-9;]*m//g' baseline) <(sed 's/…//g' after)` **exit 0** — texto sem ANSI-codes **idêntico** (`72` tarefa 1.4) |
| **T-ANSI-2 · exit-code preservado** | `bash idea-doctor.sh; echo $?` == baseline exit-code (sem-flag continua igual) |
| **T-ANSI-3 · JSON parseável** | `idea-doctor.sh --json \| python3 -c 'json.load; assert schema=="ideiaos-doctor/v1"; assert len(sections)>=14'` exit 0 |
| **T-ANSI-4 · concordância JSON↔ANSI** | `summary.ok` do JSON == número da linha `OK: N` do ANSI (`72` tarefa 1.5) — as duas vozes contam o mesmo |
| **T-ANSI-5 · §15 presente** | `idea-doctor --json \| python3 -c '…section id==15…'` mostra o self-monitoring do console |

> **Por que diff ANSI-stripped e não diff cru:** os `echo` ANSI já acontecem inline; a mudança é **aditiva** (buffer paralelo). O diff stripped prova que o *conteúdo* humano é idêntico isolando os escape-codes de cor (que poderiam mudar por reflow sem mudar a informação). Este é o teste que **destrava** o `--json` — sem ele, a Frota não pode depender do JSON.

---

## 5. Não-vazamento do ref — working tree limpo após o collector (A4)

**Invariante estrutural (`BLUEPRINT` §4 decisão 2, `02-SPEC` A4):** o snapshot é escrito DENTRO de `refs/heads/cockpit` por git-plumbing (`hash-object`→`mktree`→`commit-tree`→`update-ref`) e **nunca** materializa como arquivo no working tree — então o `git add -A` cego do autosync (verificado, `72` linha 22) **não tem o que capturar**.

| Teste | Asserção (exit-code) |
|-------|----------------------|
| **T-REF-1 · working tree limpo** | após `cockpit_write_snapshot` em repo /tmp: `[ -z "$(git status --porcelain)" ]` exit 0; **falha** se QUALQUER arquivo untracked aparecer (`72` tarefa 2.2) |
| **T-REF-2 · ref existe e é não-vazio** | `git rev-parse --verify cockpit` exit 0 **E** `git show cockpit:snapshots/$MID.json \| git hash-object --stdin` (blob não-vazio via `test -s` de `git cat-file -s`) |
| **T-REF-3 · preserva outras máquinas** | gravar MID_A, depois MID_B → `git ls-tree --name-only cockpit snapshots/ \| wc -l` == 2 (`72` tarefa 2.3) |
| **T-REF-4 · substitui, não duplica** | re-gravar MID_A → `git ls-tree cockpit snapshots/ \| grep -c "${MID_A}.json"` == 1 (`72` tarefa 2.4) |
| **T-REF-5 · autosync espelha push** | `grep -c 'push_cockpit_ref' ~/.local/bin/git-autosync` == 3 (1 def + 2 chamadas) **E** `bash -n` exit 0 |

> **Sandbox obrigatório (learning `verify-guards-in-sandbox-not-live-repo` + `autosync-races-ai-git-surgery`):** T-REF-* roda num `git init` fresco em `/tmp`, NUNCA no repo vivo — testar com stash+checkout no repo real dá falso resultado se o checkout falhar em silêncio, e o autosync pode capturar a janela. O collector deve rodar com autosync **pausado** durante o teste.

---

## 6. Mapeamento por fase — cada critério de PRONTO → o teste que o prova

Regime: **F**=artefato-de-arquivo (`test -s`/exit-code, lei); **R**=runtime/UI (render+critério explícito, `frontend-visual-loop`).

### v14.0 — Substrato + Espinha
| Critério de PRONTO (`01-ROADMAP`/`72`) | Teste | Regime |
|----------------------------------------|-------|--------|
| `idea-doctor --json` válido OU fallback ANSI | T-ANSI-1..4 (§4) | F |
| `git show cockpit:snapshots/<MID>.json` não-vazio | T-REF-2 (§5) | F |
| working tree limpo após collector | T-REF-1 (§5) | F |
| `console-ingest` reconstrói do zero (`rm db && rebuild`) | `rm db && node ingest.js && test -s db` (`72` tarefa 4.4) | F |
| `idea-doctor §15` reporta estado do console | T-ANSI-5 (§4) | F |
| snapshot sem valor de segredo | Zero-Leak S1 (§1) + guards estruturais (`72` 3.1/3.4) | F |
| baseline TtT terminal medido (N≥5, mediana) | harness §2.2 | F |
| scaffold SPA builda e serve loopback | `npm run build` + `curl -sf 127.0.0.1` (`72` 6.1/6.2) | F |
| 1 card de máquina renderiza | screenshot, critério "card mostra machine_id + last_doctor" (`72` 6.3) | **R** |

### v14.1 — MVP Bridge (read-only + comando local) · gate A1–A11
| Critério (A#) | Teste | Regime |
|---------------|-------|--------|
| A1 baseline TtT | harness §2.2 (terminal) | F |
| A2 TtT < 10s na Bridge | gate-mediana §2.2 | F (cronômetro) |
| A3 Zero-Leak = 0 | `npm run test:zeroleak` §1.4 (7 superfícies + dogfood-veneno) | F |
| A4 working tree limpo | T-REF-1 §5 | F |
| A5 read-model reconstruível | `rm db && ingest && test -s db` | F |
| A6 Trust Rate 100% vs disco | verify-against-disk §2.3 | F |
| A7 ⌘K executa 3 verbos locais | resultado inline de `autosync-pause`/`idea-doctor`/`security --record` | **R** + exit-code do verbo |
| A8 mutação de produção ausente | `grep -E 'rotate\|deploy\|revoke\|git push\|gh pr'` na allowlist → 0 (`72` 0.4) | F |
| A9 `idea-doctor §15` audita console | T-ANSI-5 | F |
| A10 WCAG 2.1 AA | contraste/teclado/cor-não-única/`prefers-reduced-motion` | **R** (critérios explícitos) |
| A11 gate de fechamento padrão | SOAK 2 máq span≥1d · doctor verde · security re-selado · README · vault | F |

> **Cofre-Espelho (cenário /spec):** "nenhum controle de UI lê/copia/escreve/rotaciona valor" → regime-R com critério explícito: snapshot da tela + assert de DOM (`72` 4.2 schema sem `value`). A ausência de botão é verificável por inspeção do a11y-tree (nenhum elemento com ação de mutação de credencial).

### v14.2 — Pilares completos
| Critério | Teste | Regime |
|----------|-------|--------|
| deny-list watch GRAVA no ledger (não só detecta) | T-LED-1..6 (§3) | F |
| Pulso bate com `git log` filtrado | classificação de ator determinística (`@*.local$`/`^wip: autosync`→autosync) vs `git log` (`72` 4.5) | F |
| Atalaia dispara ≥1 alerta real | injetar drift/regressão fixture → alerta aparece | F (gatilho) + R (render) |
| 5 pilares navegáveis | screenshot por pilar, critério "renderiza dado real do substrato" | **R** |

### v14.3 — Inteligência (Wave 2)
| Critério | Teste | Regime |
|----------|-------|--------|
| Time-Travel reconstrói estado passado **verificável contra ledger** | reconstruir incidente deny 5/5→2/5 e diff contra o ledger §3 (exit-code, sem NL) | F |
| Copiloto responde J1/J4 com SHA/linha exata, **zero** acesso a valor | resposta contém SHA real (grep) + Zero-Leak na resposta do Copiloto (S4/S7) | F |
| teste de injection não desvia roteamento | commit-msg adversarial envelopado como DADO (anti-injection `handoff-packet`) → roteamento inalterado | F |
| Token-Cost rotula estimativas | grep por label "estimativa" onde não há campo nativo | F |

---

## 7. Pirâmide e disciplina de execução

- **Base (rápida, exit-code):** unit dos readers do collector (cada fonte→objeto), guards estruturais (schema sem `value`), parsers de ledger/JSON. Rodam em milissegundos, em sandbox /tmp.
- **Meio:** integração ref↔ingest↔read-model (sandbox git fresco), idempotência (rodar 2× = mesmo DB).
- **Topo (caro, regime-R):** TtT na Bridge, WCAG, render dos pilares — só o que **não tem** exit-code.

**Regras transversais:** (1) todo teste de git roda em `/tmp` com autosync pausado; (2) toda fonte externa (commit msg, tool-description MCP) entra envelopada como DADO no Copiloto; (3) `version-reset-migration-semver-trap` — `gsd` por string-equality, nunca semver; (4) fixtures NÃO pré-criam o alvo de bootstrap (`fixture-precreation-masks-bootstrap-bugs`); (5) o Zero-Leak roda também sobre os artefatos que o próprio console cria (audit-log, ref) — dogfood.

---

*Documento 78 — PROPOSTO. Zero código. Verificação por exit-code em cada asserção (`antifragile-gates`); regime-R só onde não há exit-code, sempre com critério explícito.*
