# res://scripts/GameState.gd
class_name GameStateManager
extends Node

var death_count: int = 0
var time_elapsed: float = 0.0
var has_key: bool       = false

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	time_elapsed += delta

## Zera o estado da partida (mortes, tempo e chave). O filtro de daltonismo não é zerado.
func reset_run() -> void:
	death_count = 0
	time_elapsed = 0.0
	has_key = false
