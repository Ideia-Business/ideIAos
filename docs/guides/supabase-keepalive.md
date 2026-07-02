# Runbook — Keep-alive dos bancos Supabase do IdeiaOS

**Problema:** projetos Supabase no **free-tier pausam após 7 dias sem atividade** de API/banco.
Enquanto o Cockpit ainda não roda diariamente, os bancos internos do IdeiaOS ficam ociosos e
pausam sozinhos (o `IdeiaOS - Cockpit` já pausou uma vez). Um projeto pausado não responde à
API; após **90 dias** pausado ele não é mais restaurável (só sobra download dos dados).

**Solução:** um cron na nuvem (GitHub Actions) que bate uma query REST leve em cada projeto todo
dia — mantém ativo, custo zero, sem depender de nenhuma máquina local ligada.

## Bancos cobertos (org `tflylcjdmjctdzhwzbcm`)

| Label | Ref | Papel |
|-------|-----|-------|
| `stepup` | `xdikjgpkiqzgebcjgqmu` | Backend step-up v14.4 (pins/enrollment) |
| `view` | `ysttvskswqsvtdftjhfn` | Plano de View / P3 (motor v16) |

> O `NFIdeia` (`pdljyfyyxufkqejncccv`) é **produto** (outra org), mantido ativo pelo uso real —
> fora deste keep-alive de propósito.

## Peças

- `.github/workflows/supabase-keepalive.yml` — o cron diário (12:17 UTC) + `workflow_dispatch`.
- `supabase/keepalive.sql` — cria `public.keepalive` (SELECT anon), o alvo da query. Idempotente.
- Secret `SUPABASE_KEEPALIVE_TARGETS` — os alvos (URL + anon key). **Nunca** no repo.

---

## Setup (uma vez)

### 0. Despausar o que já pausou (dono, dashboard)
`IdeiaOS - Cockpit` (`xdikjgpkiqzgebcjgqmu`) está pausado. Dashboard → projeto → **Restore/Unpause**.
O keep-alive só age em projeto **ativo**.

### 1. Aplicar o `keepalive.sql` em CADA projeto
Dashboard → **SQL Editor** → cola o conteúdo de `supabase/keepalive.sql` → **Run**. Repetir nos dois.
(Alternativa CLI: `supabase link --project-ref <ref> && supabase db execute --file supabase/keepalive.sql`.)

### 2. Criar o secret `SUPABASE_KEEPALIVE_TARGETS`
GitHub → repo `Ideia-Business/ideIAos` → **Settings → Secrets and variables → Actions → New repository secret**.

- **Name:** `SUPABASE_KEEPALIVE_TARGETS`
- **Value** (uma linha por projeto — `LABEL|URL|ANON_KEY`):

```
stepup|https://xdikjgpkiqzgebcjgqmu.supabase.co|<ANON_KEY_DO_STEPUP>
view|https://ysttvskswqsvtdftjhfn.supabase.co|<ANON_KEY_DO_VIEW>
```

**Onde pegar a anon key:** Dashboard do projeto → **Project Settings → API** → *Project API keys* →
`anon` `public`. Use **sempre a anon** (menor privilégio); **nunca** a `service_role`.

### 3. Verificar (prova por exit-code)
GitHub → **Actions → supabase-keepalive → Run workflow** (`workflow_dispatch`). Run verde + log
`✅ stepup — HTTP 200` / `✅ view — HTTP 200` = funcionando. HTTP ≠ 200 → projeto pausado, key
errada, ou `keepalive.sql` não aplicado (a própria mensagem de erro aponta as causas).

---

## Manutenção

- **Adicionar/remover um banco:** edite só o secret `SUPABASE_KEEPALIVE_TARGETS` (uma linha por
  projeto). O workflow não muda. Lembre de aplicar o `keepalive.sql` no projeto novo.
- **Rotacionar a anon key:** atualize a linha no secret. Nada mais.
- **Migrar para Pro:** se um banco virar uso crítico/diário, o upgrade Pro (~$25/mês/projeto)
  dispensa o keep-alive e traz backups — aí é só remover a linha dele do secret.
- **Se pausar mesmo assim:** despausar (passo 0), confirmar que o `keepalive.sql` foi aplicado, e
  rodar o `workflow_dispatch`. A Supabase avisa por e-mail antes/na pausa.

## Disciplinas

- **credential-isolation** — a anon key vive só no GitHub Secret; nunca no repo, nunca em log
  (o GitHub mascara), nunca no contexto de nenhum agente.
- **least-privilege / Excessive Agency** — anon key + só `SELECT` numa tabela de um timestamp
  trivial. O cron não escreve, não lê dado sensível, não usa `service_role`.
- **CLI-First** — `curl` puro no runner, sem MCP.
