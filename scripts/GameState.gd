# res://scripts/GameState.gd
class_name GameStateManager
extends Node

var death_count: int = 0
var time_elapsed: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	time_elapsed += delta
