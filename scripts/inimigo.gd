class_name Inimigo
extends CharacterBody2D

@export var velocidade: float = 75.0
@export_range(0.0, 2000.0, 1.0) var distancia_deteccao: float = 180.0
@export_range(1.0, 100.0, 1.0) var alcance_ataque: float = 16.0
@export_range(1, 100, 1) var dano: int = 1
@export_range(0.05, 10.0, 0.05) var intervalo_ataque: float = 1.0

var jogador: Jogador
var _tempo_ate_ataque: float = 0.0


func _ready() -> void:
	add_to_group("inimigos")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	_tempo_ate_ataque = maxf(0.0, _tempo_ate_ataque - delta)
	velocity = Vector2.ZERO
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	if not is_instance_valid(jogador) or jogador.morto:
		return

	var distancia := global_position.distance_to(jogador.global_position)
	if distancia > distancia_deteccao:
		return

	if distancia <= alcance_ataque and _sem_parede_entre_nos():
		if _tempo_ate_ataque <= 0.0:
			jogador.receber_dano(dano)
			_tempo_ate_ataque = intervalo_ataque
	else:
		velocity = global_position.direction_to(jogador.global_position) * velocidade
		move_and_slide()


func _sem_parede_entre_nos() -> bool:
	# A camada 1 contem o cenario: impede ataques atraves de paredes.
	var consulta := PhysicsRayQueryParameters2D.create(global_position, jogador.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()
