extends CanvasLayer

var color_rect
var song_label

func _ready():
	color_rect = $ColorRect
	song_label = color_rect.get_node("Label")
	color_rect.visible = true

func show_now_playing(song_name: String, artist_name: String) -> void:
	print("Exibindo Now Playing:", song_name, "-", artist_name)
	song_label.text = "Tocando agora: %s - %s" % [song_name, artist_name]
	color_rect.visible = true
	await get_tree().create_timer(5).timeout  # Correção aqui
	color_rect.visible = false
