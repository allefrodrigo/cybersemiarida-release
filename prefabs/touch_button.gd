class_name TouchButton
extends Sprite2D
## Um botão de toque dos controles (spec 006): desenho + área de toque fixa + ação do InputMap.

const REST_ALPHA: float = 0.6       # repouso: deixa ver o cenário (spec §5, 60 % ± 10 %)
const PRESSED_ALPHA: float = 1.0    # apertado: opaco

@export var action: StringName = &""
@export var texture_pressed: Texture2D
@export var texture_rest: Texture2D
## Deslocamento do desenho apertado. Placeholder (tiles do Buttons_2): (0, 2). Arte final com a face já 2 px abaixo: (0, 0).
@export var pressed_shift: Vector2 = Vector2(0, 2)
@export var hit_size: Vector2 = Vector2(32, 32)

var rest_position: Vector2
var is_held: bool = false

func _ready() -> void:
	centered = false
	rest_position = position
	if texture_rest == null:
		texture_rest = texture
	set_look(false)

func hit_rect() -> Rect2:
	return Rect2(rest_position, hit_size)

func set_look(held: bool) -> void:
	texture = texture_pressed if held and texture_pressed != null else texture_rest
	position = rest_position + (pressed_shift if held else Vector2.ZERO)
	modulate.a = PRESSED_ALPHA if held else REST_ALPHA
