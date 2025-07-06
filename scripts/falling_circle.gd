extends RigidBody2D

@export var fall_speed: float = 200.0
@export var circle_radius: float = 10.0

var screen_width: float
var ground_y: float
var reset_cooldown: float = 0.0

@onready var circle_sound_player: AudioStreamPlayer2D

signal circle_destroyed
signal player_hit

func _ready() -> void:
	var viewport = get_viewport()
	screen_width = viewport.get_visible_rect().size.x
	ground_y = viewport.get_visible_rect().size.y + 50
	print("Screen width: ", screen_width, " Ground Y: ", ground_y)
	
	# Configura o corpo físico
	set_gravity_scale(0)
	set_lock_rotation_enabled(true)
	
	# Conecta sinais de colisão com a Area2D
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.area_entered.connect(_on_area_entered)
	
	# Cria a textura visual do círculo
	create_circle_visual()
	
	# Configura o AudioStreamPlayer individual
	setup_audio()

func create_circle_visual() -> void:
	var sprite = $VisualCircle
	var image = Image.create(int(circle_radius * 2), int(circle_radius * 2), false, Image.FORMAT_RGBA8)
	
	# Preenche a imagem com um círculo amarelo
	for x in range(int(circle_radius * 2)):
		for y in range(int(circle_radius * 2)):
			var distance = Vector2(x - circle_radius, y - circle_radius).length()
			if distance <= circle_radius:
				image.set_pixel(x, y, Color.YELLOW)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _physics_process(delta: float) -> void:
	# Move o círculo para baixo
	linear_velocity = Vector2(0, fall_speed)
	
	# Atualiza o cooldown
	if reset_cooldown > 0.0:
		reset_cooldown -= delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Jogador foi atingido - emite sinal para resetar a fase
		print("Jogador atingido por círculo!")
		player_hit.emit()
		# Reseta a posição do círculo também
		reset_position()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("circle_reset") and reset_cooldown <= 0.0:
		# Círculo atingiu a área de reset - reseta posição
		print("Círculo atingiu área de reset!")
		reset_position()

func reset_position() -> void:
	print("Resetando círculo - posição atual: ", global_position)
	# Reseta a posição do círculo para o topo da tela
	set_random_position_top()
	# Reseta a velocidade para garantir que volte a cair
	linear_velocity = Vector2(0, fall_speed)
	# Reseta qualquer força angular
	angular_velocity = 0.0
	# Define cooldown para evitar reset imediato
	reset_cooldown = 0.5
	print("Círculo resetado - nova posição: ", global_position, " velocidade: ", linear_velocity)

func destroy_circle() -> void:
	circle_destroyed.emit()
	queue_free()

func setup_audio() -> void:
	# Cria o AudioStreamPlayer individual para este círculo
	circle_sound_player = AudioStreamPlayer2D.new()
	add_child(circle_sound_player)
	
	# Carrega o som bass_note
	var bass_sound = load("res://audio/bass_note.ogg")
	if bass_sound:
		circle_sound_player.stream = bass_sound
		circle_sound_player.volume_db = -5  # Volume moderado
		print("Som bass_note carregado no círculo")
		
		# Toca o som quando o círculo é criado
		play_sound()
	else:
		print("Erro ao carregar bass_note.ogg")

func play_sound() -> void:
	if circle_sound_player and circle_sound_player.stream:
		# Para qualquer som que esteja tocando e reinicia
		circle_sound_player.stop()
		circle_sound_player.play()
		print("Tocando bass_note no círculo")

func set_random_position_top() -> void:
	var random_x = randf() * (screen_width - circle_radius * 2) + circle_radius
	var new_position = Vector2(random_x, -circle_radius * 2)
	global_position = new_position
	print("Círculo resetado para posição: ", new_position)
	
	# Toca o som quando reseta posição
	play_sound()