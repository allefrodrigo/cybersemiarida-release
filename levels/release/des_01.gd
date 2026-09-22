extends Node

@onready var player = $Player

func _ready():
	MusicPlayer.play("phase_des")
