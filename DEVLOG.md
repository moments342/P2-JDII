# DEVLOG

## 13/10/2026 · `1d5e6bb` — Início do repositório

Começamos com o nome do projeto no `README.md` e um `.gitignore` para o Godot. Assim, arquivos gerados pelo editor, como o cache da pasta `.godot`, ficavam de fora do Git.

## 21/10/2026 · `c58c1aa` — Estrutura do projeto

Criamos o `project.godot` com o nome e o ícone do jogo, escolhemos o modo de renderização de compatibilidade e configuramos como a imagem se ajusta ao tamanho da janela. Também deixamos este diário criado para registrar o desenvolvimento.

## 21/10/2026 · `ef07d9a` — Entrada dos sprites

Colocamos em `sprites/` os pacotes de arte dos monstros e as peças de piso e parede que iam virar o cenário. Nessa etapa, a cena da escola era só um `Node2D` vazio, pronto para receber o mapa.

## 21/10/2026 · `b77bbaa` — Primeiras cenas

Usamos a imagem de pisos e paredes para montar um `TileSet` e desenhar a escola em camadas de chão e decoração. Desenhamos as colisões nos tiles das paredes e criamos cenas separadas para o jogador e o inimigo, cada uma com seu corpo e sua colisão. A câmera ficou na cena do jogador.

## 26/10/2026 · `24faee8` — Movimento, combate e resgate

Fizemos o jogador andar com WASD ou as setas e recortamos os quadros da folha de sprites para animar cada direção. O inimigo persegue o jogador quando ele chega perto e só dá dano se estiver ao alcance e sem uma parede no meio. Para resgatar um aliado, basta entrar na área dele. A partir daí, ele guarda os pontos por onde o jogador passa e refaz o caminho com espaço para os outros da fila.

## 26/10/2026 · `e07994e` — Animações e ajustes na partida

Montamos as animações da aliada e do monstro a partir dos sprites. O monstro fica parado enquanto anima o ataque e volta a se mover quando recebe o sinal de que a animação terminou. Também colocamos os três personagens na escola, ajustamos a colisão do jogador e corrigimos a cena de abertura para iniciar direto no mapa.

## 26/10/2026 · `cddd505` — Interface de resgate

Ligamos o contador ao sinal de resgate e calculamos as setas na tela com base na posição dos aliados que ainda faltam. As setas somem quando o jogador chega perto. Ao resgatar todo mundo ou perder toda a vida, a partida pausa e mostra o resultado. O botão **Rejogar** recarrega a escola.

## 28/10/2026 · `5044d0e` — Pátio, campo e profundidade

Adicionamos o piso do pátio, o meio-fio e o campo de futebol ao mapa. Ativamos o `Y Sort` e ajustamos a origem dos objetos para que os personagens apareçam na frente ou atrás da decoração conforme a posição no chão. Como os sprites ficaram maiores, também ajustamos as colisões, o alcance do ataque e o espaço entre os aliados na fila.

## 28/10/2026 · `fcd9b4a` — Mais aliados e inimigos pela escola

Reutilizamos as cenas de aliado e inimigo e colocamos quatro novas instâncias de cada uma em pontos diferentes da escola. Com isso, a partida passou a ter cinco aliados para resgatar e cinco inimigos espalhados pelo mapa.
