extends Node2D

@export var next_scene: String    = "res://levels/release/caf_03_dg.tscn"
@export var fall_duration: float = 5.0
@export var fall_speed: float    = 400.0
@export var spin_speed: float    = 360.0

@onready var wind = $GPUParticles2D

func _ready() -> void:
	_setup_speedlines()
	$FallSound.play()
	$Player.set_physics_process(false)
	$Player.set_process(false)

	var sprite = $Player.get_node("Sprite") as AnimatedSprite2D
	sprite.play("fall")

	wind.global_position = $Player.global_position
	wind.emitting = true

	# === restaura a transição de cor de verde → azul ===
	$ColorRect.color = Color8(0x0f, 0x55, 0x3e)  # cor inicial
	create_tween().tween_property(
		$ColorRect, "color",
		Color8(0x00, 0x1a, 0x40),               # cor final
		fall_duration
	)

	var t = Timer.new()
	t.one_shot = true
	t.wait_time = fall_duration
	add_child(t)
	t.timeout.connect(self._on_fall_timer_timeout)
	t.start()

func _setup_speedlines() -> void:
	wind.texture     = preload("res://particles/speedline.png")
	wind.amount      = 100
	wind.lifetime    = fall_duration * 0.1

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(200, 0, 0)
	mat.direction            = Vector3(0, -1, 0)
	mat.spread               = deg_to_rad(2)
	mat.gravity              = Vector3.ZERO

	mat.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, fall_speed * 2)
	mat.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, fall_speed * 3)
	mat.set_param_min(ParticleProcessMaterial.PARAM_SCALE, 1)
	mat.set_param_max(ParticleProcessMaterial.PARAM_SCALE, 1)

	wind.process_material = mat

func _physics_process(delta: float) -> void:
	wind.global_position = $Player.global_position
	$Player.rotation_degrees += spin_speed * delta

func _on_fall_timer_timeout() -> void:
	wind.emitting = false
	get_tree().change_scene_to_file(next_scene)
