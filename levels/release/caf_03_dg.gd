extends Node2D

func _ready():
	MusicPlayer.play("dungeon")
	var p = $Player
	if p and p.has_method("show_vignette"):
		p.show_vignette(true)
	# resto da inicialização...
