extends Area2D

@export var padding: float = 32.0    # sobra além da largura do TileMap
@export var depth: float = 16.0      # altura da zona de queda em px

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tm = _find_tilemap()
	if tm != null:
		_auto_size_to_tilemap(tm)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.respawn_to_initial()
		FallManager.increment_fall(get_tree().current_scene.name)

func _find_tilemap() -> TileMap:
	var cur = get_parent()
	while cur != null:
		if cur is TileMap:
			return cur
		cur = cur.get_parent()
	return null

func _auto_size_to_tilemap(tm: TileMap) -> void:
	var used = tm.get_used_rect()           # Rect2 em coords de célula
	var cell = tm.cell_size                 # tamanho de cada célula
	var world_pos = tm.map_to_world(used.position)
	var world_size = used.size * cell

	var half_w = world_size.x * 0.5 + padding
	var half_h = depth * 0.5
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(half_w, half_h)
	$CollisionShape2D.shape = shape

	position.x = world_pos.x + world_size.x * 0.5
	position.y = world_pos.y + world_size.y + half_h
