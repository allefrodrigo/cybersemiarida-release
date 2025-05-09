# FallManager.gd
extends Node

var total_falls: int = 0
var falls_per_level: Dictionary = {}

func increment_fall(level_name: String) -> void:
	total_falls += 1
	falls_per_level[level_name] = falls_per_level.get(level_name,0) + 1
	print("→ Queda em %s (neste nível: %d; total: %d)" %
		[level_name, falls_per_level[level_name], total_falls])
