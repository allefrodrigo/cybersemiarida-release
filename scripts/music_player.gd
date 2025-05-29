extends Node

@export var tracks := {
	"phase1_3": preload("res://audio/phase1_3.ogg"),
	"phase4_5": preload("res://audio/phase4_5.ogg"),
	"phase_city": preload("res://audio/phase_city.ogg"),
	"phase_des": preload("res://audio/phase_des.ogg"),
	"dungeon":   preload("res://audio/dungeon.ogg")
}

var current_group: String = ""
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Music"
	add_child(player)

func play(group_name: String) -> void:
	if current_group == group_name and player.playing:
		return
	if not tracks.has(group_name):
		push_error("[MusicPlayer] Grupo inválido: %s" % group_name)
		return
	if player.playing:
		player.stop()
	
	# Ativa loop no recurso antes de tocar
	var stream_resource = tracks[group_name]
	if stream_resource is AudioStreamOggVorbis:
		stream_resource.loop = true
	
	player.stream = stream_resource
	player.play()
	current_group = group_name
