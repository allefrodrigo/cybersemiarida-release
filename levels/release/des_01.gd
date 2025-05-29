extends Node

@onready var player = $player

func _ready():
	MusicPlayer.play("phase_des")
