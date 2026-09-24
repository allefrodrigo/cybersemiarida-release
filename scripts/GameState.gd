# res://scripts/GameState.gd
class_name GameStateManager
extends Node

var death_count: int = 0
var time_elapsed: float = 0.0
var has_key: bool       = false

## Controles de toque (spec 006, P2 = a): liga se o aparelho se informa como de toque ou no 1º toque real.
signal touch_ui_enabled
var touch_ui: bool = false

func _ready() -> void:
	set_process(true)
	touch_ui = device_reports_touch()

## Se o aparelho tem tela de toque. O DisplayServer.is_touchscreen_available() responde "sim" sempre que a emulação de
## toque pelo mouse está ligada (o nosso caso), também na Web; por isso, na Web, pergunta-se ao navegador (build Web
## local da spec 006, T013/T101). Fora da Web, só celular nativo conta.
const WEB_TOUCH_QUERY: String = "'ontouchstart' in window"

static func device_reports_touch() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval(WEB_TOUCH_QUERY, true))   # o navegador devolve 1/0, não bool (T102)
	return OS.has_feature("mobile")

func _input(event: InputEvent) -> void:
	if touch_ui or not event is InputEventScreenTouch:
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:   # toque emulado pelo clique do mouse não conta (H4.1)
		return
	touch_ui = true
	touch_ui_enabled.emit()

func _process(delta: float) -> void:
	time_elapsed += delta

## Zera o estado da partida (mortes, tempo e chave). O filtro de daltonismo não é zerado.
func reset_run() -> void:
	death_count = 0
	time_elapsed = 0.0
	has_key = false
	CheckpointManager.reset()   # jogo novo: nenhum checkpoint ativo (spec 007, H1.8)
