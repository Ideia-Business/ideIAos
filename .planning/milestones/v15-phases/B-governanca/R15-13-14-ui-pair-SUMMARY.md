# R15-13 + R15-14 — Flight Recorder 1ª-classe + Card Saúde & Governança · SUMMARY

**Status:** ✅ DONE 2026-06-26 · **Wave:** 1 · **Executor:** sessão principal (UI dedicada)
**Veredito:** pass — par de UI que consome os GET do R15-12. **Fecha a Fase B (8/8).**
**Regime de verificação:** **R (runtime/UI)** — render + screenshot + a11y/network, além de
exit-code (tsc, build, test-recorder).

## R15-13 — Flight Recorder a peça de 1ª-classe

Delta (o requisito disse "já montado, elevar de rodapé a 1ª-classe + microcopy"):
- **Posição:** movido do rodapé do `Overview.tsx` para **logo após o System Pulse hero** — a peça
  narrativa central (replay determinístico) deixa de ser o último elemento.
- **Microcopy LAW vs INTERPRETED agora VISÍVEL ao usuário** (antes vivia só em comentário de código):
  parágrafo no header do `FlightRecorder.tsx` — "a fita desenha só o que o git **prova** — LAW
  (pin/ordem/reversão, por exit-code); a narrativa aparece só no nó selecionado, rotulada
  INTERPRETAÇÃO, nunca asserida como fato".
- **Filtro por máquina/projeto DIFERIDO** (o requisito o nomeou como o único vetor de super-construção).
- **`test-recorder.sh` exit 0** após a mudança de UI: o gate compara o SET `{hash8|gsd}` do
  `flight-recorder.json` vs git — **não inspeciona o `.tsx`**, então a mudança de UI não pode
  divergir a fita (13 nós, 3 reversões âmbar; confirmado).

## R15-14 — Card "Saúde & Governança" servido por GET read-only

- **Card consolidado** no `Overview.tsx`, servido por **GET read-only** (tag `GET READ-ONLY` na UI).
  **NUNCA** `POST /command`, **NUNCA** `spawnSync idea-doctor` por load, **NUNCA** `--record`.
- **3 pilares:**
  1. **Saúde** — `checks` do `GET /overview` (doctor agregado). `unknown` = `n/a` honesto (Lovable),
     nunca somado como falha.
  2. **Releases-SOAK** — consome o **`GET /soak` REAL** (span gravado = `MAX-MIN` epoch), substituindo
     o proxy `machines>=2` do card antigo. **`/soak` não era consumido por NENHUMA tela** — esse era
     o gap que o R15-12 abriu e o R15-14 fecha. Render ao vivo: `5/5 com span≥1d · 2 hosts · gate real`.
  3. **Frescor de segurança (tier)** — o "único net-new real" (coleta do `check-security-freshness
     --tier` no `collect.js`). **DIFERIDO com honestidade**: slot `aguardando coleta`, nunca um tier
     fabricado (mesma disciplina do R15-12 com `doctor.sections=[]`). Ver carry-forward abaixo.
- Cards antigos "Segurança" + "Releases-SOAK" (proxy) **consolidados** neste; "Frota" e
  "Atenção-Agora" preservados.

## Verificação

| Gate | Tipo | Resultado |
|------|------|-----------|
| `tsc -b` (type-check) | exit-code | ✅ exit 0 |
| `npm run build` (tsc + vite build) | exit-code | ✅ exit 0 — 1696 módulos |
| `test-recorder.sh` (fita íntegra pós-UI) | exit-code | ✅ exit 0 (13 nós, 3 reversões) |
| curl `/overview` `/soak` | exit-code | ✅ 200 — machines=2, 5 milestones span≥1d, 2 hosts |
| **Render (regime-R):** Flight Recorder 1ª-classe + microcopy visível | screenshot | ✅ |
| **Render (regime-R):** card Saúde & Governança 3 pilares consumindo GET | screenshot | ✅ |
| Network: `/overview` `/soak` `/fleet` | DevTools MCP | ✅ todos 200 (único 404 = `favicon.ico`, benigno/pré-existente) |
| Console: erros do código | DevTools MCP | ✅ zero (só o favicon) |

## Decisões / fronteira

- **Frescor-tier diferido (push-back informado):** entregá-lo exigiria mexer no `collect.js`/agentd
  + **re-coleta do ref `cockpit`** — exatamente o que o R15-12 evitou deliberadamente no meio do
  trabalho. O coração do R15-14 (card servido por GET consumindo dado **já-coletado**, sem spawn) é
  entregável sem ele. Slot honesto + carry-forward; não silenciado.
- **`healthVariant` "ok" com 0/2 + 2 n/a:** preserva a lógica do card "Segurança" original
  (`fail>0?…:warn>0?…:"ok"`) — consistência, não invenção. O "0/2 · 2 n/a" ao lado deixa explícito
  que não há checks positivos. Os 2 n/a preenchem quando o agentd re-coletar com o fix do `--json`.
- **Disciplina de escopo:** não adicionei favicon (404 pré-existente, fora do pedido) nem filtro de
  Flight Recorder.

## Arquivos

- `apps/cockpit/src/pages/Overview.tsx`: fetch `/soak` (best-effort), card "Saúde & Governança"
  (3 pilares GET), Flight Recorder elevado a 1ª-classe.
- `apps/cockpit/src/components/FlightRecorder.tsx`: header 1ª-classe + microcopy LAW vs INTERPRETED.

## Carry-forward (não-bloqueante p/ a fase)

- **Frescor-tier (net-new de coleta):** adicionar `check-security-freshness --tier` ao `collect.js`
  (snapshot) → ingest → expor via GET → o pilar 3 do card troca `aguardando coleta` pelo tier real.
- **2 n/a do doctor + `supabase_project_id`/`installed_versions`:** preenchem no próximo ciclo do
  agentd (re-coleta com o fix do `--json`, bugfix `f80e9c5`).
