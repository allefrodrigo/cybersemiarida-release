class_name Elevator
extends Node2D
## Elevador do fim do Deserto de Cima (spec 003, H2). Entra-se por contato, sem tecla extra.

signal sequence_started

const HOLD_BEFORE_FADE: float = 1.5   # s parado dentro da porta (H2.3)
const FADE_DURATION: float = 1.0      # s de escurecimento
const SNAP_DURATION: float = 0.2      # s para centralizar o Timby na porta (≤ 0,2 s, H2.3)
const FADE_LAYER: int = 110           # acima do HUD e do balão; abaixo do ColorBlindLayer (120)

@export_file("*.tscn") var next_scene_path: String = "res://scenes/demo_end_card.tscn"

@onready var door_area: Area2D = $DoorArea
@onready var door_shape: CollisionShape2D = $DoorArea/CollisionShape2D
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var fade_layer: CanvasLayer = $FadeLayer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var _triggered: bool = false

func _ready() -> void:
	fade_layer.layer = FADE_LAYER
	fade_rect.color = Color(0, 0, 0, 0)
	door_area.body_entered.connect(_on_door_body_entered)

func _on_door_body_entered(body: Node2D) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	var player := body as Player
	player.input_enabled = false          # direção/pulo não fazem nada (H2.4)
	player.forced_walk_direction = 0      # para, não anda sozinho
	player.velocity.x = 0.0
	create_tween().tween_property(player, "global_position:x", door_shape.global_position.x, SNAP_DURATION)
	if sfx_player.stream != null:
		sfx_player.play()
	sequence_started.emit()                # des_01 trava pausa/menu do HUD (H2.4)
	await get_tree().create_timer(HOLD_BEFORE_FADE).timeout
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished
	get_tree().change_scene_to_file(next_scene_path)
