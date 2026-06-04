# Publicação do Frontend na Lovable — e o "botão Update cinza"

> **Para qualquer IA (Claude, Cursor) ou dev que faça push neste repositório.**
> Conhecimento comum a todos os projetos hospedados na Lovable.

## TL;DR

1. **Frontend só vai a produção com Publish MANUAL** no editor da Lovable. **Push no `main` NÃO publica** — apenas sincroniza o código para o editor.
2. Se o botão **Update/Publish ficar CINZA** ("nada a publicar"), a causa típica é um **Action que reescreve `src/version.ts` a cada push** deixando um **commit de bot como `HEAD`**, que atropela o commit de publish da Lovable.
3. **Nunca afirme que algo está "em produção"** só porque viu um commit de build/rebuild ou porque a Lovable disse "sincronizei". **Confirme no bundle real** (ver abaixo).

## Quem é quem nos commits do `main`

| Autor do commit | Quem é | Significado |
|-----------------|--------|-------------|
| `gpt-engineer-app[bot]` — *"Sincronizado e rebuildado"* | **A Lovable** | Ela preparou um estado publicável. |
| `github-actions[bot]` — *"...build metadata [lovable-rebuild]"* | **Um Action** (se o projeto tiver) | Só reescreve `src/version.ts`. **Não é deploy.** |
| Seu nome / Claude / Cursor | **Você** | Código real. |

## A causa-raiz do "Update cinza"

Quando um Action roda **a cada push** e empurra um commit `github-actions[bot]` logo **depois**
do commit de publish da Lovable:

```
github-actions[bot]   — [lovable-rebuild]            ← ATROPELOU (virou HEAD)
gpt-engineer-app[bot] — Sincronizado e rebuildado    ← a Lovable ia publicar ISTO
```

Com um commit de **bot** no topo, a Lovable não gera "deploy publicável" → o botão **Update fica
cinza**, mesmo o preview já tendo o código novo.

**Correção:** manter esse Action **manual** (`on: workflow_dispatch`), e **não criar** Actions que
commitam a cada push no `main`. (No nfideia isso foi corrigido em 2026-06-04.)

## Processo de publish (passo a passo)

1. Faça as mudanças de frontend → `commit` → `push` no `main`.
2. Garanta que o **`HEAD` do `main` não seja um commit de bot**.
3. No **chat da Lovable**: peça para **sincronizar com o `main`**. Se o Update **não reativar**, peça
   uma **micro-edição real** (ex.: *"adicione um comentário `// deploy <data>` no topo de
   `src/main.tsx` e faça commit"*). Isso cria um commit `gpt-engineer-app[bot]` publicável que —
   sem o Action atropelando — vira o `HEAD` → o **Update reativa**.
4. Clique **Publish → Update** (canto superior direito).

## Como CONFIRMAR que foi a produção (obrigatório)

```bash
SITE="https://SEU-DOMINIO"   # domínio publicado na Lovable deste projeto

# 1) O bundle principal muda de hash quando rebuilda:
curl -s "$SITE/?cb=$(date +%s)" | grep -oE 'assets/index-[A-Za-z0-9_-]+\.js'
```

> ⚠️ **As strings do código novo NÃO ficam no `index` principal** — telas são *lazy-loaded* em
> **chunks separados** (`<Pagina>-<hash>.js`).
> ⚠️ **Acentos podem estar escapados** no bundle (`ó` → `ó`). **Busque por substrings ASCII.**

```bash
# 2) Baixar os chunks e procurar a string nova localmente:
CB=$(date +%s); IDX=index-XXXX.js   # hash atual (do passo 1)
curl -s "$SITE/assets/$IDX?cb=$CB" \
  | grep -oE '[A-Za-z0-9_]+-[A-Za-z0-9_-]+\.js' | sort -u > /tmp/chunks.txt
mkdir -p /tmp/dl
cat /tmp/chunks.txt | xargs -P 24 -I {} curl -s -o "/tmp/dl/{}" "$SITE/assets/{}?cb=$CB"
grep -rl "Sua string ASCII nova" /tmp/dl/
```

Se o bundle não mudou de hash / não contém a string → **ainda não publicou**: volte ao passo 3.

## Convivência multi-IA (Cursor + Claude + Lovable)

- **Não deixe um commit de bot como `HEAD` do `main`** quando o objetivo é publicar frontend.
- **Mantenha qualquer Action de rebuild manual** (não use `on: push`).
- Quem empurra frontend **avisa explicitamente** que precisa de **Publish na Lovable** (Claude/Cursor
  não conseguem clicar — é ação humana no editor).
- Edge Functions e migrations seguem a política do projeto (ver `CLAUDE.md` / `AGENTS.md`); esta
  página trata **só do frontend/publish**.
