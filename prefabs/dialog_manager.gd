extends Node

signal dialog_finished

@export var dialog_scene: PackedScene
var dialog_box: Node = null
var is_showing_dialog: bool = false

func start_dialog(texts: Array[String], dialog_position: Vector2) -> void:
	if is_showing_dialog:
		return
	if dialog_scene == null:
		push_error("dialog_scene não foi atribuído no inspetor")
		return

	# instancia e configura a caixa de diálogo
	dialog_box = dialog_scene.instantiate()
	get_tree().current_scene.add_child(dialog_box)
	dialog_box.texts_to_display = texts
	dialog_box.global_position = dialog_position
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

	# emite o sinal do manager para quem esteja aguardando
	emit_signal("dialog_finished")
