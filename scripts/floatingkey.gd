extends Area2D

signal key_collected

@export var float_amplitude := 15.0
@export var float_speed := 2.0
@export var follow_speed :=10.0


var collected := false
var float_offset := 0.0

var following_player := false
var player_ref: Node2D = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if following_player and player_ref:
		# Lógica de flutuar perto do player
		float_offset += delta * float_speed
		var float_effect = sin(float_offset) * float_amplitude
		var target_pos = player_ref.global_position
		# Ajuste para dar um leve balanço
		target_pos.y += float_effect
		
		global_position = lerp(global_position, target_pos, delta * follow_speed)
	else:
		# Se não estiver seguindo ainda	
		# (aqui entra o flutuar sozinho, se quiser manter)
		float_offset += delta * float_speed
		position.y += sin(float_offset) * float_amplitude * delta


func _on_body_entered (body: Node2D) -> void:
	if body.name == "player" and not collected:
		collected = true
		key_collected.emit()
		hide()
		set_deferred("monitoring", false)

func start_following(player):
	print("start_following")
	following_player = true
	player_ref = player
	show()
