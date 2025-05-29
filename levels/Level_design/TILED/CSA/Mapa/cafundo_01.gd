extends Node

@onready var player = $player

func _ready():
	MusicPlayer.play("phase1_3")

	# Desabilita o controle do player enquanto o diálogo não acaba
	#player.set_process_input(false)
	#player.set_physics_process(false)
	
	# Conecta o sinal de término do diálogo para reabilitar o jogador
#	DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_finished"))
	
	# Exibe o diálogo carregado a partir do arquivo
#	DialogueManager.show_dialogue_balloon(load("res://dialogos/dialogue.dialogue"))

#func _on_dialogue_finished(resource: Resource) -> void:
	# Quando o diálogo terminar, libera o controle do jogador
	#player.set_process_input(true)
	#player.set_physics_process(true)
