# falling_plataform.gd
extends AnimatableBody2D

@export var reset_timer: float = 3.0
@export var platform_texture: Texture2D

@onready var anim           = $anim as AnimationPlayer
@onready var respawn_timer  = $respawn_timer as Timer
@onready var respawn_position = global_position
@onready var sprite         = $texture as Sprite2D

var velocity := Vector2.ZERO
var gravity  = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_triggered := false

func _ready() -> void:
	sprite.texture = platform_texture
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

func has_collided_with(collision: KinematicCollision2D, collider: CharacterBody2D) -> void:
	if not is_triggered:
		is_triggered = true
		anim.play("shake")
		velocity = Vector2.ZERO
		if collider.has_method("shake_camera"):
			collider.shake_camera(8, 0.3)

func _on_anim_animation_finished(anim_name: StringName) -> void:
	set_physics_process(true)
	respawn_timer.start(reset_timer)

func _on_respawn_timer_timeout() -> void:
	set_physics_process(false)
	global_position = respawn_position
	if is_triggered:
		var spawn_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
		spawn_tween.tween_property(sprite, "scale", Vector2(1,1), 0.2).from(Vector2(0,0))
	is_triggered = false
