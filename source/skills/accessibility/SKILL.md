---
name: accessibility
description: "Acessibilidade web (WCAG 2.1 AA): semântica, contraste, teclado, ARIA, foco. Use proativamente em qualquer UI nova ou antes de publicar. Complementa /web-quality (auditoria) e /ui-ux-pro-max."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: accessibility

**Idioma:** Português brasileiro.

---

## Quando usar

- Qualquer UI nova ou alterada (componente, página, modal, formulário).
- Antes de deploy de feature com interface de usuário.
- Review de PR que toca HTML/JSX/componentes.

## Quando NÃO usar

- Backend puro (APIs sem interface de usuário).
- Scripts internos sem surface visual.

---

## Processo

### 1. HTML semântico primeiro

Usar elementos HTML nativos antes de ARIA:
- Botões: `<button>`, não `<div onClick>`.
- Links de navegação: `<a href>`, não `<span onClick>`.
- Formulários: `<form>`, `<label>`, `<input>` com `id` associado.
- Estrutura: `<main>`, `<nav>`, `<header>`, `<footer>`, `<section>`, `<article>`.

**Regra:** Se o elemento HTML nativo faz o que você precisa, use-o. ARIA só quando o nativo não é suficiente.

### 2. Contraste AA

- Texto normal: mínimo 4.5:1 em relação ao fundo.
- Texto grande (18px+ regular ou 14px+ bold): mínimo 3:1.
- Componentes UI e ícones informativos: mínimo 3:1.
- Ferramenta: WebAIM Contrast Checker ou extensão axe DevTools.

### 3. Navegação por teclado e foco visível

- Todo elemento interativo deve ser alcançável via Tab.
- Ordem de foco deve ser lógica (seguir fluxo visual).
- Foco visível obrigatório: `outline` não pode ser `outline: none` sem substituto.
- Modais e drawers: foco deve ser preso dentro (focus trap) enquanto abertos.
- ESC deve fechar modais.

### 4. Labels em inputs

- Todo `<input>`, `<select>`, `<textarea>` deve ter `<label>` associado (via `for`/`id` ou `aria-label`).
- Placeholder não substitui label (desaparece ao digitar).
- Mensagens de erro associadas ao campo: `aria-describedby`.

### 5. ARIA quando necessário

Usar `aria-label`, `aria-labelledby`, `aria-describedby`, `role` apenas quando o HTML nativo não comunica a semântica.
Exemplos legítimos: ícone sem texto (`aria-label="Fechar"`), região dinâmica (`aria-live="polite"`), componente customizado (`role="dialog"`).

### 6. Testar com leitor de tela

- macOS: VoiceOver (Cmd+F5). Navegar pela tela apenas com teclado.
- Verificar: o que o leitor anuncia faz sentido sem ver a tela?
- Ferramenta automatizada: axe DevTools (Chrome extension) para catches rápidos — não substitui teste manual.

---

## Output

- Checklist WCAG 2.1 AA preenchido (ver abaixo).
- Correções aplicadas diretamente no código.

### Checklist mínimo

- [ ] HTML semântico usado (sem divs clicáveis sem role)
- [ ] Contraste AA verificado (4.5:1 texto normal, 3:1 texto grande)
- [ ] Todos os inputs têm label
- [ ] Navegação por teclado funciona na ordem correta
- [ ] Foco visível em todos os elementos interativos
- [ ] Modais têm focus trap e ESC fecha
- [ ] Imagens informativas têm `alt` descritivo; imagens decorativas têm `alt=""`
- [ ] Testado com VoiceOver ou NVDA

---

## Relações

- `/web-quality` — audita e mede acessibilidade (Lighthouse score); esta skill orienta a **construir** acessível.
- `/ui-ux-pro-max` — design de UX; acessibilidade é requisito mínimo, não opcional.

---

## Anti-patterns

- `outline: none` sem substituto visível de foco.
- `<div onClick>` sem `role="button"` e `tabIndex={0}`.
- Placeholder como único label do campo.
- ARIA inventado sem necessidade (aria-role="textbox" em `<input type="text">`).
- Considerar acessibilidade "nice to have" — é requisito legal em muitos países.
