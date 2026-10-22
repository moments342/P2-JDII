# P2-JDII — jogo de resgate

Abra `project.godot` no Godot 4.7 e pressione **F5**. A cena principal é
`scenes/resgate.tscn`; ela também pode ser executada com **F6** quando estiver aberta.

- **Setas ou WASD:** movimentam o personagem azul, sem acelerar na diagonal.
- **Aliados verdes:** ficam parados até o personagem encostar neles. Após o
  resgate, entram na fila na ordem de coleta e percorrem o caminho do jogador.
  Não recebem dano. Cada novo aliado espera o personagem abrir o espaço da sua
  posição na fila antes de começar a andar; ele não é teleportado para a cauda.
- **Inimigos vermelhos:** perseguem o jogador dentro do raio de detecção e
  atacam quando estão perto, respeitando o intervalo entre golpes e as paredes.
- A barra acima do personagem mostra sua vida. Depois de um golpe, ele fica
  temporariamente invulnerável. Com vida zero, o personagem, a fila e os
  inimigos param. Para testar outra vez, pare e execute a cena novamente.

## Scripts e configuração

| Script | Responsabilidade | Ajustes no Inspetor |
| --- | --- | --- |
| `scripts/player.gd` | Movimento, vida e ordem dos resgates | Velocidade, Vida Maxima, Tempo Invulneravel, Espacamento Aliados |
| `scripts/aliado.gd` | Resgate por contato e caminho da fila | Velocidade |
| `scripts/inimigo.gd` | Perseguição e ataque ao jogador | Velocidade, Distancia Deteccao, Alcance Ataque, Dano, Intervalo Ataque |

Os scripts já estão ligados às respectivas cenas. Para colocar mais aliados
ou inimigos, arraste `scenes/aliado.tscn` ou `scenes/inimigo.tscn` para a fase
e ajuste a posição. Use apenas um jogador por fase.

Os visuais coloridos são marcadores para testar a lógica. Você pode trocar o
nó `Visual` por `Sprite2D` ou `AnimatedSprite2D` sem alterar os scripts.
As animações ainda não estão implementadas.

## Nós e colisões

Os três personagens usam uma raiz `CharacterBody2D` com `CollisionShape2D`.
O aliado precisa também de `AreaResgate/CollisionShape2D`; o script conecta
o sinal `body_entered` automaticamente. A barra de vida do jogador e opcional.

| Objeto | Camada | Mascara |
| --- | --- | --- |
| Cenario e paredes | 1 | Conforme a fase |
| Jogador | 2 | 1 |
| Inimigo | 3 | 1 |
| Aliado | 4 | 1 |
| AreaResgate | Nenhuma | 2 |

Assim todos respeitam as paredes e os personagens nao bloqueiam a fila.
Os inimigos seguem diretamente na direção do jogador; a navegação automática
ao redor de obstáculos internos ainda não está implementada. Eles não atacam
através das paredes e nunca escolhem aliados como alvo.

O jogador emite `vida_alterada(atual, maxima)`, `morreu` e
`aliado_resgatado(total)` para conectar depois a uma interface, tela de derrota
ou objetivo da fase. Resgatar todos não encerra a partida automaticamente.

## Testes automáticos

Com o executável do Godot disponível no PATH, execute na pasta do projeto:

```powershell
godot --headless --path . --script res://tests/resgate_test.gd --fixed-fps 60
```

Em um checkout novo, abra primeiro o projeto no editor para importar os
recursos. Os testes verificam resgate, ordem e curvas da fila, parada,
velocidade diagonal, invulnerabilidade, ataques, morte e colisão com paredes.
