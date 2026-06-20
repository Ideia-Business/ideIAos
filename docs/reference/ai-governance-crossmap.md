# SOURCE: cross-map de governança de IA (v12) — DADOS de referência
<!-- Fatos públicos; ponteiros de descoberta via TalEliyahu/Awesome-AI-Security (MIT).
     Citar SEMPRE a fonte primária, nunca a awesome-list. -->

## Para que serve

Produtos regulados (cfoai, nfideia) re-pesquisam frameworks de governança de IA do zero em
due-diligence. Este é um **mapa de referência cruzada** — links autoritativos, datado. Zero
superfície operacional no OS; é consulta. (Espelhar no vault Obsidian `References/` quando
conveniente — o vault é o lar canônico de referências externas.)

## Cross-map de frameworks

| Framework | Autoridade (fonte primária) | Papel |
|---|---|---|
| **NIST AI RMF** + **AI 100-2** (Adversarial ML Taxonomy) | `nist.gov` / `csrc.nist.gov` | terminologia canônica (evasion, poisoning, extraction, membership inference) + gestão de risco |
| **ISO/IEC 42001** | `iso.org` | sistema de gestão de IA (certificável) |
| **CSA AICM** (243 controles / 18 domínios) | `cloudsecurityalliance.org` | controles de governança cloud + IA |
| **Google SAIF** | `saif.google` | framework de segurança de IA do Google |
| **OWASP LLM/Agentic Top 10** (2025) | `genai.owasp.org` | taxonomia de risco LLM/agêntico — **CC BY-SA 4.0** (conceito-only, atribuição) |
| **MITRE ATLAS** | `atlas.mitre.org` | TTP adversarial de IA ("ATT&CK para IA") — rastreável por technique-ID |

## Uso no IdeiaOS

- **Terminologia ubíqua:** alimentar `CONTEXT.md` (`/grelha`) com os termos NIST canônicos em
  vez de nomes ad-hoc — afia spec, reduz tokens de reconciliação.
- **Due-diligence de produto regulado:** ponto de partida do mapeamento de compliance; o OS
  não implementa controles, só aponta o primário.

> Datado 2026-06-19 (v12). Reverificar periodicamente (links de framework evoluem).
