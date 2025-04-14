extends Node2D

# Referências automáticas para os nós
@onready var player: CharacterBody2D = $Player
@onready var tilemap_fundo: TileMapLayer = $TilemapFundo
@onready var tilemap_wall: TileMapLayer = $TileMapWall

# Variáveis para o movimento
var fall_speed = 0.01
var rotation_speed = 1
var walls_speed = 0.1

func _ready():
	# Verifica se os nós foram atribuídos corretamente
	assert(player, "Player node não encontrado!")
	assert(tilemap_fundo, "TilemapFundo node não encontrado!")
	assert(tilemap_wall, "TileMapWall node não encontrado!")

func _process(delta):
	# Movimento do personagem
	player.position.y += fall_speed * delta
	player.rotation += rotation_speed * delta

	# Movimento do fundo e das paredes
	move_background(delta)

func move_background(delta):
	# Move os TileMaps para simular o movimento
	tilemap_fundo.position.y += walls_speed * delta
	tilemap_wall.position.y += walls_speed * delta

	# Reinicia as posições se saírem da tela
	if tilemap_fundo.position.y > get_viewport_rect().size.y:
		reset_background()

func reset_background():
	tilemap_fundo.position.y = 0
	tilemap_wall.position.y = 0
