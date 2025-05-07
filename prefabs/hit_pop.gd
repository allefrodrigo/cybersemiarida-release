extends Area2D

@export var dialog_texts: Array[String] = []
@export var offset_position: Vector2 = Vector2(0, -20)

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return

	# 1) trava todo input do player
	body.input_enabled = false

	# 2) inicia o diálogo
	DialogManager.start_dialog(dialog_texts, global_position + offset_position)

	# 3) espera o sinal de término do diálogo
	await DialogManager.dialog_finished

	# 4) espera um frame para “consumir” o espaço de fechar
	await get_tree().process_frame

	# 5) reabilita o input sem disparar pulo
	body.input_enabled = true
