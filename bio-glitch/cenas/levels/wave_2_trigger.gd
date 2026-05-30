extends Area2D

@export var cena_pirara: PackedScene
@export var cena_cardume: PackedScene
@export var cena_cardume2: PackedScene
@export var cena_pirarucu: PackedScene

@onready var red_flash: ColorRect = %RedFlash
@onready var wave_text: Label = %WaveText

@onready var spawn_pirara_1: Marker2D = %SpawnPirara_Wave2
@onready var spawn_pirara_2: Marker2D = %SpawnPirara2_Wave2
@onready var spawn_cardume: Marker2D = %SpawnCardume
@onready var spawn_cardume2: Marker2D = %SpawnCardume2
@onready var spawn_pirarucu: Marker2D = %SpawnPirarucu_Wave2

var inimigos_vivos_na_etapa: int = 0
var etapa_atual: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if red_flash:
		red_flash.color.a = 0.0
		red_flash.visible = true  # Mantém visível mas transparente para o Tween funcionar
	if wave_text:
		wave_text.modulate.a = 0.0
		wave_text.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		set_deferred("monitoring", false) 
		iniciar_wave()

func iniciar_wave() -> void:
	var player = get_tree().get_first_node_in_group("player_principal")
	
	if player and "pode_andar" in player:
		player.pode_andar = false
	
	await animar_alerta("ALERTA: ONDA 2", 2)
	
	if player and "pode_andar" in player:
		player.pode_andar = true
	
	etapa_1()

func animar_alerta(texto: String, quantidade_piscadas: int) -> void:
	if not red_flash or not wave_text:
		push_error("[Wave2_Trigger] ERRO: RedFlash ou WaveText não encontrados! Verifique os unique_name nos nós da UI.")
		return
	
	wave_text.text = texto
	red_flash.visible = true
	wave_text.visible = true
	
	red_flash.color.a = 0.0
	wave_text.modulate.a = 0.0
	
	var tween = create_tween()
	
	for i in range(quantidade_piscadas):
		tween.tween_property(red_flash, "color:a", 0.4, 0.3) 
		tween.parallel().tween_property(wave_text, "modulate:a", 1.0, 0.3)
		
		tween.tween_property(red_flash, "color:a", 0.0, 0.3)
		tween.parallel().tween_property(wave_text, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	red_flash.visible = false
	wave_text.visible = false

func etapa_1() -> void:
	etapa_atual = 1
	inimigos_vivos_na_etapa = 1
	
	var cardume = cena_cardume.instantiate()
	cardume.global_position = spawn_cardume.global_position
	cardume.auto_start = true
	
	cardume.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(cardume)

func etapa_2() -> void:
	etapa_atual = 2
	inimigos_vivos_na_etapa = 3  # 2 piraras + 1 cardume
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	var spawns_pirara = [spawn_pirara_1, spawn_pirara_2]
	for spawn in spawns_pirara:
		var pirara = cena_pirara.instantiate()
		pirara.global_position = spawn.global_position
		pirara.jogador = player
		
		pirara.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirara)

func etapa_3() -> void:
	etapa_atual = 3
	inimigos_vivos_na_etapa = 3  # 1 cardume + 1 pirara + 1 pirarucu
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	var cardume = cena_cardume.instantiate()
	cardume.global_position = spawn_cardume2.global_position
	cardume.auto_start = true
	
	cardume.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(cardume)
	
	var pirara = cena_pirara.instantiate()
	pirara.global_position = spawn_pirara_1.global_position
	pirara.jogador = player
	
	pirara.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(pirara)
	
	var pirarucu = cena_pirarucu.instantiate()
	pirarucu.global_position = spawn_pirarucu.global_position
	pirarucu.is_active = true
	
	pirarucu.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(pirarucu)

func _on_inimigo_morreu(_inimigo: Node2D) -> void:
	inimigos_vivos_na_etapa -= 1
	
	if inimigos_vivos_na_etapa <= 0:
		if etapa_atual == 1:
			await get_tree().create_timer(1.0).timeout
			etapa_2()
		elif etapa_atual == 2:
			await get_tree().create_timer(1.0).timeout
			etapa_3()
		elif etapa_atual == 3:
			finalizar_wave()

func finalizar_wave() -> void:
	await animar_alerta("ONDA CONCLUÍDA", 1)
