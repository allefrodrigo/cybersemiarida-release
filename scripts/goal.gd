extends Area2D

@export_file("*.tscn") var next_scene_path: String

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Deixe o ColorRect visível desde o início
	color_rect.visible = true
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("[GOAL] Player entrou no goal! handle_goal_reached() chamado.")
		handle_goal_reached(body)

func handle_goal_reached(player: Node) -> void:
	print("[GOAL] handle_goal_reached iniciado. Desativando input e forçando movimento.")

	# Desativa o efeito do shader, tornando o ColorRect invisível
	color_rect.visible = false

	# Desativa input e força movimento do player
	player.input_enabled = false
	player.forced_walk_direction = 1

	# Desativa a câmera do player
	var player_camera = player.get_node_or_null("Camera2D")
	if player_camera and player_camera.is_current():
		player_camera.set_process_mode(Camera2D.PROCESS_MODE_DISABLED)

	# Tenta obter a câmera fixa
	var fixed_camera = get_parent().get_node_or_null("CameraFixed")
	if fixed_camera:
		fixed_camera.make_current()
	else:
		print("[GOAL] Câmera fixa não encontrada. Pulando espera.")
	
	# Aguarda um tempo antes de checar se o player saiu do viewport
	await get_tree().create_timer(1.5).timeout

	# Se a câmera fixa existir, espera o player sair da tela
	if fixed_camera:
		await wait_until_player_leaves_screen(player, fixed_camera)
		print("[GOAL] Player saiu do viewport.")

	print("[GOAL] Mudando para a próxima cena.")
	if next_scene_path.is_empty():
		push_error("[GOAL] ERRO: next_scene_path não foi definido!")
		return

	get_tree().change_scene_to_file(next_scene_path)

func wait_until_player_leaves_screen(player: Node, fixed_camera: Camera2D) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	print("[GOAL] Iniciando loop para checar se player saiu do viewport da câmera fixa.")
	while true:
		# Converte a posição global do player para o espaço local da câmera fixa
		var local_pos = fixed_camera.to_local(player.global_position)
		var screen_rect = Rect2(Vector2.ZERO, viewport_size)

		if not screen_rect.has_point(local_pos):
			print("[GOAL] Player saiu do viewport!")
			break

		await get_tree().process_frame
	print("[GOAL] Encerrando loop de espera (player saiu do viewport).")
