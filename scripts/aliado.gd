class_name Aliado
extends CharacterBody2D

@export var velocidade: float = 160.0

var resgatado: bool = false
var jogador: Jogador
var distancia_na_fila: float = 0.0

# Cada aliado guarda o caminho a partir do seu proprio resgate.
var _pontos: Array[Vector2] = []
var _distancias: Array[float] = []
var _proximo_ponto: int = 0

@onready var _area_resgate: Area2D = $AreaResgate


func _ready() -> void:
	add_to_group("aliados")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_area_resgate.body_entered.connect(_ao_corpo_entrar)


func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if not resgatado or not is_instance_valid(jogador) or jogador.morto:
		return

	# O segundo aliado espera mais caminho que o primeiro, e assim por diante.
	var limite := jogador.distancia_percorrida - distancia_na_fila
	var movimento_restante := maxf(velocidade, jogador.velocidade) * delta
	while _proximo_ponto < _pontos.size() and movimento_restante > 0.001:
		if _distancias[_proximo_ponto] > limite:
			break
		var destino := _pontos[_proximo_ponto]
		var deslocamento := destino - global_position
		if deslocamento.length() <= 0.01:
			_proximo_ponto += 1
			continue

		var passo := deslocamento.limit_length(movimento_restante)
		var posicao_anterior := global_position
		var colisao := move_and_collide(passo)
		var percorrido := posicao_anterior.distance_to(global_position)
		movimento_restante -= percorrido
		velocity = (global_position - posicao_anterior) / delta
		if global_position.distance_to(destino) <= 0.01:
			_proximo_ponto += 1
		if colisao != null or percorrido <= 0.001:
			break

	# Descarta pontos ja visitados para a memoria nao crescer com a partida.
	if _proximo_ponto >= 128:
		_pontos = _pontos.slice(_proximo_ponto)
		_distancias = _distancias.slice(_proximo_ponto)
		_proximo_ponto = 0


func seguir(novo_jogador: Jogador, posicao_na_fila: int) -> void:
	if resgatado:
		return
	resgatado = true
	jogador = novo_jogador
	distancia_na_fila = jogador.espacamento_aliados * posicao_na_fila
	_guardar_ponto(jogador.global_position, jogador.distancia_percorrida)
	jogador.caminho_atualizado.connect(_guardar_ponto)
	_area_resgate.set_deferred("monitoring", false)


func _guardar_ponto(posicao: Vector2, distancia: float) -> void:
	_pontos.append(posicao)
	_distancias.append(distancia)


func _ao_corpo_entrar(corpo: Node2D) -> void:
	if corpo is Jogador:
		corpo.resgatar_aliado(self)
