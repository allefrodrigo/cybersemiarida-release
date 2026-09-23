extends MarginContainer

signal dialog_finished()

var texts_to_display: Array[String] = []
var current_index : int = 0
var typing_speed : float = 0.05
var is_typing : bool = false

@onready var text_label: Label = $text_container/text_label
@onready var indicator: TextureRect = $indicator
@onready var tween : Tween = get_tree().create_tween()

func _ready() -> void:
	pivot_offset = size / 2
	self.scale = Vector2.ZERO
	indicator.visible = false

	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

		
func show_text():
	if current_index < texts_to_display.size():
		is_typing = true
		indicator.visible = false
		text_label.text = ""
		_type_text(texts_to_display[current_index])
	else:
		_close_dialog()
		
func _type_text(text: String):
	for i in range(text.length()):
		text_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
	indicator.visible = true
	get_tree().paused = true
	
func _close_dialog():
	is_typing = true
	tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
	await tween.finished
	dialog_finished.emit()
	queue_free()
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and can_advance():
		advance()

## Toque (ou clique do mouse, que vira toque emulado) em qualquer ponto fora do ⏸ e do 🏠 (spec 006, H2.1).
## Só o começo de um toque conta: dedo que já estava na tela não avança nem ao ser solto.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and can_advance() and not _is_over_hud_button(event.position):
		advance()

## ▼ visível: a página terminou de ser escrita e o balão não está fechando.
func can_advance() -> bool:
	return not is_typing and indicator.visible

func advance() -> void:
	if current_index + 1 < texts_to_display.size():
		current_index += 1
		show_text()          # is_typing = true já aqui: um 2º dedo no mesmo quadro não avança outra página
	else:
		get_tree().paused = false
		_close_dialog()

func _is_over_hud_button(p: Vector2) -> bool:
	for hud in get_tree().get_nodes_in_group(&"game_hud"):
		if hud.has_method("is_over_buttons") and hud.is_over_buttons(p):
			return true
	return false
