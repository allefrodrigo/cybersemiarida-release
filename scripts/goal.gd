extends Area2D

@export_file("*.tscn") var next_scene_path: String

# Nós filhos de Goal:
# ├─ CollisionShape2D
# ├─ FadeOutRect (ColorRect full-screen, cor preta alpha=0)
# └─ BellPlayer   (AudioStreamPlayer, Stream apontando para bell-goal.ogg)
@onready var fade_out_rect: ColorRect         = $FadeOutRect
@onready var bell_player: AudioStreamPlayer2D = $BellPlayer

func _ready() -> void:
	# Inicializa o fade invisível
	fade_out_rect.visible = false
	fade_out_rect.color   = Color(0, 0, 0, 0)
	# Conecta detecção de colisão
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Toca o sino
		bell_player.play()
		print("[GOAL] Player entrou! Tocando sino e iniciando rotina.")
		handle_goal_reached(body)


func handle_goal_reached(player: Node) -> void:
	print("[GOAL] handle_goal_reached iniciado. Desativando controles e forçando movimento.")

	# 1) Desativa input e força movimento do player
	player.input_enabled       = false
	player.forced_walk_direction = 1

	# 2) Desativa a câmera do player (se estiver ativa)
	var player_camera = player.get_node_or_null("Camera2D")
	if player_camera and player_camera.is_current():
		player_camera.set_process_mode(Camera2D.PROCESS_MODE_DISABLED)

	# 3) Ativa a câmera fixa (se existir)
	var fixed_camera = get_parent().get_node_or_null("CameraFixed")
	if fixed_camera:
		fixed_camera.make_current()
	else:
		print("[GOAL] Câmera fixa não encontrada. Pulando espera.")

	# 4) Aguarda 1.5s antes de começar o fade
	await get_tree().create_timer(1.5).timeout

	# 5) Fade-out  
	print("[GOAL] Iniciando fade-out")
	fade_out_rect.visible = true
	fade_out_rect.color   = Color(0, 0, 0, 0)
	var tw = create_tween()
	tw.tween_property(
		fade_out_rect,
		"color:a",    # anima só o alpha
		1.0,          # opaco
		1.0           # duração 1s
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	print("[GOAL] Fade-out completo.")

	# 6) Se houver câmera fixa, espera o player sair do viewport
	if fixed_camera:
		print("[GOAL] Esperando player sair do viewport…")
		await wait_until_player_leaves_screen(player, fixed_camera)
		print("[GOAL] Player saiu do viewport.")

	# 7) Troca de cena
	print("[GOAL] Mudando para:", next_scene_path)
	if next_scene_path.is_empty():
		push_error("[GOAL] ERRO: next_scene_path não foi definido!")
		return
	get_tree().change_scene_to_file(next_scene_path)


func wait_until_player_leaves_screen(player: Node, fixed_camera: Camera2D) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	while true:
		var local_pos = fixed_camera.to_local(player.global_position)
		if not Rect2(Vector2.ZERO, viewport_size).has_point(local_pos):
			break
		await get_tree().process_frame
