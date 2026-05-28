extends Area2D

@export var cena_pirarucu: PackedScene
@export var cena_pirara: PackedScene
@export var cena_cardume: PackedScene
@export var debug_iniciar_direto: bool = false 
# @export var cena_jau: PackedScene  # JAU — futuro inimigo, descomentar quando implementado

# Referências da UI
@onready var red_flash: ColorRect = %RedFlash
@onready var wave_text: Label = %WaveText

# Referências dos pontos de Spawn — piraras
@onready var spawn_pirara_1: Marker2D = %SpawnPirara_W3_1
@onready var spawn_pirara_2: Marker2D = %SpawnPirara_W3_2
@onready var spawn_pirara_3: Marker2D = %SpawnPirara_W3_3

# Referências dos pontos de Spawn — pirarucus
@onready var spawn_pirarucu_1: Marker2D = %SpawnPirarucu_W3_1
@onready var spawn_pirarucu_2: Marker2D = %SpawnPirarucu_W3_2

# Referências dos pontos de Spawn — cardumes (2 por etapa = 6 no total)
@onready var spawn_cardume_e1_a: Marker2D = %SpawnCardume_W3_E1A
@onready var spawn_cardume_e1_b: Marker2D = %SpawnCardume_W3_E1B
@onready var spawn_cardume_e2_a: Marker2D = %SpawnCardume_W3_E2A
@onready var spawn_cardume_e2_b: Marker2D = %SpawnCardume_W3_E2B
@onready var spawn_cardume_e3_a: Marker2D = %SpawnCardume_W3_E3A
@onready var spawn_cardume_e3_b: Marker2D = %SpawnCardume_W3_E3B

# @onready var spawn_jau: Marker2D = %SpawnJau_W3  # JAU — descomentar quando implementado

var inimigos_vivos_na_etapa: int = 0
var etapa_atual: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if red_flash:
		red_flash.color.a = 0.0
		red_flash.visible = true
	if wave_text:
		wave_text.modulate.a = 0.0
		wave_text.visible = false
	
	if debug_iniciar_direto:  # <- aqui
		set_deferred("monitoring", false)
		iniciar_wave()
		

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		set_deferred("monitoring", false)
		iniciar_wave()

func iniciar_wave() -> void:
	var player = get_tree().get_first_node_in_group("player_principal")
	
	if player and "pode_andar" in player:
		player.pode_andar = false
	
	await animar_alerta("ALERTA: ONDA 3", 2)
	
	if player and "pode_andar" in player:
		player.pode_andar = true
	
	etapa_1()

func animar_alerta(texto: String, quantidade_piscadas: int) -> void:
	if not red_flash or not wave_text:
		push_error("[Wave3_Trigger] ERRO: RedFlash ou WaveText não encontrados!")
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

# ---------------------------------------------------------------------------
# ETAPA 1: 2 cardumes + 2 piraras + 1 pirarucu
# ---------------------------------------------------------------------------
func etapa_1() -> void:
	etapa_atual = 1
	inimigos_vivos_na_etapa = 5  # 2 cardumes + 2 piraras + 1 pirarucu
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	# --- 2 Cardumes ---
	_spawnar_cardume(spawn_cardume_e1_a)
	_spawnar_cardume(spawn_cardume_e1_b)
	
	# --- 2 Piraras ---
	for spawn in [spawn_pirara_1, spawn_pirara_2]:
		var pirara = cena_pirara.instantiate()
		pirara.global_position = spawn.global_position
		pirara.jogador = player
		pirara.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirara)
	
	# --- 1 Pirarucu ---
	var pirarucu = cena_pirarucu.instantiate()
	pirarucu.global_position = spawn_pirarucu_1.global_position
	pirarucu.is_active = true
	pirarucu.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(pirarucu)
	
	print("[Etapa1] Onda finalizada com sucesso!")

# ---------------------------------------------------------------------------
# ETAPA 2: 2 cardumes + 3 piraras + 2 pirarucus
# ---------------------------------------------------------------------------
func etapa_2() -> void:
	etapa_atual = 2
	inimigos_vivos_na_etapa = 7  # 2 cardumes + 3 piraras + 2 pirarucus
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	# --- 2 Cardumes ---
	_spawnar_cardume(spawn_cardume_e2_a)
	_spawnar_cardume(spawn_cardume_e2_b)
	
	# --- 3 Piraras ---
	for spawn in [spawn_pirara_1, spawn_pirara_2, spawn_pirara_3]:
		var pirara = cena_pirara.instantiate()
		pirara.global_position = spawn.global_position
		pirara.jogador = player
		pirara.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirara)
	
	# --- 2 Pirarucus ---
	for spawn in [spawn_pirarucu_1, spawn_pirarucu_2]:
		var pirarucu = cena_pirarucu.instantiate()
		pirarucu.global_position = spawn.global_position
		pirarucu.is_active = true
		pirarucu.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirarucu)

# ---------------------------------------------------------------------------
# ETAPA 3: 2 cardumes + 2 piraras + 1 pirarucu + JAU (futuro)
# ---------------------------------------------------------------------------
func etapa_3() -> void:
	etapa_atual = 3
	inimigos_vivos_na_etapa = 5  # 2 cardumes + 2 piraras + 1 pirarucu
	# Quando o Jau for implementado: inimigos_vivos_na_etapa = 6
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	# --- 2 Cardumes ---
	_spawnar_cardume(spawn_cardume_e3_a)
	_spawnar_cardume(spawn_cardume_e3_b)
	
	# --- 2 Piraras ---
	for spawn in [spawn_pirara_1, spawn_pirara_2]:
		var pirara = cena_pirara.instantiate()
		pirara.global_position = spawn.global_position
		pirara.jogador = player
		pirara.morreu.connect(_on_inimigo_morreu)
		get_parent().add_child(pirara)
	
	# --- 1 Pirarucu ---
	var pirarucu = cena_pirarucu.instantiate()
	pirarucu.global_position = spawn_pirarucu_1.global_position
	pirarucu.is_active = true
	pirarucu.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(pirarucu)
	
	# --- JAU (futuro) ---
	# var jau = cena_jau.instantiate()
	# jau.global_position = spawn_jau.global_position
	# jau.jogador = player
	# jau.morreu.connect(_on_inimigo_morreu)
	# get_parent().add_child(jau)

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
func _spawnar_cardume(spawn: Marker2D) -> void:
	var cardume = cena_cardume.instantiate()
	cardume.global_position = spawn.global_position
	cardume.auto_start = true
	cardume.morreu.connect(_on_inimigo_morreu)
	get_parent().add_child(cardume)

# ---------------------------------------------------------------------------
# CONTROLE DE MORTES
# ---------------------------------------------------------------------------
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
	print("[Wave3] Onda finalizada com sucesso!")
