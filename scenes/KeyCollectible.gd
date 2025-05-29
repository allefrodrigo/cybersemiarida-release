# res://scenes/KeyCollectible.gd
extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D
static var shine_shader: Shader = preload("res://shaders/radial_shine.gdshader")
var collected: bool = false

func _ready() -> void:
	# garanta que no editor você já tenha atribuído
	# sprite_2d.texture = preload("res://props/key.png")

	var mat = ShaderMaterial.new()
	mat.shader = shine_shader
	sprite_2d.material = mat

	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		GameState.has_key = true
		queue_free()
