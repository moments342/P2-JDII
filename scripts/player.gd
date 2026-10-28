class_name Jogador
extends CharacterBody2D

signal vida_alterada(atual: int, maxima: int)
signal morreu
signal aliado_resgatado(total: int)
signal caminho_atualizado(posicao: Vector2, distancia: float)

@export var velocidade: float = 120.0
@export_range(1, 100, 1) var vida_maxima: int = 5
@export_range(0.05, 5.0, 0.05) var tempo_invulneravel: float = 0.8
@export_range(0.03, 0.5, 0.01) var intervalo_piscar: float = 0.1
@export_range(12.0, 100.0, 1.0) var espacamento_aliados: float = 32.0

var vida_atual: int
var morto: bool = false
var distancia_percorrida: float = 0.0
var aliados: Array[Aliado] = []

var _invulnerabilidade: float = 0.0
var _tempo_piscar: float = 0.0
var _cor_original: Color = Color.WHITE
var _direcao_visual: String = "baixo"

@onready var _barra_vida: ProgressBar = get_node_or_null("BarraVida")
@onready var _visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group("jogador")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	vida_atual = vida_maxima

	if _visual != null:
		_cor_original = _visual.modulate

	_atualizar_vida()
	_atualizar_animacao(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	_atualizar_efeito_dano(delta)

	if morto:
		_atualizar_animacao(Vector2.ZERO)
		return

	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")
	direcao += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = direcao.limit_length() * velocidade

	var posicao_anterior := global_position
	move_and_slide()

	var movimento := global_position - posicao_anterior
	var deslocamento := movimento.length()

	if deslocamento > 0.001:
		distancia_percorrida += deslocamento
		caminho_atualizado.emit(global_position, distancia_percorrida)

	_atualizar_animacao(movimento)


func resgatar_aliado(aliado: Aliado) -> void:
	if morto or aliado.resgatado or aliados.has(aliado):
		return

	aliados.append(aliado)
	aliado.seguir(self, aliados.size())
	aliado_resgatado.emit(aliados.size())


func receber_dano(quantidade: int) -> bool:
	if morto or quantidade <= 0 or _invulnerabilidade > 0.0:
		return false

	vida_atual = maxi(0, vida_atual - quantidade)
	_invulnerabilidade = tempo_invulneravel
	_tempo_piscar = 0.0

	_atualizar_vida()
	_atualizar_efeito_dano(0.0)

	if vida_atual == 0:
		morto = true
		velocity = Vector2.ZERO
		_atualizar_animacao(Vector2.ZERO)
		morreu.emit()

	return true


func _atualizar_vida() -> void:
	if _barra_vida != null:
		_barra_vida.max_value = vida_maxima
		_barra_vida.value = vida_atual

	vida_alterada.emit(vida_atual, vida_maxima)


func _atualizar_efeito_dano(delta: float) -> void:
	_invulnerabilidade = maxf(0.0, _invulnerabilidade - delta)

	if _visual == null:
		return

	if _invulnerabilidade <= 0.0:
		_visual.modulate = _cor_original
		return

	_tempo_piscar += delta

	var vermelho := int(_tempo_piscar / intervalo_piscar) % 2 == 0
	_visual.modulate = (
		Color(1.0, 0.25, 0.25, _cor_original.a)
		if vermelho else _cor_original
	)


func _atualizar_animacao(deslocamento: Vector2) -> void:
	if _visual == null or _visual.sprite_frames == null:
		return

	var andando := deslocamento.length_squared() > 0.0001
	var nome: StringName = &"parado"

	if andando:
		if absf(deslocamento.x) > absf(deslocamento.y):
			_direcao_visual = "direita" if deslocamento.x > 0.0 else "esquerda"
		else:
			_direcao_visual = "baixo" if deslocamento.y > 0.0 else "cima"

		nome = StringName("andar_" + _direcao_visual)

	if not _visual.sprite_frames.has_animation(nome):
		return

	if _visual.sprite_frames.get_frame_count(nome) == 0:
		return

	if _visual.animation != nome or not _visual.is_playing():
		_visual.play(nome)
