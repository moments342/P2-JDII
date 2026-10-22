class_name Jogador
extends CharacterBody2D

signal vida_alterada(atual: int, maxima: int)
signal morreu
signal aliado_resgatado(total: int)
signal caminho_atualizado(posicao: Vector2, distancia: float)

@export var velocidade: float = 120.0
@export_range(1, 100, 1) var vida_maxima: int = 5
@export_range(0.05, 5.0, 0.05) var tempo_invulneravel: float = 0.8
@export_range(12.0, 100.0, 1.0) var espacamento_aliados: float = 18.0

var vida_atual: int
var morto: bool = false
var distancia_percorrida: float = 0.0
var aliados: Array[Aliado] = []
var _invulnerabilidade: float = 0.0

@onready var _barra_vida: ProgressBar = get_node_or_null("BarraVida")

func _ready() -> void:
	add_to_group("jogador")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	vida_atual = vida_maxima
	_atualizar_vida()


func _physics_process(delta: float) -> void:
	_invulnerabilidade = maxf(0.0, _invulnerabilidade - delta)
	if morto:
		return

	# As setas usam as acoes padrao do Godot; WASD tambem funciona.
	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direcao += Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	velocity = direcao.limit_length() * velocidade
	var posicao_anterior := global_position
	move_and_slide()

	var deslocamento := posicao_anterior.distance_to(global_position)
	if deslocamento > 0.001:
		distancia_percorrida += deslocamento
		caminho_atualizado.emit(global_position, distancia_percorrida)

	modulate = Color(1.0, 0.55, 0.55, 0.65) if _invulnerabilidade > 0.0 else Color.WHITE


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
	_atualizar_vida()
	if vida_atual == 0:
		morto = true
		velocity = Vector2.ZERO
		modulate = Color(0.45, 0.45, 0.45)
		morreu.emit()
	return true


func _atualizar_vida() -> void:
	if _barra_vida != null:
		_barra_vida.max_value = vida_maxima
		_barra_vida.value = vida_atual
	vida_alterada.emit(vida_atual, vida_maxima)
