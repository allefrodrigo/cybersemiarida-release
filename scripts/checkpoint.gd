class_name Checkpoint
extends Area2D
## Poste com sino (spec 007, H1). Origem = base do poste, no chão. Ativa ao ser cruzado (sem tecla), em qualquer estado,
## do chão até ACTIVATION_REACH acima da base. Não trava o Timby. Neutro: sem símbolo, nome ou texto.

signal activated(checkpoint: Checkpoint)

const ACTIVATION_REACH: float = 96.0       # px acima da base em que os pés ainda ativam (H1.2)
const LINE_HALF_WIDTH: float = 2.0         # meia largura da linha (px); o corpo do Timby tem 13 px
const PLAYER_HALF_HEIGHT: float = 10.0     # colisão do Timby 13×20: pés = origem + 10
const ANIM_INACTIVE: StringName = &"inativo"
const ANIM_ACTIVATING: StringName = &"ativacao"
const ANIM_ACTIVE: StringName = &"ativo"

@export var order: int = 1                 # posição na rota da fase (1, 2, 3): o maior ativo é o renascer
@export var facing_right: bool = true      # sentido da rota (o Timby renasce olhando para ele)
@export var spawn_ahead: float = 16.0      # px à frente do poste, no sentido da rota, onde os pés tocam o chão

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sfx: AudioStreamPlayer = $Sfx
@onready var line_shape: CollisionShape2D = $CollisionShape2D

var is_active: bool = false

func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(LINE_HALF_WIDTH * 2.0, ACTIVATION_REACH + PLAYER_HALF_HEIGHT * 2.0)
	line_shape.shape = rect
	line_shape.position = Vector2(0.0, -rect.size.y * 0.5)   # da base até REACH + a altura do corpo (pés ≤ 96)
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(ANIM_INACTIVE)

func respawn_position() -> Vector2:
	var dir: float = 1.0 if facing_right else -1.0
	return global_position + Vector2(spawn_ahead * dir, -PLAYER_HALF_HEIGHT)

func level_path() -> String:
	var lvl: Node = owner if owner != null else get_tree().current_scene
	return lvl.scene_file_path if lvl != null else ""

func _on_body_entered(body: Node2D) -> void:
	if is_active or not body is Player:
		return
	is_active = true
	CheckpointManager.activate(level_path(), order, respawn_position(), facing_right)
	sfx.play()
	sprite.play(ANIM_ACTIVATING)
	activated.emit(self)

func _on_animation_finished() -> void:
	if sprite.animation == ANIM_ACTIVATING:
		sprite.play(ANIM_ACTIVE)
