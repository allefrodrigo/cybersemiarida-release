# res://scenes/CreditsScreen.gd
extends Control

@export var scroll_speed: float = 50.0
@export var credits: Array[Dictionary] = [
  { "name": "Allef", "contribution": "Desenvolvedor Chefe" },
  { "name": "Jorge", "contribution": "Desenvolvedora Frontend" },
  { "name": "Felipe Souza", "contribution": "Desenvolvedor Backend" },
  { "name": "Lucas Oliveira", "contribution": "Engenheiro de Ferramentas" },
  { "name": "Tiago Costa", "contribution": "Game Designer" },
  { "name": "Beatriz Martins", "contribution": "Designer de Níveis" },
  { "name": "Larissa Rocha", "contribution": "UI/UX Designer" },
  { "name": "Rafael Lima", "contribution": "Designer de Personagens" },
  { "name": "Camila Silva", "contribution": "Artista de Conceito" },
  { "name": "Bruno Nunes", "contribution": "Artista de Texturas" },
  { "name": "Juliana Fernandes", "contribution": "Artista de Modelagem 3D" },
  { "name": "Gustavo Pereira", "contribution": "Artista de Animação" },
  { "name": "Victoria Almeida", "contribution": "Ilustradora de Cenários" },
  { "name": "Gabriel Santos", "contribution": "Engenheiro de Áudio" },
  { "name": "Paula Rodrigues", "contribution": "Designer de Efeitos Sonoros" },
  { "name": "Larissa Tavares", "contribution": "Mixagem e Masterização" },
  { "name": "Ana Beatriz", "contribution": "Voz da Protagonista" },
  { "name": "Rodrigo Machado", "contribution": "Voz do Antagonista" },
  { "name": "Camila Freitas", "contribution": "Voz da NPC 'Elara'" },
  { "name": "Fernando Costa", "contribution": "Voz do NPC 'Grok'" },
  { "name": "Diego Pereira", "contribution": "QA Lead" },
  { "name": "Marília Santos", "contribution": "Teste de Regressão" },
  { "name": "Pedro Alves", "contribution": "Teste de Compatibilidade" },
  { "name": "Julio Castro", "contribution": "Teste de Performance" },
  { "name": "Equipe Alpha", "contribution": "Testers" },
  { "name": "Cláudia Lima", "contribution": "Tradutora PT-BR" },
  { "name": "Hannah Müller", "contribution": "Tradutora EN-US" },
  { "name": "Jean Dupont", "contribution": "Tradutor FR-FR" },
  { "name": "Rafael Andrade", "contribution": "Produtor Executivo" },
  { "name": "Patrícia Gomes", "contribution": "Produtora de Projeto" },
  { "name": "Bruno Carvalho", "contribution": "Gerente de Marketing" },
  { "name": "Fernanda Nascimento", "contribution": "Community Manager" },
  { "name": "Família e Amigos", "contribution": "Apoio e Incentivo" },
  { "name": "Playtesters", "contribution": "Feedback Valioso" },
  { "name": "OST 1 – A Jornada Começa", "contribution": "Compositor: Victor Campos" },
  { "name": "OST 2 – Dança das Espadas", "contribution": "Compositor: Helena Arantes" },
  { "name": "OST 3 – Ecos das Ruínas", "contribution": "Compositor: Lucas Fernandes" },
  { "name": "Esboço Concept Art: Kael, o Herói Sombrio", "contribution": "Artista de Conceito: Camila Silva" },
  { "name": "Esboço Concept Art: Aria, a Feiticeira do Gelo", "contribution": "Artista de Conceito: Larissa Rocha" },
  { "name": "Desenho de Cenário: Floresta Encantada", "contribution": "Ilustrador de Cenário: Victoria Almeida" },
  { "name": "Design de UI: HUD de Batalha", "contribution": "UI/UX Designer: Larissa Rocha" },
  { "name": "Cinemática de Introdução", "contribution": "Diretor de Cinemática: Marcelo Reis" },
  { "name": "Storyboard das Cenas", "contribution": "Storyboard Artist: Juliana Fernandes" },
  { "name": "Arte Final: Menu Principal", "contribution": "Artista de Interface: Larissa Rocha" },
  { "name": "Consultoria Técnica: Física de Partículas", "contribution": "Dr. Ana Paula Duarte" }
	# ... repita ou remova entradas conforme desejar para testar
]

@onready var scroll     : ScrollContainer  = $ScrollContainer
@onready var rich_text  : RichTextLabel    = scroll.get_node("RichTextLabel")

func _ready() -> void:
	# 1) Monta o BBCode
	rich_text.bbcode_enabled = true
	rich_text.bbcode_text    = _build_bbcode()
	# 2) Defer pra ajustar tamanho após o RichTextLabel processar o texto
	call_deferred("_start_scroll")


func _build_bbcode() -> String:
	var txt := ""
	for entry in credits:
		txt += "[center][b]%s[/b]\n%s\n\n" % [entry["name"], entry["contribution"]]
	return txt


func _start_scroll() -> void:
	# 3) Ajusta a altura do RichTextLabel ao conteúdo
	var content_h = rich_text.get_content_height()
	rich_text.custom_minimum_size.y = content_h

	# 4) Bloqueia todo input e esconde ambas as barras de rolagem
	scroll.mouse_filter = MOUSE_FILTER_IGNORE        # bloqueia cliques e toques :contentReference[oaicite:0]{index=0}
	var vbar = scroll.get_v_scroll_bar()             
	var hbar = scroll.get_h_scroll_bar()
	if vbar: vbar.visible = false                    
	if hbar: hbar.visible = false                    

	# 5) Posiciona o “ponto de vista” abaixo da tela
	var view_h = get_viewport_rect().size.y
	scroll.scroll_vertical = -view_h                 # usa a propriedade correta :contentReference[oaicite:1]{index=1}

	# 6) Calcula distância total e duração do tween
	var max_scroll = max(content_h - view_h, 0)
	var distance   = max_scroll + view_h
	var duration   = distance / scroll_speed

	# 7) Tween anima scroll_vertical de uma só vez
	create_tween()\
		.tween_property(scroll, "scroll_vertical", max_scroll, duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)\
		.connect("finished", Callable(self, "_on_scroll_complete"))


func _on_scroll_complete() -> void:
	# espera 5 segundos
	await get_tree().create_timer(5.0).timeout
	# só então troca de cena
	get_tree().change_scene_to_file("res://scenes/main_title.tscn")
