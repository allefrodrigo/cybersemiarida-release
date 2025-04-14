extends Area2D

@export var world_name: String  # Nome do mundo ou fase
@export var checkpoint_id: int  # ID único do checkpoint
signal checkpoint_activated  # Sinal para notificar o CheckpointManager

func _ready():
	add_to_group("checkpoints")  # Opcional: Adiciona a flag ao grupo "checkpoints"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Verifica se o jogador ativou o checkpoint
		emit_signal("checkpoint_activated", global_position, checkpoint_id)
		print("Checkpoint ativado:", checkpoint_id, "em", global_position)
		CheckpointManager.set_checkpoint(world_name, global_position, checkpoint_id)
