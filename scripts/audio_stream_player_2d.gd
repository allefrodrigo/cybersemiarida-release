extends AudioStreamPlayer2D

var has_started = false  # Flag para verificar se a música já começou

# Chamado quando o nó entra na árvore de cena pela primeira vez.
func _ready() -> void:
	# Inicia a reprodução
	play()
	print("Tentando iniciar a música...")

# Chamado a cada frame
func _process(delta: float) -> void:
	if playing and not has_started:
		# Verifica se a música começou a tocar
		seek(22)  # Mude para 20.0 se quiser começar no segundo 20
		has_started = true  # Marca que a música já começou
		print("Música iniciada a partir do segundo:", get_playback_position())
