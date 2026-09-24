class_name Player
extends CharacterBody2D

@onready var key_holder: Marker2D = $key_holder
var key_instance = null
var KEY_SCENE = preload("res://props/key.tscn")

# --- Corrida (sem mudança) ---
const SPEED: float = 150.0
const ACCELERATION: float = 800.0
const DECELERATION: float = 600.0

# --- Pulo (spec 005, H2) ---
const JUMP_VELOCITY: float = -350.0            # igual a antes: pulo cheio 65,5 px / 112,5 px (restrição dura)
const JUMP_CUT_VELOCITY: float = -170.0        # soltar o pulo subindo: vy fica em no máximo -170 (mínimo ~20 px)
const JUMP_BUFFER_FRAMES: int = 5              # q desde o quadro em que o aperto chega; o teste mede 6–7 q antes do pouso (H2.3)
const COYOTE_FRAMES: int = 10                  # o teste mede 8 q = 0,133 s (H2.4, errata E3 / D2)
const MAX_FALL_SPEED: float = 450.0            # px/s (H2.5)

# --- Parede (spec 005, H1) ---
const WALL_SLIDE_SPEED: float = 60.0           # px/s, teto enquanto desliza
const WALL_CONTACT_DISTANCE: float = 1.5       # px além da colisão para "encostar" (H1.3)
const WALL_JUMP_FORCE: float = 400.0           # igual a antes: (±282,8, −282,8) px/s
const WALL_JUMP_COYOTE_FRAMES: int = 8         # q desde o último quadro encostado; o teste mede 6 q (H1.4)
const WALL_JUMP_LOCK_FRAMES: int = 7           # 0,12 s sem efeito da direção depois do wall jump (H1.4)

const FRAME_COUNTER_MAX: int = 999               # teto dos contadores de quadros ("longe demais"; plano 005 §4.4)
const DEATH_ANIMATION: StringName = &"dizzy"     # tontura na sequência de morte (spec 007, H2.1)

@export var sfx_jump : AudioStream
@export var sfx_footstep : AudioStream
@export var sfx_fall : AudioStream
@onready var camera = $Camera2D
# referências à vinheta
@onready var vignette_layer: CanvasLayer    = $CanvasLayer
@onready var vignette_rect:  ColorRect      = $CanvasLayer/Vignette
var shader_mat: ShaderMaterial

var footstep_frames : Array = [2, 5]
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var was_on_floor = false

# --- NOVOS CONTROLES DE INPUT ---
var input_enabled = true
var forced_walk_direction = 0
var initial_position: Vector2

# --- RAYCASTS PARA DETECTAR PAREDE ---
@onready var raycast_wall_left: RayCast2D = $raycast_wall_left
@onready var raycast_wall_right: RayCast2D = $raycast_wall_right
@onready var body_shape: CollisionShape2D = $CollisionShape2D

# Flag para sabermos se estamos deslizando na parede
var is_wall_sliding = false

# Contadores da spec 005 (janelas em quadros de física)
var frames_since_floor: int = FRAME_COUNTER_MAX
var frames_since_jump_press: int = FRAME_COUNTER_MAX
var frames_since_wall: int = FRAME_COUNTER_MAX
var wall_jump_lock_frames_left: int = 0
var last_wall_dir: int = 0          # -1 parede à esquerda, +1 à direita
var wall_dir: int = 0
var is_jump_cuttable: bool = false
var move_x: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var state_label: Label = $Label

func vibrate(duration_ms: int) -> void:
	if OS.has_feature("HTML5") and Engine.has_singleton("JavaScript"):
		Engine.get_singleton("JavaScript").eval("if(navigator.vibrate){navigator.vibrate(" + str(duration_ms) + ");}", "")

func _ready() -> void:
	add_to_group("player")
	print("Grupos do jogador:", get_groups())
	initial_position = global_position
	CheckpointManager.enter_level(level_path())   # outra fase: zera o checkpoint (spec 007, H1.7)
	respawn_if_needed()
	shader_mat           = vignette_rect.material as ShaderMaterial
	vignette_layer.visible = false
	_setup_wall_rays()
	set_process(true)  # para _process rodar

## Raios de parede alinhados à forma de colisão: alcance = meia largura + WALL_CONTACT_DISTANCE (H1.3).
func _setup_wall_rays() -> void:
	var rect := body_shape.shape as RectangleShape2D
	var half_w: float = rect.size.x * 0.5
	var cx: float = body_shape.position.x
	raycast_wall_left.position = Vector2(cx, body_shape.position.y)
	raycast_wall_right.position = Vector2(cx, body_shape.position.y)
	raycast_wall_left.target_position = Vector2(-(half_w + WALL_CONTACT_DISTANCE), 0.0)
	raycast_wall_right.target_position = Vector2(half_w + WALL_CONTACT_DISTANCE, 0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		frames_since_jump_press = FRAME_COUNTER_MAX   # aperto durante a pausa não vira pulo (H3.5)

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()

	apply_gravity(delta, on_floor)
	update_coyote_time(on_floor)
	update_wall_contact(on_floor)
	
	if input_enabled:
		handle_movement(delta)
		handle_wall_slide(on_floor)
		handle_jump(on_floor)
	else:
		frames_since_jump_press = FRAME_COUNTER_MAX   # aperto com o controle travado não vira pulo depois (H2.6)
		is_wall_sliding = false
		# Input desativado mas com direcao forçada
		if forced_walk_direction != 0:
			velocity.x = move_toward(velocity.x, forced_walk_direction * SPEED, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
	
	update_animations(on_floor)
	update_stretch_and_squash(delta, on_floor)

	move_and_slide()

	# Verifica colisões depois do move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)
	
	# Toca som de queda ao pousar
	if not was_on_floor and on_floor:
		load_sfx(sfx_fall)
		$sfx_player.play()
	was_on_floor = on_floor


# ------------------------------------------------------
#                 FUNÇÕES PRINCIPAIS
# ------------------------------------------------------

func apply_gravity(delta: float, on_floor: bool) -> void:
	if not on_floor:
		velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
	else:
		velocity.y = 0

func update_coyote_time(on_floor: bool) -> void:
	if on_floor:
		frames_since_floor = 0
	elif frames_since_floor < FRAME_COUNTER_MAX:
		frames_since_floor += 1

func update_wall_contact(on_floor: bool) -> void:
	wall_dir = 0
	if raycast_wall_right.is_colliding():
		wall_dir = 1
	elif raycast_wall_left.is_colliding():
		wall_dir = -1
	if wall_dir != 0 and not on_floor:
		last_wall_dir = wall_dir
		frames_since_wall = 0
	elif frames_since_wall < FRAME_COUNTER_MAX:
		frames_since_wall += 1

func handle_movement(delta: float) -> void:
	# Obtém um Vector2 combinando teclado e gamepad (-X, +X, -Y, +Y)
	var move_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move_x = move_vec.x
	if wall_jump_lock_frames_left > 0:
		wall_jump_lock_frames_left -= 1
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)   # trava do wall jump: como sem direção
		return
	# Calcula a velocidade-alvo no eixo X
	var target_speed = move_vec.x * SPEED
	if abs(target_speed) > 0.1:
		# Acelera até a velocidade-alvo
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		# Desacelera suavemente até parar
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)

func handle_wall_slide(on_floor: bool) -> void:
	is_wall_sliding = false
	if on_floor or velocity.y <= 0.0 or wall_dir == 0:
		return
	if signf(move_x) == float(wall_dir):   # empurrando CONTRA a parede (H1.1)
		is_wall_sliding = true
		frames_since_floor = FRAME_COUNTER_MAX
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

func handle_jump(on_floor: bool) -> void:
	if Input.is_action_just_pressed("jump"):
		frames_since_jump_press = 0
	elif frames_since_jump_press < FRAME_COUNTER_MAX:
		frames_since_jump_press += 1
	if frames_since_jump_press <= JUMP_BUFFER_FRAMES:
		if frames_since_floor <= COYOTE_FRAMES:
			_do_ground_jump()
		elif not on_floor and frames_since_wall <= WALL_JUMP_COYOTE_FRAMES:
			_do_wall_jump()
	# pulo variável: soltar o botão corta a subida (só no pulo do chão; H2.1)
	if is_jump_cuttable:
		if velocity.y >= 0.0:
			is_jump_cuttable = false
		elif not Input.is_action_pressed("jump") and velocity.y < JUMP_CUT_VELOCITY:
			velocity.y = JUMP_CUT_VELOCITY
			is_jump_cuttable = false

func _do_ground_jump() -> void:
	load_sfx(sfx_jump)
	$sfx_player.play()
	velocity.y = JUMP_VELOCITY
	frames_since_floor = FRAME_COUNTER_MAX
	frames_since_jump_press = FRAME_COUNTER_MAX
	is_jump_cuttable = true
	vibrate(400)

func _do_wall_jump() -> void:
	load_sfx(sfx_jump)
	$sfx_player.play()
	vibrate(400)
	var away: float = -float(last_wall_dir)
	velocity = Vector2(away, -1.0).normalized() * WALL_JUMP_FORCE
	is_wall_sliding = false
	is_jump_cuttable = false
	frames_since_jump_press = FRAME_COUNTER_MAX
	frames_since_wall = FRAME_COUNTER_MAX
	wall_jump_lock_frames_left = WALL_JUMP_LOCK_FRAMES


# ------------------------------------------------------
#                ATUALIZAÇÃO DE ANIMAÇÕES
# ------------------------------------------------------

func update_animations(on_floor: bool) -> void:
	var state = ""

	# Verifica primeiro o wall slide
	if is_wall_sliding:
		animated_sprite.play("wall_slide")
		# vira o sprite pelo lado da parede encostada (wall_dir: -1 esquerda, +1 direita)
		if wall_dir < 0:
			animated_sprite.flip_h = true
		elif wall_dir > 0:
			animated_sprite.flip_h = false
		state = "WallSlide"

	# Se não está em wall slide, segue fluxo normal!!
	elif not on_floor:
		if velocity.y > 0:
			animated_sprite.play("fall")
			state = "Fall"
		else:
			animated_sprite.play("jump")
			state = "Jump"
	else:
		if abs(velocity.x) > 0.1:
			animated_sprite.play("run")
			animated_sprite.flip_h = (velocity.x < 0)
			state = "Run"
		else:
			animated_sprite.play("idle")
			state = "Idle"
	
	# Atualiza o label de estado, se tiver
	if state_label.text != state:
		state_label.text = state


func update_stretch_and_squash(delta: float, on_floor: bool) -> void:
	if not on_floor:
		var target_scale = Vector2.ONE
		if velocity.y < 0:
			target_scale = Vector2(0.95, 1.1)
		else:
			target_scale = Vector2(1.1, 0.95)
		animated_sprite.scale = animated_sprite.scale.lerp(target_scale, 5 * delta)
	else:
		animated_sprite.scale = Vector2.ONE


# ------------------------------------------------------
#            CHECKPOINT / RESPAWN / ETC.
# ------------------------------------------------------

func respawn_if_needed() -> void:
	# só vale para a mesma fase recarregada (mundos legados); nas fases da rota a morte não recarrega a cena
	if CheckpointManager.has_respawn(level_path()):
		global_position = CheckpointManager.get_respawn_position()

## Caminho da fase dona deste Timby (raiz da cena da fase; nos testes a fase pode não ser a current_scene).
func level_path() -> String:
	var lvl: Node = owner if owner != null else get_tree().current_scene
	return lvl.scene_file_path if lvl != null else ""

## Começo da sequência de morte (spec 007, H2.1): a árvore está pausada; só o sprite anima (tontura).
func enter_death() -> void:
	velocity = Vector2.ZERO
	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.play(DEATH_ANIMATION)

func exit_death() -> void:
	animated_sprite.process_mode = Node.PROCESS_MODE_INHERIT

## Renascer (spec 007, H1.3/H2.2): de pé, parado, olhando no sentido da rota; câmera já no lugar, sem viagem.
func respawn_at(pos: Vector2, facing_right: bool) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	frames_since_floor = FRAME_COUNTER_MAX
	frames_since_jump_press = FRAME_COUNTER_MAX
	frames_since_wall = FRAME_COUNTER_MAX
	wall_jump_lock_frames_left = 0
	is_jump_cuttable = false
	is_wall_sliding = false
	animated_sprite.flip_h = not facing_right
	animated_sprite.play("idle")
	animated_sprite.scale = Vector2.ONE
	camera.reset_smoothing()
	camera.force_update_scroll()
	if key_instance != null and is_instance_valid(key_instance):
		key_instance.global_position = global_position   # a chave não atravessa o mapa atrás do Timby

func load_sfx(sfx_to_load):
	if $sfx_player.stream != sfx_to_load:
		$sfx_player.stop()
		$sfx_player.stream = sfx_to_load

func _on_sprite_frame_changed() -> void:
	if $Sprite.animation == "idle": return
	if $Sprite.animation == "jump": return
	load_sfx(sfx_footstep)
	if $Sprite.frame in footstep_frames:
		$sfx_player.play()
		vibrate(50)

func shake_camera(intensity: float = 8.0, duration: float = 0.3) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var shakes = 8
	var original_offset = camera.offset
	var shake_tween = create_tween()
	for i in range(shakes):
		var random_offset = Vector2(
			rng.randf_range(-intensity, intensity),
			rng.randf_range(-intensity, intensity)
		)	
		shake_tween.tween_property(camera, "offset", random_offset, duration / (shakes * 2))
		shake_tween.tween_property(camera, "offset", original_offset, duration / (shakes * 2))
	shake_tween.tween_callback(Callable(self, "_restore_camera_offset"))

func _restore_camera_offset() -> void:
	camera.offset = Vector2.ZERO


# ------------------------------------------------------
#           MECÂNICA DE PEGAR/GERAR A CHAVE
# ------------------------------------------------------

func collect_key():
	if key_instance:
		return
	key_instance = KEY_SCENE.instantiate()
	get_tree().current_scene.call_deferred("add_child", key_instance)
	key_instance.global_position = global_position + Vector2(-50, -50)
	key_instance.show()
	key_instance.set_deferred("monitoring", false)
	key_instance.start_following(key_holder)

func _on_keynote_key_collected() -> void:
	print("key_collect")
	collect_key()

func respawn_to_initial() -> void:
	GameState.death_count += 1
	print(GameState.death_count)
	global_position = initial_position
	velocity = Vector2.ZERO


# roda todo frame para atualizar a vinheta
func _process(_delta: float) -> void:
	if not vignette_layer.visible or shader_mat == null:
		return

	# 1) pega tamanho da tela em pixels
	var vs   = get_viewport().get_visible_rect().size
	# 2) calcula canto superior-esquerdo da view em world-space
	var cam_pos  = camera.global_position
	var top_left = cam_pos - vs * 0.5
	# 3) obtém posição do player em pixels dentro da view
	var pixel    = global_position - top_left
	# 4) normaliza X e Y (SCREEN_UV.y=0 é bottom, então invertemos Y)
	var uv = Vector2(
		pixel.x / vs.x,
		1.0 - (pixel.y / vs.y)
	)
	shader_mat.set_shader_parameter("player_pos", uv)

# chame isto para ligar/desligar a vinheta
func show_vignette(on: bool) -> void:
	vignette_layer.visible = on
