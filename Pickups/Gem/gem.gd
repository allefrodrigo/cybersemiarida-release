extends Area2D

var thickness_direction: float = 1.0
var thickness_speed: float = 0.2  # Velocidade da mudança
var min_thickness: float = 0.4
var max_thickness: float = 1

# Função chamada quando o nó entra na árvore de cena
func _ready() -> void:
	var animated_sprite = get_node("AnimatedSprite2D")
	if animated_sprite == null:
		print("AnimatedSprite2D não encontrado")
		return
	
	var sprite_material = animated_sprite.material
	if sprite_material == null:
		print("Material não encontrado")
		return
	
	sprite_material = sprite_material as ShaderMaterial
	if sprite_material != null:
		sprite_material.set_shader_parameter("thickness", min_thickness)
	else:
		print("Material não é um ShaderMaterial")

# Função chamada a cada frame
func _process(delta: float) -> void:
	var animated_sprite = get_node("AnimatedSprite2D")
	if animated_sprite == null:
		print("AnimatedSprite2D não encontrado")
		return
	
	var sprite_material = animated_sprite.material
	if sprite_material == null:
		print("Material não encontrado ou não é um ShaderMaterial")
		return
	
	sprite_material = sprite_material as ShaderMaterial
	if sprite_material == null:
		print("Material não é um ShaderMaterial")
		return
	
	# Obtenha o valor atual de 'thickness'
	var current_thickness = sprite_material.get_shader_parameter("thickness")
	
	# Altere o valor de thickness
	current_thickness += thickness_speed * thickness_direction * delta
	sprite_material.set_shader_parameter("thickness", current_thickness)
	
	# Verifique os limites para inverter a direção
	if current_thickness >= max_thickness:
		thickness_direction = -1.0
	elif current_thickness <= min_thickness:
		thickness_direction = 1.0
