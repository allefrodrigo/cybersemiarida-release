extends Node2D

@onready var player = $Player  # Referência ao nó do jogador

func _ready():
	$Fade/Fade_transatision/AnimationPlayer.play("fade_out")

	# Conectando os sinais das flags
	for checkpoint in $Flags.get_children():
		checkpoint.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))

	# Conectando os sinais das fallzones
	for fallzone in $Fallzones.get_children():
		fallzone.connect("fallzone_triggered", Callable(self, "_on_fallzone_triggered"))

func _on_checkpoint_activated(position: Vector2, checkpoint_id: int):
	print("Checkpoint ativado:", checkpoint_id, "na posição:", position)

func _on_fallzone_triggered(fallzone_name: String):
	print("Player caiu na fallzone:", fallzone_name)
	# Opcional: Implementar lógica para reposicionar o jogador
	respawn_player()

func respawn_player():
	var checkpoint_data = CheckpointManager.get_checkpoint()
	if checkpoint_data["position"]:
		print("Respawnando jogador no último checkpoint:", checkpoint_data["position"])
		player.global_position = checkpoint_data["position"]
	else:
		print("Nenhum checkpoint salvo. Respawnando na posição inicial.")
		player.global_position = Vector2(0, 0)  # Defina a posição inicial padrão
