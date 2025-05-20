extends Node

@onready var player = $player

func _ready():
	MusicPlayer.play("phase1_3")
