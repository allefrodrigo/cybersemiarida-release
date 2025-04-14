class_name Player
extends CharacterBody2D

@onready var key_holder: Marker2D = $key_holder
var key_instance = null
var KEY_SCENE = preload("res://props/key.tscn")

# Ajuste os valores de velocidade e força de jump conforme achar melhor.
const SPEED = 150.0
const JUMP_VELOCITY = -350.0
const ACCELERATION = 800.0
const DECELERATION = 600.0
const COYOTE_TIME = 0.2

# --- FORÇAS ESPECÍFICAS PARA WALL SLIDE E WALL JUMP ---
const WALL_SLIDE_SPEED = 60.0       # Velocidade vertical (máx) ao deslizar
const WALL_JUMP_HORIZONTAL = 200.0  # Força horizontal do wall jump (você pode ajustar)
# ----------------------------------
const WALL_JUMP_FORCE = 400.0  # Ajuste conforme o comportamento desejado

@export var sfx_jump : AudioStream
@export var sfx_footstep : AudioStream
@export var sfx_fall : AudioStream
@onready var camera = $Camera2D

var footstep_frames : Array = [2, 5]
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var coyote_time_counter = 0.0
var was_on_floor = false

# --- NOVOS CONTROLES DE INPUT ---
var input_enabled = true
var forced_walk_direction = 0

# --- RAYCASTS PARA DETECTAR PAREDE ---
@onready var raycast_wall_left: RayCast2D = $raycast_wall_left
@onready var raycast_wall_right: RayCast2D = $raycast_wall_right

# Flag para sabermos se estamos deslizando na parede
var is_wall_sliding = false

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var state_label: Label = $Label

func vibrate(duration_ms: int) -> void:
	if OS.has_feature("HTML5") and Engine.has_singleton("JavaScript"):
		Engine.get_singleton("JavaScript").eval("if(navigator.vibrate){navigator.vibrate(" + str(duration_ms) + ");}", "")

func _ready() -> void:
	add_to_group("player")
	print("Grupos do jogador:", get_groups())
	respawn_if_needed()

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()

	apply_gravity(delta, on_floor)
	update_coyote_time(delta, on_floor)
	
	if input_enabled:
		handle_movement(delta)
		handle_wall_slide(delta)
		handle_jump()
	else:
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
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func update_coyote_time(delta: float, on_floor: bool) -> void:
	if on_floor:
		coyote_time_counter = COYOTE_TIME
	else:
		coyote_time_counter = max(coyote_time_counter - delta, 0)

func handle_movement(delta: float) -> void:
	var direction = Input.get_axis("ui_left", "ui_right")
	var target_speed = direction * SPEED

	if abs(target_speed) > 0.1:
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)


func handle_wall_slide(delta: float) -> void:
	is_wall_sliding = false

	# Se não está no chão e está caindo (velocity.y > 0)...
	if not is_on_floor() and velocity.y > 0:
		# Verifica se está pressionando esquerda e colidindo com a parede esquerda
		if Input.get_action_strength("ui_left") > 0 and raycast_wall_left.is_colliding():
			is_wall_sliding = true
		# Ou se está pressionando direita e colidindo com a parede direita
		elif Input.get_action_strength("ui_right") > 0 and raycast_wall_right.is_colliding():
			is_wall_sliding = true

	# Ao deslizar na parede, limitamos a velocidade vertical
	if is_wall_sliding:
		# Zera coyote time, para não permitir jump "normal" ao invés de wall jump
		coyote_time_counter = 0
		if velocity.y > WALL_SLIDE_SPEED:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, 300 * delta)

func handle_jump() -> void:
	# Pulo normal (quando está no chão ou com coyote time) e não está em wall slide
	if Input.is_action_just_pressed("ui_accept") and coyote_time_counter > 0 and not is_wall_sliding:
		load_sfx(sfx_jump)
		$sfx_player.play()
		velocity.y = JUMP_VELOCITY
		coyote_time_counter = 0
		vibrate(400)
		return

	# Wall jump: somente dispara se estiver em wall slide
	if is_wall_sliding and Input.is_action_just_pressed("ui_accept"):
		load_sfx(sfx_jump)
		$sfx_player.play()
		vibrate(400)
		var jump_impulse: Vector2 = Vector2.ZERO
		# Se o player estiver encostado na parede da esquerda, força o impulso para a direita e para cima
		if raycast_wall_left.is_colliding():
			jump_impulse = Vector2(1, -1).normalized() * WALL_JUMP_FORCE
		# Se estiver encostado na parede da direita, força o impulso para a esquerda e para cima
		elif raycast_wall_right.is_colliding():
			jump_impulse = Vector2(-1, -1).normalized() * WALL_JUMP_FORCE
		velocity = jump_impulse
		is_wall_sliding = false
		return


# ------------------------------------------------------
#                ATUALIZAÇÃO DE ANIMAÇÕES
# ------------------------------------------------------

func update_animations(on_floor: bool) -> void:
	var state = ""

	# Verifica primeiro o wall slide
	if is_wall_sliding:
		animated_sprite.play("wall_slide")
		# Se quiser que o sprite fique "olhando" pra direita quando na parede esquerda, basta ajustar:
		if raycast_wall_left.is_colliding():
			animated_sprite.flip_h = true
		elif raycast_wall_right.is_colliding():
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
	var checkpoint_data = CheckpointManager.get_checkpoint()
	if checkpoint_data.has("position") and checkpoint_data["position"]:
		global_position = checkpoint_data["position"]
		health = CheckpointManager.player_data["health"]
		print("Respawned at:", checkpoint_data["position"])

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
