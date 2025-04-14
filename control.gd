extends Control

@onready var black_screen: ColorRect = $BlackScreen
@onready var city_label: Label = $CityLabel

# Texto que será digitado
var city_text: String = "CAFUNDÓ, RN"

# Ajuste de velocidade de digitação e duração de fades
var typing_speed: float = 0.1
var fade_duration: float = 1.0

func _ready() -> void:
	# Começa completamente preto
	black_screen.modulate.a = 1.0
	# Inicia o efeito de digitação
	typewriter_text()

func typewriter_text() -> void:
	city_label.text = ""
	_type_letter(0)

func _type_letter(index: int) -> void:
	if index >= city_text.length():
		# Terminou de digitar. Espera 2s antes de iniciar o fade out
		var wait_timer = get_tree().create_timer(2.0)
		wait_timer.timeout.connect(fade_out)
		return

	# Adiciona a próxima letra
	city_label.text += city_text[index]

	# Timer para digitar a próxima letra
	var timer = get_tree().create_timer(typing_speed)
	timer.timeout.connect(
		func():
			_type_letter(index + 1)
	)

func fade_out() -> void:
	# Passa de alpha = 1 (preto) para alpha = 0 (transparente)
	var tween = get_tree().create_tween()
	tween.tween_property(black_screen, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(_on_fade_out_done)

func _on_fade_out_done() -> void:
	# Após o fade_out, você pode trocar de cena ou remover esta cena
	queue_free()
