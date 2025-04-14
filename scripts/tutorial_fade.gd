extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var label = $Label
@export var tutorial_text: String = "Digite seu texto aqui"  # Texto configurável no editor
var animation_played = false
var is_visible = false

func _ready():
	label.modulate.a = 0
	label.text = tutorial_text  # Define o texto da Label

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and not animation_played:
		animation_player.play("fade_in_out")
		is_visible = true
		animation_played = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player") and is_visible:
		animation_player.play("fade_out")
		is_visible = false
