# Instalar o ideIAos no Windows

> **Este arquivo é um ponteiro.** O passo a passo completo e único vive no repo, versionado
> junto com o ferramental que ele descreve — assim nunca sai de sincronia com os scripts.

Há **dois caminhos** no Windows; escolha pelo seu papel:

| Você é… | Caminho | Onde está o passo a passo |
|---------|---------|---------------------------|
| **Dev-consumidor** (trabalha nos projetos) | **A — Nativo + Git Bash** (⚗️ experimental) | [`docs/guides/windows-wsl.md`](docs/guides/windows-wsl.md) — **Caminho A** |
| **Mantenedor** do ideIAos, ou o teste do Caminho A falhou | **B — WSL2 / Ubuntu** (✅ garantido) | [`docs/guides/windows-wsl.md`](docs/guides/windows-wsl.md) — **Caminho B** |

**Antes de qualquer coisa:** cumpra os **acessos** (org `Ideia-Business` com `push`/write nos repos +
conta Claude Code) — [`docs/guides/onboarding-novo-dev.md` §0](docs/guides/onboarding-novo-dev.md).
Sem write, o `git clone` de repo privado já falha.

📑 Mapa de todos os guias de instalação (macOS, Windows, Linux, `.env`, dia a dia):
[`docs/guides/README.md`](docs/guides/README.md).

> _Por que um ponteiro e não a cópia?_ O runbook deste guia era duplicado verbatim aqui na raiz —
> duas cópias divergem com o tempo. A fonte única agora é `docs/guides/windows-wsl.md`; este arquivo
> só roteia (R15-15).
