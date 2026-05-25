extends Area2D

@export var cena_pirarucu: PackedScene
@export var cena_pirara: PackedScene

# Referências da UI (ajuste os caminhos se sua árvore for diferente)
@onready var red_flash: ColorRect = %RedFlash
@onready var wave_text: Label = %WaveText

# Referências dos pontos de Spawn
@onready var spawn_pirarucu: Marker2D = %SpawnPirarucu
@onready var spawn_pirara_1: Marker2D = %SpawnPirara1
@onready var spawn_pirara_2: Marker2D = %SpawnPirara2

var inimigos_vivos_na_etapa: int = 0
var etapa_atual: int = 0

func _ready() -> void:
	# Conecta a área para quando o player entrar
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		set_deferred("monitoring", false) 
		iniciar_wave()

func iniciar_wave() -> void:
	# 1. Busca o player usando o grupo "player_principal" que você já usa no jogo
	var player = get_tree().get_first_node_in_group("player_principal")
	
	# Bloqueia o jogador (se ele existir e tiver a variável de controle)
	if player and "pode_andar" in player:
		player.pode_andar = false
	
	# 2. Piscar tela e texto duas vezes (o 'await' faz o código parar aqui até a animação terminar)
	await animar_alerta("ALERTA: ONDA 1", 2)
	
	# Libera o jogador para andar novamente assim que o alerta acabar
	if player and "pode_andar" in player:
		player.pode_andar = true
	
	# 3. Começar a primeira etapa
	etapa_1()

func animar_alerta(texto: String, quantidade_piscadas: int) -> void:
	wave_text.text = texto
	red_flash.visible = true
	wave_text.visible = true
	
	# Garante que tudo comece invisível (Alpha = 0) antes do Tween agir
	red_flash.color.a = 0.0
	wave_text.modulate.a = 0.0
	
	var tween = create_tween()
	
	for i in range(quantidade_piscadas):
		# Aparece (Usamos "color:a" no red_flash para não depender do modulate)
		tween.tween_property(red_flash, "color:a", 0.4, 0.3) 
		tween.parallel().tween_property(wave_text, "modulate:a", 1.0, 0.3)
		
		# Some
		tween.tween_property(red_flash, "color:a", 0.0, 0.3)
		tween.parallel().tween_property(wave_text, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	# Esconde tudo no final
	red_flash.visible = false
	wave_text.visible = false

# --- ETAPA 1: O PIRARUCU ---
func etapa_1() -> void:
	etapa_atual = 1
	inimigos_vivos_na_etapa = 1
	
	var pirarucu = cena_pirarucu.instantiate()
	pirarucu.global_position = spawn_pirarucu.global_position
	pirarucu.is_active = true # Já ativa ele baseado no seu código
	
	# Conecta o sinal de morte que criamos
	pirarucu.morreu.connect(_on_inimigo_morreu)
	
	# Adiciona ao mundo (ajuste get_parent() para onde você quer colocar os inimigos)
	get_parent().add_child(pirarucu)

# --- ETAPA 2: OS DOIS PIRARAS ---
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

# --- CONTROLE DE MORTES ---
func _on_inimigo_morreu(inimigo: Node2D) -> void:
	inimigos_vivos_na_etapa -= 1
	
	if inimigos_vivos_na_etapa <= 0:
		if etapa_atual == 1:
			# Aguarda 1 segundinho antes de jogar os Piraras
			await get_tree().create_timer(1.0).timeout
			etapa_2()
		elif etapa_atual == 2:
			finalizar_wave()

func finalizar_wave() -> void:
	await animar_alerta("ONDA CONCLUÍDA", 1)
	# Aqui você destrava as barreiras da arena, dá algum item pro player, etc.
