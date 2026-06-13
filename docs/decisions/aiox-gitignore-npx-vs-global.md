# ADR — AIOX Core: instalação por-máquina (gitignore + npx), instrução global

**Data:** 2026-06-13
**Status:** Aceito
**Contexto:** padronização do AIOX nos 4 repos (ideiapartner, nfideia, lapidai, cfoai-grupori)

## Contexto

O "AIOX" tem **duas camadas** com naturezas diferentes:

1. **Camada de instrução** — orquestrador `/idea` (Deia), suíte GSD (67 skills) e as **personas** AIOX (`@dev`, `@qa`, `@architect`, `@aiox-master`, etc.). São markdown/skills **stateless**: zero código, zero dependências, zero estado de projeto. O Claude as lê **globalmente** (`~/.claude/skills`, plugins) e aplica ao projeto aberto.
2. **Engine `.aiox-core`** — o pacote npm `@aiox-squads/core-internal` (v5.2.x). Tem **código executável + ~43M de `node_modules` próprios** E **estado/config específicos do projeto** (`core-config.yaml`, `.aiox-ai-config.yaml`, `data/` com stories/squads, `manifests/`, `product/`). `package.json` tem `bin: []` → **não é uma CLI global**; é um *scaffold* que se instala dentro de um projeto.

### Problema observado (drift)

Sem um padrão escrito, os 4 repos divergiram:
- cfoai-grupori / lapidai: `.aiox-core` (14M) **commitado** (ignoravam só `.aiox-core/local/`).
- nfideia: `.aiox-core/` **gitignorado** (ausente).
- ideiapartner: **esqueleto quebrado** de 20K commitado (importava módulos inexistentes).

## Decisão

1. **Instrução = global.** GSD, `/idea` (Deia) e personas AIOX ficam instalados uma vez em `~/.claude` / `~/.cursor` e valem para todos os projetos. **Orquestrador oficial = `/idea` (Deia) + IdeiaOS.**
2. **Engine = por-máquina, gitignored.** `.aiox-core/` é tratado como `node_modules`: instalado por máquina via `npx aiox-core@latest install` e **NUNCA versionado**. Idem os artefatos multi-IDE que o instalador gera: `.antigravity/ .codex/ .gemini/ .kimi/ .cursor/rules/agents/ .github/agents/`.
3. **Fresh clone / máquina nova:** rodar `npx aiox-core@latest install` no projeto para regenerar o `.aiox-core` (a instrução global já funciona sem isso).

## Por que NÃO global o `.aiox-core`

- Carrega **estado por-projeto** (stories/squads/config) — uma cópia global misturaria todos os projetos.
- É **scaffold sem `bin`** — não foi feito para `npm i -g` como ferramenta.
- Hoje o engine está **dormente** nos projetos (eles rodam em GSD + personas globais + Lovable); não compensa re-arquitetar o pacote upstream para forçá-lo a ser global.

## Consequências

- Repos ficam **leves** (sem 14-58M de código vendido versionado).
- Clone novo precisa de `npx aiox-core@latest install` (documentado no output do `setup.sh`).
- Padrão **encodado no instalador**: `setup.sh` adiciona `.aiox-core/` + dirs IDE ao `.gitignore` de todo projeto (loop de proteções essenciais) — previne a recorrência do drift.

## Implementação

- `setup.sh`: `.aiox-core/` + dirs multi-IDE no loop de `.gitignore` essencial; nota no output do install AIOX sobre `npx` em clone novo.
- Aplicado retroativamente nos 4 repos (2026-06-13): `.aiox-core` completo local (v5.2.9) + gitignored; tracking antigo removido (`git rm --cached`).
