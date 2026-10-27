extends Control

const MARGEM_SETAS: float = 28.0
const ESPACAMENTO_SETAS: float = 44.0
const PROPORCAO_DISTANCIA_SETA: float = 0.5
const DISTANCIA_MINIMA_JOGADOR: float = 56.0
const DISTANCIA_MINIMA_ALIADO: float = 64.0
const DISTANCIA_OCULTAR_SETA: float = 144.0
const COR_SETA: Color = Color(0.2, 0.8, 0.25, 1.0)
const COR_CONTORNO: Color = Color(0.025, 0.035, 0.05, 1.0)

var _jogador: Jogador
var _aliados: Array[Aliado] = []
var _partida_encerrada: bool = false
var _atualizacao_aliados_pendente: bool = false

@onready var _painel_contador: PanelContainer = $Contador
@onready var _contador: Label = $Contador/Texto
@onready var _tela_resultado: Control = $Resultado
@onready var _titulo_resultado: Label = $Resultado/Centro/Painel/Conteudo/Titulo
@onready var _mensagem_resultado: Label = $Resultado/Centro/Painel/Conteudo/Mensagem
@onready var _resumo: Label = $Resultado/Centro/Painel/Conteudo/Resumo
@onready var _botao_rejogar: Button = $Resultado/Centro/Painel/Conteudo/Rejogar


func _ready() -> void:
	_botao_rejogar.pressed.connect(_rejogar)
	_conectar_partida.call_deferred()


func _conectar_partida() -> void:
	_jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	get_tree().node_added.connect(_ao_mudar_aliados)
	get_tree().node_removed.connect(_ao_mudar_aliados)

	if is_instance_valid(_jogador):
		_jogador.aliado_resgatado.connect(_ao_resgatar_aliado)
		_jogador.morreu.connect(_mostrar_game_over)

	_sincronizar_aliados()
	if is_instance_valid(_jogador) and _jogador.morto:
		_mostrar_game_over()
	else:
		_verificar_vitoria()


func _ao_mudar_aliados(no: Node) -> void:
	if no is Aliado and not _atualizacao_aliados_pendente:
		_atualizacao_aliados_pendente = true
		_sincronizar_aliados.call_deferred()


func _sincronizar_aliados() -> void:
	_atualizacao_aliados_pendente = false
	if not is_inside_tree():
		return

	_aliados.clear()
	for no in get_tree().get_nodes_in_group("aliados"):
		if no is Aliado and not no.is_queued_for_deletion():
			_aliados.append(no)
	_atualizar_contador()
	queue_redraw()


func _process(_delta: float) -> void:
	if not _partida_encerrada:
		queue_redraw()


func _ao_resgatar_aliado(_total: int) -> void:
	_atualizar_contador()
	queue_redraw()
	_verificar_vitoria()


func _atualizar_contador() -> void:
	var resgatados: int = _jogador.aliados.size() if is_instance_valid(_jogador) else 0
	var pendentes: int = 0
	for aliado in _aliados:
		if is_instance_valid(aliado) and not aliado.resgatado:
			pendentes += 1
	_contador.text = "Resgatados: %d / %d" % [resgatados, resgatados + pendentes]


func _draw() -> void:
	if _partida_encerrada or not is_instance_valid(_jogador):
		return
	if size.x <= MARGEM_SETAS * 2.0 or size.y <= MARGEM_SETAS * 2.0:
		return

	var para_tela := get_global_transform_with_canvas().affine_inverse()
	var origem: Vector2 = para_tela * _jogador.get_global_transform_with_canvas().origin
	var limites := Rect2(Vector2.ONE * MARGEM_SETAS, size - Vector2.ONE * MARGEM_SETAS * 2.0)
	var origem_interna := Vector2(
		clampf(origem.x, limites.position.x, limites.end.x),
		clampf(origem.y, limites.position.y, limites.end.y)
	)
	var destinos: Array[Vector2] = []
	for aliado in _aliados:
		if is_instance_valid(aliado) and not aliado.resgatado:
			destinos.append(para_tela * aliado.get_global_transform_with_canvas().origin)

	var posicoes_usadas: Array[Vector2] = []
	for destino in destinos:
		# Some antes de o espaço entre jogador e aliado ficar pequeno para a seta.
		var distancia := minf(origem.distance_to(destino), origem_interna.distance_to(destino))
		if distancia <= DISTANCIA_OCULTAR_SETA:
			continue
		var posicao := _posicionar_seta(origem_interna, destino, limites, posicoes_usadas, destinos)
		posicoes_usadas.append(posicao)
		var direcao_seta := posicao.direction_to(destino)
		if direcao_seta.is_zero_approx():
			direcao_seta = Vector2.UP
		_desenhar_seta(posicao, direcao_seta)


func _projetar_na_borda(origem: Vector2, direcao: Vector2, limites: Rect2) -> Vector2:
	var distancia_x: float = INF
	var distancia_y: float = INF

	if direcao.x > 0.0:
		distancia_x = (limites.end.x - origem.x) / direcao.x
	elif direcao.x < 0.0:
		distancia_x = (limites.position.x - origem.x) / direcao.x

	if direcao.y > 0.0:
		distancia_y = (limites.end.y - origem.y) / direcao.y
	elif direcao.y < 0.0:
		distancia_y = (limites.position.y - origem.y) / direcao.y

	return origem + direcao * minf(distancia_x, distancia_y)


func _posicionar_seta(
	origem: Vector2,
	destino: Vector2,
	limites: Rect2,
	usadas: Array[Vector2],
	destinos: Array[Vector2]
) -> Vector2:
	var direcao := origem.direction_to(destino)
	if direcao.is_zero_approx():
		direcao = Vector2.UP
	var raio := maxf(
		DISTANCIA_MINIMA_JOGADOR,
		origem.distance_to(destino) * PROPORCAO_DISTANCIA_SETA
	)
	var preferida := _limitar_seta(origem, direcao, raio, limites)

	# Abre espaço em torno do jogador, mantendo uma seta para cada destino.
	for camada in range(destinos.size() + 1):
		for tentativa in range(73):
			var graus := ceilf(float(tentativa) / 2.0) * 5.0
			if tentativa % 2 == 0:
				graus = -graus
			var orientacao := direcao.rotated(deg_to_rad(graus))
			var candidata := _limitar_seta(
				origem, orientacao, raio + camada * ESPACAMENTO_SETAS, limites
			)
			if _posicao_livre(candidata, origem, usadas, destinos):
				return candidata

	# Se os aliados se concentrarem perto de um canto, procura espaço no restante da tela.
	var melhor := preferida
	var menor_distancia: float = INF
	for linha in range(int(limites.size.y / ESPACAMENTO_SETAS) + 1):
		for coluna in range(int(limites.size.x / ESPACAMENTO_SETAS) + 1):
			var candidata := limites.position + Vector2(coluna, linha) * ESPACAMENTO_SETAS
			if _posicao_livre(candidata, origem, usadas, destinos):
				var distancia := candidata.distance_squared_to(preferida)
				if distancia < menor_distancia:
					melhor = candidata
					menor_distancia = distancia
	return melhor


func _limitar_seta(origem: Vector2, direcao: Vector2, distancia: float, limites: Rect2) -> Vector2:
	var borda := _projetar_na_borda(origem, direcao, limites)
	return origem + direcao * minf(distancia, origem.distance_to(borda))


func _posicao_livre(
	posicao: Vector2,
	origem: Vector2,
	usadas: Array[Vector2],
	destinos: Array[Vector2]
) -> bool:
	if _painel_contador.get_rect().grow(18.0).has_point(posicao):
		return false
	if posicao.distance_to(origem) < DISTANCIA_MINIMA_JOGADOR - 0.1:
		return false
	for destino in destinos:
		if posicao.distance_to(destino) < DISTANCIA_MINIMA_ALIADO - 0.1:
			return false
	for usada in usadas:
		if posicao.distance_to(usada) < ESPACAMENTO_SETAS - 0.1:
			return false
	return true


func _desenhar_seta(posicao: Vector2, direcao: Vector2) -> void:
	var pontos := PackedVector2Array([
		Vector2(12, 0), Vector2(1, -10), Vector2(1, -4),
		Vector2(-10, -4), Vector2(-10, 4), Vector2(1, 4), Vector2(1, 10)
	])
	for indice in range(pontos.size()):
		pontos[indice] = posicao + pontos[indice].rotated(direcao.angle())

	draw_colored_polygon(pontos, COR_SETA)
	pontos.append(pontos[0])
	draw_polyline(pontos, COR_CONTORNO, 2.0, true)


func _verificar_vitoria() -> void:
	if _partida_encerrada or not is_instance_valid(_jogador) or _jogador.morto:
		return
	if _jogador.aliados.is_empty():
		return

	for no in get_tree().get_nodes_in_group("aliados"):
		if no is Aliado and not no.resgatado:
			return

	_encerrar_partida(true)


func _mostrar_game_over() -> void:
	_encerrar_partida(false)


func _encerrar_partida(vitoria: bool) -> void:
	if _partida_encerrada:
		return

	_partida_encerrada = true
	_titulo_resultado.text = "VITÓRIA!" if vitoria else "GAME OVER"
	_titulo_resultado.add_theme_color_override(
		"font_color", COR_SETA if vitoria else Color(0.96, 0.38, 0.38, 1.0)
	)
	_mensagem_resultado.visible = vitoria
	_atualizar_contador()
	_resumo.text = _contador.text
	_painel_contador.hide()
	_tela_resultado.show()
	queue_redraw()
	get_tree().paused = true
	_botao_rejogar.grab_focus.call_deferred()


func _rejogar() -> void:
	_botao_rejogar.disabled = true
	get_tree().paused = false
	var erro := get_tree().reload_current_scene()
	if erro != OK:
		get_tree().paused = true
		_resumo.text = "Não foi possível reiniciar.\nTente novamente."
		_botao_rejogar.disabled = false
		_botao_rejogar.grab_focus()
