# Visual Critique Rubric

Checklist de crítica para o passo CRITIQUE do visual loop. Cada item tem severidade. Ancorado nas prioridades do `ui-ux-pro-max`.

## BLOCK — corrige na mesma iteração

| Check | Como detectar no snapshot/screenshot |
|-------|--------------------------------------|
| Overflow horizontal | scrollbar horizontal; conteúdo além da viewport mobile (390px) |
| Texto cortado / truncado indevidamente | `...` onde devia caber; altura fixa cortando linha |
| Contraste < 4.5:1 (texto normal) | texto cinza-sobre-cinza, texto sobre imagem sem overlay |
| Elementos sobrepostos | z-index errado; dropdown/tooltip atrás de outro; modal sem backdrop |
| Conteúdo invisível | branco no branco; opacity 0 esquecido; altura 0 |
| Erro no console | qualquer `error` em `list_console_messages` durante o render |
| Layout quebrado no mobile | grid não colapsa; `max-w-md` estourando Dialog; row de botões empilhando feio |

## FLAG — corrige se barato

| Check | Referência |
|-------|-----------|
| Alvo de toque < 44×44px | ui-ux-pro-max prioridade 2 |
| Espaçamento inconsistente | múltiplos de 4/8px; gaps irregulares |
| Hierarquia visual fraca | tudo no mesmo peso; sem âncora de leitura |
| Falta estado de loading | ação assíncrona sem feedback (spinner/skeleton) |
| Falta estado vazio (empty) | lista vazia mostra nada em vez de mensagem |
| Falta foco visível | remover focus ring é anti-padrão de a11y |
| Animação instantânea (0ms) | transições de estado devem ter 150–300ms |

## PASS — encerra o loop

Nenhum BLOCK e, idealmente, nenhum FLAG barato pendente. Conteúdo legível em desktop E mobile, console limpo.

## Pior caso (sempre testar)

Da memória `feedback_uat_visual_antes_de_commitar_ux` — cenários que UAT pega e revisão estática não:
- 3+ botões em uma row → quebra em telas estreitas
- `max-w-md` dentro de `<Dialog>` → estoura ou aperta
- Coluna nova em tabela → empurra layout, scroll horizontal
- Nome/string longo real (não o caso canônico curto) → trunca ou vaza
- Lista com 0 itens e com N>50 itens → empty state e densidade

## Como fundamentar o veredito

Em vez de "achei feio", cite a regra:
```
ui-ux-pro-max --domain ux      # accessibility, touch, layout, forms
ui-ux-pro-max --domain style   # style selection vs product type
ui-ux-pro-max --domain color   # contraste, tokens semânticos
```
