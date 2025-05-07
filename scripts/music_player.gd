extends Node

@export var tracks := {
	"phase1_3": preload("res://audio/phase1_3.ogg"),
	"phase4_5": preload("res://audio/phase4_5.ogg"),
	"dungeon":   preload("res://audio/dungeon.ogg")
}

var current_group: String = ""
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Music"  # opcional: defina um bus separado

func play(group_name: String) -> void:
	if current_group == group_name:
		return
	if player.playing:
		player.stop()
	if tracks.has(group_name):
		player.stream = tracks[group_name]
		player.play()
		current_group = group_name
	else:
		push_error("[MusicPlayer] Grupo inválido: %s" % group_name)
