extends Node

var player_data = {
	"health": 100,
	"checkpoint_position": null,
	"current_world": null,
	"last_checkpoint_id": null  # Armazena o ID do último checkpoint
}

func set_checkpoint(world_name: String, position: Vector2, checkpoint_id: int):
	if player_data["last_checkpoint_id"] == null or checkpoint_id > player_data["last_checkpoint_id"]:
		player_data["checkpoint_position"] = position
		player_data["current_world"] = world_name
		player_data["last_checkpoint_id"] = checkpoint_id
		print("Checkpoint atualizado:", checkpoint_id, "em", position)
	else:
		print("Checkpoint ignorado. ID menor ou já visitado:", checkpoint_id)

func get_checkpoint() -> Dictionary:
	return {
		"position": player_data["checkpoint_position"],
		"world": player_data["current_world"],
		"last_checkpoint_id": player_data["last_checkpoint_id"]
	}
