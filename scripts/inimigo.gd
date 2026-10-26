class_name Inimigo
extends CharacterBody2D

@export var velocidade: float = 75.0
@export_range(0.0, 2000.0, 1.0) var distancia_deteccao: float = 180.0
@export_range(1.0, 100.0, 1.0) var alcance_ataque: float = 16.0
@export_range(1, 100, 1) var dano: int = 1
@export_range(0.05, 10.0, 0.05) var intervalo_ataque: float = 1.0

var jogador: Jogador
var _tempo_ate_ataque: float = 0.0
var _direcao_visual: String = "baixo"

@onready var _visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group("inimigos")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_atualizar_animacao(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	_tempo_ate_ataque = maxf(0.0, _tempo_ate_ataque - delta)
	velocity = Vector2.ZERO

	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador

	if not is_instance_valid(jogador) or jogador.morto:
		_atualizar_animacao(Vector2.ZERO)
		return

	var distancia := global_position.distance_to(jogador.global_position)

	if distancia > distancia_deteccao:
		_atualizar_animacao(Vector2.ZERO)
		return

	var posicao_anterior := global_position

	if distancia <= alcance_ataque and _sem_parede_entre_nos():
		if _tempo_ate_ataque <= 0.0:
			jogador.receber_dano(dano)
			_tempo_ate_ataque = intervalo_ataque
	else:
		velocity = global_position.direction_to(jogador.global_position) * velocidade
		move_and_slide()

	_atualizar_animacao(global_position - posicao_anterior)


func _sem_parede_entre_nos() -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(
		global_position,
		jogador.global_position,
		1
	)

	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


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
