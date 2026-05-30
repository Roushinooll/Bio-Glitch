extends Control

@onready var seta: TextureRect = $GrupoOpcoes/Seta
@onready var botao_tentar: Button = $GrupoOpcoes/BotaoTentarNovamente
@onready var botao_menu: Button = $GrupoOpcoes/BotaoMenu

var opcao_selecionada: int = 0

const SETA_X := 0.0
const SETA_Y_TENTAR := -8.0
const SETA_Y_MENU := 69.0

func _ready() -> void:
	botao_tentar.grab_focus()
	atualizar_seta()

	botao_tentar.mouse_entered.connect(func():
		opcao_selecionada = 0
		botao_tentar.grab_focus()
		atualizar_seta()
	)

	botao_menu.mouse_entered.connect(func():
		opcao_selecionada = 1
		botao_menu.grab_focus()
		atualizar_seta()
	)

	botao_tentar.pressed.connect(tentar_novamente)
	botao_menu.pressed.connect(voltar_ao_menu)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		opcao_selecionada = 1
		botao_menu.grab_focus()
		atualizar_seta()

	if event.is_action_pressed("ui_up"):
		opcao_selecionada = 0
		botao_tentar.grab_focus()
		atualizar_seta()

	if event.is_action_pressed("ui_accept"):
		if opcao_selecionada == 0:
			tentar_novamente()
		else:
			voltar_ao_menu()


func atualizar_seta() -> void:
	if opcao_selecionada == 0:
		seta.position = Vector2(SETA_X, SETA_Y_TENTAR)
	else:
		seta.position = Vector2(SETA_X, SETA_Y_MENU)


func tentar_novamente() -> void:
	get_tree().change_scene_to_file("res://cenas/levels/Level_01_Distopico.tscn")


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu/Menu_inicial.tscn")
