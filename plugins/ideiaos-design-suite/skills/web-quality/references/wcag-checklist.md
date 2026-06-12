# WCAG 2.1 AA — Checklist

Lighthouse automatiza ~30%. Esta lista cobre o resto (checagem manual/guiada). Marcar cada item.

## Perceptível

- [ ] **Contraste** texto normal ≥ 4.5:1, texto grande ≥ 3:1, componentes/ícones ≥ 3:1
- [ ] **Alt text** em imagens significativas; `alt=""` em decorativas
- [ ] **Não só cor** para transmitir informação (erro = cor + ícone + texto)
- [ ] **Legendas/transcrição** em vídeo/áudio
- [ ] Conteúdo **reflui** a 320px sem scroll horizontal e a 200% de zoom
- [ ] Texto redimensionável sem quebra (respeita dynamic type)

## Operável

- [ ] **100% navegável por teclado** (Tab/Shift+Tab/Enter/Esc/setas)
- [ ] **Foco visível** sempre (nunca remover outline sem substituto ≥ 2px)
- [ ] Ordem de foco = ordem visual/lógica
- [ ] **Skip link** "pular para conteúdo"
- [ ] Sem armadilha de teclado (focus trap só em modal, com Esc)
- [ ] Alvos de toque ≥ 44×44px (alinha ui-ux-pro-max prioridade 2)
- [ ] `prefers-reduced-motion` respeitado (ver skill `motion`)
- [ ] Nada que pisque > 3x/s (risco de convulsão)

## Compreensível

- [ ] `<html lang="pt-BR">` definido
- [ ] **Labels** visíveis associadas a inputs (`<label for>`); placeholder ≠ label
- [ ] Erros descritos em texto, próximos do campo, com instrução de correção
- [ ] Navegação consistente entre páginas
- [ ] Foco não muda contexto inesperadamente

## Robusto

- [ ] HTML válido / semântico (`<nav> <main> <button> <h1..h6>` em ordem)
- [ ] **Hierarquia de headings** sequencial (sem pular nível)
- [ ] `aria-label`/`aria-labelledby` em controles sem texto (botão-ícone)
- [ ] Roles ARIA corretos só quando o HTML nativo não basta
- [ ] Componentes custom (dropdown, tabs, modal) seguem o padrão ARIA Authoring Practices
- [ ] Estados comunicados a leitores de tela (`aria-expanded`, `aria-selected`, `aria-live` para toasts)

## Teste manual mínimo
1. Desconecte o mouse → navegue tudo no teclado
2. Rode VoiceOver (Cmd+F5 no macOS) na home e num formulário
3. Zoom 200% → confira reflow
4. DevTools → emular `prefers-reduced-motion: reduce`
