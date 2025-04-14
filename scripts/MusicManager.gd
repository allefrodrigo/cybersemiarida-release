extends AudioStreamPlayer

func _ready():
	# Carregue a música e chame play_song()
	var song = load("res://assets/Music/bg_mundo1.wav") as AudioStream
	if song == null:
		print("Erro: Não foi possível carregar a música.")
	else:
		play_song(song, "Nome da Música", "Nome do Artista")

func play_song(song_resource: AudioStream, song_name: String, artist_name: String) -> void:
	print("Iniciando reprodução:", song_name, "-", artist_name)
	self.stream = song_resource
	self.play()
	print("Está tocando:", self.is_playing())
	var ui_overlay = get_node("../CanvasLayer")
	if ui_overlay == null:
		print("Erro: ui_overlay é null.")
	else:
		ui_overlay.show_now_playing(song_name, artist_name)
