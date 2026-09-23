class_name TouchControls
extends CanvasLayer
## Controles de toque (spec 006). Mora dentro do HUD; aparece só em tela de toque e só quando o Timby obedece.
## Cada dedo (índice do InputEventScreenTouch) é seguido; o botão fica apertado enquanto algum dedo está nele.

## Dispositivo próprio dos eventos de ação do toque: soltar um dedo não solta a mesma ação segurada no teclado
## (Input.action_release limparia todos os dispositivos).
const TOUCH_DEVICE_ID: int = -3

var _fingers: Dictionary = {}          # índice do dedo (int) -> TouchButton sob ele, ou null
var _buttons: Array[TouchButton] = []
var _player: Player = null

func _ready() -> void:
	for c in get_children():
		if c is TouchButton:
			_buttons.append(c as TouchButton)
	visible = false
	_update_visibility()

## Troca de cena com um dedo num botão (🏠, sino, elevador): a ação não pode ficar presa na cena seguinte.
func _exit_tree() -> void:
	release_all()

func _physics_process(_delta: float) -> void:   # o HUD processa sempre (pausa inclusive)
	_update_visibility()

func should_show() -> bool:
	if not GameState.touch_ui or get_tree().paused or DialogManager.is_showing_dialog:
		return false
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	return _player != null and _player.input_enabled

func _update_visibility() -> void:
	var want: bool = should_show()
	if want == visible:
		return
	if not want:
		release_all()          # dedo que estava na tela não continua valendo depois (H2.4, H3.3)
	visible = want

func release_all() -> void:
	_fingers.clear()
	_sync()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and not st.canceled:
			_fingers[st.index] = _button_at(st.position)
		else:
			_fingers.erase(st.index)
		_sync()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _fingers.has(sd.index):   # só dedos que começaram com os controles visíveis
			_fingers[sd.index] = _button_at(sd.position)
			_sync()

func _button_at(p: Vector2) -> TouchButton:
	for b in _buttons:
		if b.hit_rect().has_point(p):
			return b
	return null

func _sync() -> void:
	var held_now: Array = _fingers.values()
	for b in _buttons:
		var held: bool = held_now.has(b)
		if held == b.is_held:
			continue
		b.is_held = held
		b.set_look(held)
		var e := InputEventAction.new()
		e.action = b.action
		e.pressed = held
		e.strength = 1.0 if held else 0.0
		e.device = TOUCH_DEVICE_ID
		Input.parse_input_event(e)   # dentro do _input: entra no mesmo lote de eventos, mesmo quadro de física
