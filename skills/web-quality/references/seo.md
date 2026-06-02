# SEO & Best Practices — Checklist

## Meta / head essencial

- [ ] `<title>` único e descritivo por página (≤ ~60 chars)
- [ ] `<meta name="description">` por página (≤ ~155 chars)
- [ ] `<meta name="viewport" content="width=device-width, initial-scale=1">`
- [ ] `<html lang="pt-BR">`
- [ ] Canonical (`<link rel="canonical">`) para evitar conteúdo duplicado
- [ ] Open Graph + Twitter Card (title, description, image) para compartilhamento

## Conteúdo / semântica

- [ ] Um `<h1>` por página, hierarquia sequencial
- [ ] HTML semântico (`<nav> <main> <article> <footer>`)
- [ ] Links com texto descritivo (não "clique aqui")
- [ ] Imagens com `alt` (também ajuda SEO)
- [ ] URLs limpas e legíveis

## Indexação

- [ ] `robots.txt` presente e correto
- [ ] `sitemap.xml` gerado e referenciado
- [ ] Sem `noindex` acidental em páginas que devem indexar
- [ ] Structured data (JSON-LD) quando aplicável (Organization, Product, Article, FAQ)

## Best Practices (segurança/qualidade — Lighthouse)

- [ ] HTTPS em tudo (sem mixed content)
- [ ] Sem erros no console
- [ ] `rel="noopener"` em links `target="_blank"`
- [ ] Imagens com aspect-ratio correto (evita distorção + CLS)
- [ ] Bibliotecas sem vulnerabilidades conhecidas
- [ ] Permissões sensíveis (geolocation, notif.) só sob ação do usuário

## SPA caveat
Apps client-side (React/Vite) podem ter SEO fraco sem SSR/pre-render. Se SEO importa: SSR (Next.js), pre-render estático, ou meta tags dinâmicas via react-helmet. Para apps internos/logados, SEO geralmente não se aplica — não otimize à toa.
