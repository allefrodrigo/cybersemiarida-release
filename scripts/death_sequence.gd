class_name DeathSequence
extends ColorRect
## Sequência de morte (spec 007, H2): mora no HUD (camada 1, primeiro filho: o preto fica por baixo do HUD, então
## mortes, tempo, ⏸ e 🏠 continuam visíveis). Pausa a árvore de T0 até o controle voltar: o Timby, o cenário, a câmera
## e o cronômetro param; a entrada não fica guardada (Player limpa o buffer ao despausar).

signal finished

const GROUP: StringName = &"death_sequence"
const FALLING_PLATFORMS_GROUP: StringName = &"falling_platforms"
# tempos em quadros de física (60 Hz), contados de T0 (§5 da spec)
const READ_FRAMES: int = 18          # 0,00–0,30 s: tontura, câmera parada
const FADE_OUT_FRAMES: int = 12      # 0,30–0,50 s: escurece
const BLACK_FRAMES: int = 6          # 0,50–0,60 s: troca (teleporte + câmera sem viagem)
const FADE_IN_FRAMES: int = 12       # 0,60–0,80 s: clareia; o controle volta no fim

@onready var sfx: AudioStreamPlayer = $Sfx

var _player: Player = null
var _frame: int = -1                 # -1 = parada
var _locked_hud: bool = false

func _ready() -> void:
	add_to_group(GROUP)
	color = Color(0, 0, 0, 0)
	visible = false                  # parado, não existe na tela (nem para o teste do balão, 003h A16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_running() -> bool:
	return _frame >= 0

## T0. Devolve false se a sequência já está em andamento (a morte conta uma vez só, H2.4).
func start(player: Player) -> bool:
	if is_running() or player == null:
		return false
	_player = player
	_frame = 0
	GameState.death_count += 1
	visible = true
	get_tree().paused = true
	MusicPlayer.set_play_while_paused(true)   # D1: a música não para na morte
	player.enter_death()
	var hud := get_tree().get_first_node_in_group(&"game_hud") as GameHud
	if hud != null and not hud.pause_button.disabled:
		hud.set_buttons_locked(true)
		_locked_hud = true
	if sfx.stream != null:
		sfx.play()
	return true

func _physics_process(_delta: float) -> void:
	if _frame < 0:
		return
	_frame += 1
	var f: int = _frame
	var t_black: int = READ_FRAMES + FADE_OUT_FRAMES
	var t_clear: int = t_black + BLACK_FRAMES
	var t_end: int = t_clear + FADE_IN_FRAMES
	if f <= READ_FRAMES:
		color.a = 0.0
	elif f <= t_black:
		color.a = float(f - READ_FRAMES) / float(FADE_OUT_FRAMES)
	elif f <= t_clear:
		color.a = 1.0
		if f == t_black + 1:
			_respawn()
	elif f < t_end:
		color.a = 1.0 - float(f - t_clear) / float(FADE_IN_FRAMES)
	else:
		color.a = 0.0
		_finish()

func _respawn() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var path: String = _player.level_path()
	if CheckpointManager.has_respawn(path):
		_player.respawn_at(CheckpointManager.get_respawn_position(), CheckpointManager.get_respawn_facing_right())
	else:
		_player.respawn_at(_player.initial_position, true)
	get_tree().call_group(FALLING_PLATFORMS_GROUP, &"reset_platform")

func _finish() -> void:
	_frame = -1
	if _locked_hud:
		var hud := get_tree().get_first_node_in_group(&"game_hud") as GameHud
		if hud != null:
			hud.set_buttons_locked(false)
		_locked_hud = false
	if _player != null and is_instance_valid(_player):
		_player.exit_death()
	MusicPlayer.set_play_while_paused(false)
	visible = false
	get_tree().paused = false
	finished.emit()
