extends Area2D
## Porteira de sucata no fim da fase. Origem = chão, no meio da porteira (arte em art/_gerado/goal_porteira/).
## A porteira fica na diagonal: o Timby passa na frente do 1º mourão e da folha (Fundo) e some atrás do 2º (Frente).
## Por isso o nó Goal tem que vir ANTES do player na cena da fase; a Frente usa z_index 1 para ficar na frente dele.

const ANIM_CLOSED: StringName = &"fechada"
const ANIM_OPENING: StringName = &"abrindo"
const ANIM_OPEN: StringName = &"aberta"
const STOP_TIME: float = 0.3       # s parado na frente da porteira enquanto a tramela pula
const WALK_TIME: float = 1.2       # s andando antes do fade (total 1,5 s, como no sino)

@export_file("*.tscn") var next_scene_path: String

# Nós filhos de Goal:
# ├─ CollisionShape2D (área de toque antes do 1º mourão: o Timby freia ~19 px e para logo antes dele)
# ├─ Fundo / Frente   (AnimatedSprite2D: fechada → abrindo → aberta)
# ├─ FadeOutRect      (ColorRect preto alpha=0, z_index 10)
# └─ Sfx              (AudioStreamPlayer, sfx_porteira.ogg)
@onready var fade_out_rect: ColorRect     = $FadeOutRect
@onready var sfx: AudioStreamPlayer       = $Sfx
@onready var back_sprite: AnimatedSprite2D  = $Fundo
@onready var front_sprite: AnimatedSprite2D = $Frente

var reached: bool = false

func _ready() -> void:
	# Inicializa o fade invisível
	fade_out_rect.visible = false
	fade_out_rect.color   = Color(0, 0, 0, 0)
	body_entered.connect(_on_body_entered)
	back_sprite.animation_finished.connect(_on_animation_finished)
	_play(ANIM_CLOSED)
	_check_drawn_behind_player.call_deferred()


func _play(anim: StringName) -> void:
	back_sprite.play(anim)
	front_sprite.play(anim)


func _on_animation_finished() -> void:
	if back_sprite.animation == ANIM_OPENING:
		_play(ANIM_OPEN)


## O Fundo só fica atrás do Timby se o Goal vier antes do player entre os irmãos (todos em z 0).
func _check_drawn_behind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.get_parent() == get_parent() and player.get_index() < get_index():
		push_warning("[GOAL] %s vem depois do player na cena: o fundo da porteira vai cobrir o Timby. Mova o nó Goal para antes do player." % get_path())


func _on_body_entered(body: Node) -> void:
	if reached or not body.is_in_group("player"):
		return
	reached = true
	print("[GOAL] Player chegou! Abrindo a porteira.")
	handle_goal_reached(body)


func handle_goal_reached(player: Node) -> void:
	# 1) Desativa input e para o Timby na frente da porteira
	player.input_enabled         = false
	player.forced_walk_direction = 0
	_play(ANIM_OPENING)
	sfx.play()

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

	# 4) Tramela pula, porteira abre e o Timby atravessa por conta própria
	await get_tree().create_timer(STOP_TIME).timeout
	player.forced_walk_direction = 1
	await get_tree().create_timer(WALK_TIME).timeout

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
