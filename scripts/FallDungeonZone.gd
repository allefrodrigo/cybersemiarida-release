extends Area2D

@export var destination_scene: String = "res://scenes/caf_fall_dg.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file(destination_scene)
