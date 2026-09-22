extends CanvasLayer
## Camada persistente do filtro de daltonismo (autoload ColorBlindLayer).
## O estado continua em global_accesibility_signal (addon); aqui só se desenha.

const FILTER_LAYER: int = 120   # acima do HUD (1) e do balão de diálogo (100)
const NORMAL_INDEX: int = 0     # item "Normal" de colorblind_optionbutton.tscn

func _ready() -> void:
	layer = FILTER_LAYER
	global_accesibility_signal.change_shader.connect(_on_change_shader)
	_refresh_visibility()

func _on_change_shader(_shader: Shader) -> void:
	_refresh_visibility()

func _refresh_visibility() -> void:
	visible = global_accesibility_signal.color_blind_selected != NORMAL_INDEX
