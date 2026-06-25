# `.env` para dev novo — templates mínimos (least-privilege)

> Os `.env` são **gitignored** (não vêm no `git clone`) e contêm segredos. Este doc dá o
> **template mínimo por projeto** para um **dev-consumidor** (roda o frontend/app + IA). Os
> **valores** são preenchidos pelo dono do projeto e entregues por **canal seguro** — nunca por
> chat/e-mail em texto plano.
>
> **Princípio (least-privilege, OWASP Excessive Agency):** dê ao dev só o que a tarefa exige.
> Chaves de alto risco (`SERVICE_ROLE_KEY`) e tokens de deploy/automação (Vercel, Railway, GitHub,
> N8N, ClickUp) **não** entram no `.env` de um dev de frontend.

## Suposição

O dev é **consumidor de frontend/app**. Se ele for rodar **edge functions / scripts admin**
localmente, aí sim adicione `SUPABASE_SERVICE_ROLE_KEY` (e só esse, sob demanda). Se for usar o
gateway do ideiapartner, adicione `OPS_DB_GATEWAY_TOKEN`.

## Como entregar com segurança

- ❌ **Nunca** por WhatsApp/Slack/e-mail/chat em texto plano (fica cacheado/indexado).
- ✅ **Gerenciador de senhas compartilhado** (1Password / Bitwarden — item ou Secure Note).
- ✅ Ou **secret-share efêmero** (ex.: onetimesecret.com — link que se autodestrói após 1 leitura).
- O dev **cria o arquivo dentro do WSL** (não no disco Windows):
  ```bash
  cd ~/dev/<projeto>
  nano .env          # cola o conteúdo, Ctrl+O salva, Ctrl+X sai
  ```
- **Nunca commitar** o `.env` (o `.gitignore` já cobre — confira `git status` não o mostra).

---

## Atalho — gerar os blocos automaticamente (com valores)

Em vez de abrir cada `.env` à mão, rode **na sua máquina** (Mac/Linux) o script que extrai só as
chaves mínimas de cada projeto, já com os valores:

```bash
bash ~/dev/IdeiaOS/scripts/export-env-dev.sh              # todos os projetos
bash ~/dev/IdeiaOS/scripts/export-env-dev.sh nfideia      # só um projeto
bash ~/dev/IdeiaOS/scripts/export-env-dev.sh --keys-only  # só os nomes (sem valores)
bash ~/dev/IdeiaOS/scripts/export-env-dev.sh --list       # projetos configurados
```
> ⚠️ O output contém **segredos reais** — copie e entregue por **canal seguro**; **nunca** cole em
> chat/e-mail/IA. **Estender** (novo projeto): edite o array `PROJECTS` no topo do script (1 linha).

## Templates manuais (se preferir montar à mão — preencha os valores)

### lapidai — `.env` (só Supabase, tudo público)
```dotenv
# Supabase (anon/publishable — pública por natureza, vai pro browser)
VITE_SUPABASE_URL=
VITE_SUPABASE_PROJECT_ID=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

### ideiapartner — `.env`
```dotenv
# Frontend (Vite — público)
VITE_SUPABASE_URL=
VITE_SUPABASE_PROJECT_ID=
VITE_SUPABASE_PUBLISHABLE_KEY=
# Backend cliente (anon — RLS aplicada)
SUPABASE_URL=
SUPABASE_ANON_KEY=
# OMITIDO (least-privilege): SUPABASE_SERVICE_ROLE_KEY (só edge functions admin)
# OMITIDO: OPS_DB_GATEWAY_TOKEN (só se for usar o gateway)
```

### nfideia — `.env`
```dotenv
NODE_ENV=development
AIOX_VERSION=                 # não é segredo (versão) — copie do .env.example

# Supabase (anon — RLS aplicada; NÃO o service_role)
SUPABASE_URL=
SUPABASE_ANON_KEY=

# LLM principal (o que o dev vai usar localmente)
OPENROUTER_API_KEY=

# Opcionais — só se ele for usar diretamente:
# ANTHROPIC_API_KEY=
# OPENAI_API_KEY=
# DEEPSEEK_API_KEY=
# EXA_API_KEY=
# CONTEXT7_API_KEY=
# SENTRY_DSN=

# OMITIDO (operacional/deploy — dev de app NÃO precisa):
#   SUPABASE_SERVICE_ROLE_KEY · GITHUB_TOKEN · VERCEL_TOKEN · RAILWAY_TOKEN
#   N8N_API_KEY · N8N_WEBHOOK_URL · CLICKUP_API_KEY
```

> Referência das chaves de cada projeto: o `.env.example` versionado em cada repo
> (`~/dev/<projeto>/.env.example`) — lista todas as variáveis que o projeto suporta. Este doc é o
> **subconjunto mínimo de dev**.
