extends Area2D

@export var door_closed: Texture2D
@export var door_open:   Texture2D
@export_file("*.tscn") var next_scene_path: String = "res://levels/release/des_01.tscn"

@onready var sprite: Sprite2D = $Sprite2D

var is_open: bool = false

func _ready() -> void:
	is_open = GameState.has_key
	_update_sprite()
	connect("body_entered", Callable(self, "_on_body_entered"))
	set_process(true)

func _process(_delta: float) -> void:
	if not is_open and GameState.has_key:
		is_open = true
		_update_sprite()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if is_open:
		get_tree().change_scene_to_file(next_scene_path)

func _update_sprite() -> void:
	sprite.texture = door_open if is_open else door_closed
