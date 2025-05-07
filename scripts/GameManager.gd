# GameManager.gd
extends Node

# Armazena os dados de checkpoint para cada nível
var checkpoints = {}
# Nome ou caminho da fase atual (pode ser usado para saber qual respawn usar)
var current_level_path = ""
# Outros dados globais que forem necessários (pontuação, vidas, etc.)
var player_data = {
	"health": 100,
	"coins": 0,
}

func set_checkpoint(level_path: String, position: Vector2) -> void:
	# Armazena a posição do checkpoint da fase corrente
	checkpoints[level_path] = position

func get_checkpoint(level_path: String) -> Vector2:
	# Retorna a posição do checkpoint se existir ou null
	return checkpoints.get(level_path, null)

func load_level(level_path: String) -> void:
	# Armazena qual é o nível atual
	current_level_path = level_path
	get_tree().change_scene(level_path)
