# res://scripts/HUD.gd
extends CanvasLayer

@export var icon_pause: Texture
@export var icon_play:  Texture

@onready var death_label:  Label         = $DeathLabel
@onready var fps_label:    Label         = $FPSLabel
@onready var timer_label:  Label         = $MarginContainer/TimerLabel
@onready var pause_button: TextureButton = $PauseButton
@onready var menu_button:  TextureButton = $MenuButton
@onready var key_label: Label = $KeyLabel

func _ready() -> void:
	# HUD sempre processa, mesmo com Tree pausada
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

	# Desabilita foco em botões para que teclas não os acionem
	pause_button.focus_mode = Control.FOCUS_NONE
	menu_button.focus_mode  = Control.FOCUS_NONE

	# Ícone inicial de “pausar”
	pause_button.texture_normal = icon_pause

func _process(_delta: float) -> void:
	death_label.text = str(GameState.death_count)
	var total = int(GameState.time_elapsed)
	timer_label.text = "%02d:%02d" % [total/60, total%60]
	fps_label.text   = str(Engine.get_frames_per_second())
	key_label.text   = "1/1" if GameState.has_key else "0/1"

func _on_pause_button_pressed() -> void:
	var will_pause = not get_tree().paused
	get_tree().paused = will_pause
	pause_button.texture_normal = icon_play if will_pause else icon_pause

func _on_menu_button_pressed() -> void:
	print("MenuButton clicado")
	get_tree().paused = false
	if MusicPlayer.player.playing:
		MusicPlayer.player.stop()
	GameState.death_count  = 0
	GameState.time_elapsed = 0.0
	var err = get_tree().change_scene_to_file("res://scenes/main_title.tscn")
	if err != OK:
		printerr("Falha ao trocar para Main Title:", err)
