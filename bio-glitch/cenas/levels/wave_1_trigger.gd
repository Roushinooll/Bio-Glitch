extends Area2D

@export var cena_pirarucu: PackedScene
@export var cena_pirara: PackedScene

@onready var red_flash: ColorRect = %RedFlash
@onready var wave_text: Label = %WaveText

@onready var spawn_pirarucu: Marker2D = %SpawnPirarucu
@onready var spawn_pirara_1: Marker2D = %SpawnPirara1
@onready var spawn_pirara_2: Marker2D = %SpawnPirara2

var inimigos_vivos_na_etapa: int = 0
var etapa_atual: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		set_deferred("monitoring", false) 
		iniciar_wave()

func iniciar_wave() -> void:
	var player = get_tree().get_first_node_in_group("player_principal")
	
	if player and "pode_andar" in player:
		player.pode_andar = false
	
	await animar_alerta("ALERTA: ONDA 1", 2)
	
	if player and "pode_andar" in player:
		player.pode_andar = true
	
	etapa_1()

func animar_alerta(texto: String, quantidade_piscadas: int) -> void:
	wave_text.text = texto
	red_flash.visible = true
	wave_text.visible = true
	
	red_flash.color.a = 0.0
	wave_text.modulate.a = 0.0
	
	var tween = create_tween()
	
	for i in range(quantidade_piscadas):
		# Aparece (Usamos "color:a" no red_flash para não depender do modulate)
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
	
	var pirarucu = cena_pirarucu.instantiate()
	pirarucu.global_position = spawn_pirarucu.global_position
	pirarucu.is_active = true # Já ativa ele baseado no seu código
	
	pirarucu.morreu.connect(_on_inimigo_morreu)
	
	get_parent().add_child(pirarucu)

func etapa_2() -> void:
	etapa_atual = 2
	inimigos_vivos_na_etapa = 2
	
	var spawns = [spawn_pirara_1, spawn_pirara_2]
	var player = get_tree().get_first_node_in_group("player_principal")
	
	for spawn in spawns:
		var pirara = cena_pirara.instantiate()
		pirara.global_position = spawn.global_position
		pirara.jogador = player # Força ele já saber quem é o player
		
		pirara.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirara)

func _on_inimigo_morreu(inimigo: Node2D) -> void:
	inimigos_vivos_na_etapa -= 1
	
	if inimigos_vivos_na_etapa <= 0:
		if etapa_atual == 1:
			await get_tree().create_timer(1.0).timeout
			etapa_2()
		elif etapa_atual == 2:
			finalizar_wave()

func finalizar_wave() -> void:
	await animar_alerta("ONDA CONCLUÍDA", 1)
