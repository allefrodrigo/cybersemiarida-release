extends CanvasLayer

signal transition_finished

func play_transition():
	# Tocar o som
	$AudioStreamPlayer.play()

	# Iniciar a animação
	$AnimationPlayer.play("zoom")

	# Aguardar a animação terminar
	await $AnimationPlayer.animation_finished

	# Emitir sinal de fim de transição
	emit_signal("transition_finished")

	# Remover o nó após a transição
	queue_free()
