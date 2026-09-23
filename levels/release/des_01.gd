extends Node

@onready var player: Player = $Player
@onready var hud: GameHud = $Hud
@onready var elevator: Elevator = $Elevator

func _ready() -> void:
	MusicPlayer.play("phase_des")
	elevator.sequence_started.connect(hud.lock_buttons)
