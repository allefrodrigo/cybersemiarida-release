# res://scripts/HUD.gd
extends CanvasLayer

@onready var death_label: Label  = $DeathLabel
@onready var fps_label:   Label  = $FPSLabel
@onready var timer_label: Label = $MarginContainer/TimerLabel

func _process(_delta: float) -> void:
	# Mortes
	death_label.text = str(GameState.death_count)
	# Timer MM:SS
	var total_secs = int(GameState.time_elapsed)
	var m = total_secs / 60
	var s = total_secs % 60
	timer_label.text = "%02d:%02d" % [m, s]
	# FPS
	fps_label.text = str(Engine.get_frames_per_second())
