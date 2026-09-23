extends Node

signal dialog_finished

const DIALOG_LAYER: int = 100   # acima do HUD (1); abaixo do ColorBlindLayer (120)
const SCREEN_MARGIN: int = 4    # px entre o balão e a borda de baixo da tela

@export var dialog_scene: PackedScene
var dialog_box: Node = null
var dialog_layer: CanvasLayer = null
var is_showing_dialog: bool = false

## O balão fica fixo na tela, centralizado embaixo, fora do HUD (spec 003, T101).
## dialog_position é mantido na assinatura por compatibilidade com hit_pop.gd.
func start_dialog(texts: Array[String], _dialog_position: Vector2) -> void:
	if is_showing_dialog:
		return
	if dialog_scene == null:
		push_error("dialog_scene não foi atribuído no inspetor")
		return

	# instancia e configura a caixa de diálogo
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = DIALOG_LAYER
	get_tree().current_scene.add_child(dialog_layer)
	dialog_box = dialog_scene.instantiate()
	dialog_layer.add_child(dialog_box)
	dialog_box.texts_to_display = texts
	# âncora no centro de baixo da tela; cresce para os lados e para cima conforme as linhas
	dialog_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_box.offset_left = 0.0
	dialog_box.offset_right = 0.0
	dialog_box.offset_top = -SCREEN_MARGIN
	dialog_box.offset_bottom = -SCREEN_MARGIN
	dialog_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_box.show_text()
	is_showing_dialog = true

	# conecta o sinal do dialog_box usando um Callable
	# em vez de passar (self, "nome_do_metodo")
	dialog_box.dialog_finished.connect(Callable(self, "_on_box_finished"))


func _on_box_finished() -> void:
	is_showing_dialog = false
	if dialog_box:
		dialog_box.queue_free()
		dialog_box = null
	if dialog_layer:
		dialog_layer.queue_free()
		dialog_layer = null

	# emite o sinal do manager para quem esteja aguardando
	emit_signal("dialog_finished")
