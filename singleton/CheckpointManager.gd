extends Node
## Checkpoints da fase atual (spec 007). Guarda só o poste ativo mais adiante da fase em que o Timby está; trocar de
## fase (Player novo numa cena de outra fase) ou começar um jogo novo (GameState.reset_run) zera.

signal respawn_changed(position: Vector2)

var _level_path: String = ""        # fase dona do checkpoint (scene_file_path da raiz da fase)
var _order: int = 0                 # 0 = nenhum poste ativo
var _position: Vector2 = Vector2.ZERO
var _facing_right: bool = true

## Chamado pelo Player no _ready. Outra fase: zera (o checkpoint de uma fase nunca vale noutra, H1.7).
func enter_level(level_path: String) -> void:
	if level_path != _level_path:
		reset()
		_level_path = level_path

func reset() -> void:
	_level_path = ""
	_order = 0
	_position = Vector2.ZERO
	_facing_right = true

## Poste cruzado. Só avança: um poste anterior não muda o ponto de renascer (§5, Ordem). Devolve true se mudou.
func activate(level_path: String, order: int, respawn_position: Vector2, facing_right: bool) -> bool:
	if level_path != _level_path:
		reset()
		_level_path = level_path
	if order <= _order:
		return false
	_order = order
	_position = respawn_position
	_facing_right = facing_right
	respawn_changed.emit(respawn_position)
	return true

func has_respawn(level_path: String) -> bool:
	return _order > 0 and level_path == _level_path

func get_respawn_position() -> Vector2:
	return _position

func get_respawn_facing_right() -> bool:
	return _facing_right

func get_active_order() -> int:
	return _order

# --- compatibilidade com os mundos legados (scripts/flag.gd, scenes/World/world.gd), fora da rota ---
func set_checkpoint(_world_name: String, position: Vector2, checkpoint_id: int) -> void:
	var scene := get_tree().current_scene
	activate(scene.scene_file_path if scene else "", checkpoint_id, position, true)

func get_checkpoint() -> Dictionary:
	return {"position": _position if _order > 0 else null, "world": _level_path, "last_checkpoint_id": _order}
