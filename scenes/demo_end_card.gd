extends Control
## Cartão de fim da demo (spec 003, H2.6–H2.9). Sem HUD; o filtro vem do autoload ColorBlindLayer.

const INPUT_LOCK_TIME: float = 2.0   # s ignorando entradas (H2.7)
const FADE_DURATION: float = 1.0     # s de escurecimento até o menu (H2.8)
const FADE_LAYER: int = 110

## B33: trocar para a cena de créditos quando ela existir (spec, Q1 = a).
@export_file("*.tscn") var next_scene_path: String = "res://scenes/main_title.tscn"

@onready var sting_player: AudioStreamPlayer = $StingPlayer
@onready var fade_layer: CanvasLayer = $FadeLayer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var _accepting: bool = false
var _leaving: bool = false

func _ready() -> void:
	get_tree().paused = false
	if MusicPlayer.player.playing:
		MusicPlayer.player.stop()        # a música do deserto não toca no cartão (spec §5)
	fade_layer.layer = FADE_LAYER
	fade_rect.color = Color(0, 0, 0, 0)
	if sting_player.stream != null:
		sting_player.play()
	await get_tree().create_timer(INPUT_LOCK_TIME).timeout
	_accepting = true

func _input(event: InputEvent) -> void:
	if _accepting and not _leaving and _is_confirm(event):
		get_viewport().set_input_as_handled()
		_leave()

func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT   # roda do mouse não conta
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_START
	return event.is_action_pressed("ui_accept")   # Enter, Espaço (Start também está em ui_accept)

func _leave() -> void:
	_leaving = true                       # clique gera mouse + toque emulado: só o 1º vale
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished
	GameState.reset_run()
	get_tree().change_scene_to_file(next_scene_path)
