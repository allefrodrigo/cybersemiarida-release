extends Node2D

@export var game_duration: float = 60.0
@export var max_circles: int = 3
@export var spawn_interval: float = 8.0

var circle_scene = preload("res://prefabs/falling_circle.tscn")
var active_circles: Array = []
var game_timer: float = 0.0
var spawn_timer: float = 0.0
var game_active: bool = true

signal game_finished
signal player_hit_reset_phase

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not game_active:
		return
		
	game_timer += delta
	spawn_timer += delta
	
	# Verifica se o jogo terminou
	if game_timer >= game_duration:
		end_game()
		return
	
	# Verifica se é hora de spawnar um novo círculo
	if spawn_timer >= spawn_interval and active_circles.size() < max_circles:
		spawn_circle()
		spawn_timer = 0.0

func spawn_circle() -> void:
	var circle = circle_scene.instantiate()
	
	# Adiciona à cena
	get_tree().current_scene.add_child(circle)
	
	# Configura posição inicial no topo da tela
	circle.set_random_position_top()
	
	# Conecta sinais
	circle.circle_destroyed.connect(_on_circle_destroyed)
	circle.player_hit.connect(_on_player_hit)
	
	# Adiciona à lista de círculos ativos
	active_circles.append(circle)
	
	print("Círculo spawnado. Total ativo: ", active_circles.size())

func _on_circle_destroyed() -> void:
	# Remove círculos destruídos da lista
	for i in range(active_circles.size() - 1, -1, -1):
		if not is_instance_valid(active_circles[i]):
			active_circles.remove_at(i)
	
	print("Círculo destruído. Total ativo: ", active_circles.size())

func _on_player_hit() -> void:
	# Emite sinal para resetar a fase
	player_hit_reset_phase.emit()
	print("Player foi atingido! Resetando fase...")


func end_game() -> void:
	game_active = false
	
	# Destrói todos os círculos ativos
	for circle in active_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	active_circles.clear()
	
	game_finished.emit()
	print("Jogo de círculos finalizado!")

func get_remaining_time() -> float:
	return max(0.0, game_duration - game_timer)


func reset_game() -> void:
	# Reseta todos os timers
	game_timer = 0.0
	spawn_timer = 0.0
	game_active = true
	
	# Reseta posições de todos os círculos ativos
	for circle in active_circles:
		if is_instance_valid(circle):
			circle.reset_position()
	
	print("Jogo resetado!")
