extends Area2D

signal fallzone_triggered  # Sinal para notificar o mundo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Certifica-se de que é o jogador
		print("Player caiu na fallzone:", name)
		emit_signal("fallzone_triggered", self.name)  # Emite um sinal com o nome da fallzone
