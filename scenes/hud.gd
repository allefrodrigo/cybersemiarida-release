# res://scripts/HUD.gd
class_name GameHud
extends CanvasLayer

const PAUSE_ACTION: StringName = &"pause"   # Esc, P, Start (spec 005, H3.4)

@export var icon_pause: Texture
@export var icon_play:  Texture

@onready var death_label:  Label         = $DeathLabel
@onready var fps_label:    Label         = $FPSLabel
@onready var timer_label:  Label         = $MarginContainer/TimerLabel
@onready var pause_button: TextureButton = $PauseButton
@onready var menu_button:  TextureButton = $MenuButton
@onready var key_label: Label = $KeyLabel

func _ready() -> void:
	add_to_group(&"game_hud")
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

## ⏸ e 🏠 por toque de qualquer dedo (spec 006, H3.1–H3.2). O Godot só emula mouse para o 1º dedo na tela, então
## os TextureButton ignoram o mouse (mouse_filter = IGNORE) e o HUD lê o toque; o clique do mouse chega aqui como toque
## emulado, então o computador continua igual.
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and event.pressed):
		return
	var p: Vector2 = (event as InputEventScreenTouch).position
	if pause_button.get_global_rect().has_point(p) and not pause_button.disabled:
		get_viewport().set_input_as_handled()
		_on_pause_button_pressed()
	elif menu_button.get_global_rect().has_point(p) and not menu_button.disabled:
		get_viewport().set_input_as_handled()
		_on_menu_button_pressed()

## Pausa por tecla ou botão do controle, com as mesmas regras do botão ⏸ (spec 005, H3.4–H3.6).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PAUSE_ACTION) and _can_toggle_pause():
		_on_pause_button_pressed()
		get_viewport().set_input_as_handled()

func _can_toggle_pause() -> bool:
	if pause_button.disabled:                 # trava do elevador (spec 003, lock_buttons)
		return false
	if DialogManager.is_showing_dialog:       # balão/placa aberto: Start e Espaço seguem com o balão
		return false
	var pl := get_tree().get_first_node_in_group("player") as Player
	if pl != null and not pl.input_enabled and not get_tree().paused:
		return false                          # sino (goal.gd, fade), placa (hit_pop.gd), elevador
	return true

## Desabilita pausa e menu (continuam visíveis) — usado na sequência do elevador (spec 003, H2.4).
func lock_buttons() -> void:
	set_buttons_locked(true)

## Trava/destrava ⏸ e 🏠 (continuam visíveis). Elevador (003) e sequência de morte (007, H2.5–H2.6).
func set_buttons_locked(locked: bool) -> void:
	pause_button.disabled = locked
	menu_button.disabled = locked

func _on_menu_button_pressed() -> void:
	print("MenuButton clicado")
	get_tree().paused = false
	if MusicPlayer.player.playing:
		MusicPlayer.player.stop()
	GameState.reset_run()
	var err = get_tree().change_scene_to_file("res://scenes/main_title.tscn")
	if err != OK:
		printerr("Falha ao trocar para Main Title:", err)

## Ponto (coordenadas da tela-base) dentro da área de toque do ⏸ ou do 🏠 (spec 006, H2.6).
func is_over_buttons(p: Vector2) -> bool:
	return pause_button.get_global_rect().has_point(p) or menu_button.get_global_rect().has_point(p)
