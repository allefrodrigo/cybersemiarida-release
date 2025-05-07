extends StaticBody2D

@export var platform_texture: Texture2D
@export var is_vertical: bool    = true
@export var move_distance: float = 100.0
@export var move_speed: float    = 50.0

@onready var sprite: Sprite2D = $Sprite2D
var start_position: Vector2
var direction: int = 1

func _ready() -> void:
	sprite.texture   = platform_texture
	start_position   = global_position
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	var disp = move_speed * delta * direction

	if is_vertical:
		var new_y   = global_position.y + disp
		var min_y   = start_position.y
		var max_y   = start_position.y + move_distance
		if new_y > max_y:
			new_y      = max_y
			direction  = -1
		elif new_y < min_y:
			new_y      = min_y
			direction  = 1
		global_position.y = new_y
	else:
		var new_x   = global_position.x + disp
		var min_x   = start_position.x
		var max_x   = start_position.x + move_distance
		if new_x > max_x:
			new_x      = max_x
			direction  = -1
		elif new_x < min_x:
			new_x      = min_x
			direction  = 1
		global_position.x = new_x
