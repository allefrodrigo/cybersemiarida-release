extends Node2D

var button_type = null

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_texture_button_pressed() -> void:
	$Fade.show()
	$Fade/Fade_timer.start()
	$Fade/Fade_transatision/AnimationPlayer.play("fade_in")    

func _on_fade_timer_timeout() -> void:
	# Pausa a música
	get_tree().change_scene_to_file("res://levels/release/caf_01.tscn")
