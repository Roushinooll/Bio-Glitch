extends CharacterBody2D

signal morreu(inimigo_node)

enum Estado {
	PARADO,
	INDO_PARA_ATAQUE,
	ATACANDO,
	RECUANDO,
	SENDO_PUXADO,
	CAINDO
}

@export var nome_do_inimigo: String = "Pirarara"

@export var velocidade: float = 110.0
@export var velocidade_de_recuo: float = 130.0
@export var dano: int = 1

@export var distancia_de_ataque: float = 20.0 
@export var tolerancia_ponto_ataque: float = 5.0 

@export var distancia_de_recuo: float = 120.0
@export var tempo_duracao_ataque: float = 0.18

@export var sprite_olha_para_esquerda: bool = true
@export var deslocamento_x_da_boca: float = -28.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var bite_hitbox: Area2D = $BiteHitBox
@onready var bite_hitbox_collision: CollisionShape2D = $BiteHitBox/CollisionShape2D
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound

@export var vida_maxima: int = 5
var vida_atual: int
var is_dead: bool = false

var jogador: Node2D = null
var estado_atual: Estado = Estado.PARADO

var direcao_do_olhar: int = -1
var cronometro_de_ataque: float = 0.0
var ja_acertou_jogador: bool = false

var ponto_de_ataque: Vector2 = Vector2.ZERO
var ponto_de_recuo: Vector2 = Vector2.ZERO

# --- NOVA VARIÁVEL ---
var meu_y_inicial: float = 0.0


func _ready() -> void:
	vida_atual = vida_maxima
	# Salva a altura em que este peixe específico nasceu/está
	meu_y_inicial = global_position.y

	bite_hitbox.monitoring = false
	bite_hitbox_collision.disabled = true

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	bite_hitbox.body_entered.connect(_on_bite_hitbox_body_entered)

	atualizar_direcao(-1)


func _physics_process(delta: float) -> void:
	match estado_atual:
		Estado.PARADO:
			processar_parado()
		Estado.INDO_PARA_ATAQUE:
			processar_ida_para_ataque()
		Estado.ATACANDO:
			processar_ataque(delta)
		Estado.RECUANDO:
			processar_recuo()
		Estado.SENDO_PUXADO:
			move_and_slide()
		Estado.CAINDO:
			processar_queda()


func processar_parado() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if jogador != null:
		preparar_ciclo_de_ataque()


func preparar_ciclo_de_ataque() -> void:
	if jogador == null:
		estado_atual = Estado.PARADO
		return

	if global_position.x > jogador.global_position.x:
		direcao_do_olhar = -1
	else:
		direcao_do_olhar = 1

	atualizar_direcao(direcao_do_olhar)

	# --- CORREÇÃO DE POSICIONAMENTO ---
	# Criamos o ponto usando o X do jogador com o deslocamento da distância de ataque
	# E travamos o Y no Y inicial do próprio peixe.
	var x_alvo_ataque = jogador.global_position.x - (direcao_do_olhar * distancia_de_ataque)
	ponto_de_ataque = Vector2(x_alvo_ataque, meu_y_inicial)
	
	# Fazemos o mesmo para o ponto de recuo
	var x_alvo_recuo = jogador.global_position.x - (direcao_do_olhar * distancia_de_recuo)
	ponto_de_recuo = Vector2(x_alvo_recuo, meu_y_inicial)
	# ----------------------------------

	estado_atual = Estado.INDO_PARA_ATAQUE


func processar_ida_para_ataque() -> void:
	if jogador == null:
		estado_atual = Estado.PARADO
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Mantém os pontos atualizados acompanhando o X do player, mas travados no Y do peixe
	ponto_de_ataque.x = jogador.global_position.x - (direcao_do_olhar * distancia_de_ataque)
	ponto_de_recuo.x = jogador.global_position.x - (direcao_do_olhar * distancia_de_recuo)

	var distancia_ate_ataque := global_position.distance_to(ponto_de_ataque)

	if distancia_ate_ataque <= tolerancia_ponto_ataque:
		velocity = Vector2.ZERO
		iniciar_ataque()
		return

	var direcao := global_position.direction_to(ponto_de_ataque)
	velocity = direcao * velocidade

	move_and_slide()

	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var corpo_colidido = colisao.get_collider()
		
		if corpo_colidido != null and corpo_colidido.is_in_group("player"):
			velocity = Vector2.ZERO
			iniciar_ataque()
			return


func iniciar_ataque() -> void:
	estado_atual = Estado.ATACANDO
	velocity = Vector2.ZERO
	cronometro_de_ataque = tempo_duracao_ataque
	ja_acertou_jogador = false

	bite_hitbox.monitoring = true
	bite_hitbox_collision.set_deferred("disabled", false)

	call_deferred("verificar_sobreposicao_da_mordida")


func processar_ataque(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	cronometro_de_ataque -= delta

	if cronometro_de_ataque <= 0:
		encerrar_ataque()


func encerrar_ataque() -> void:
	bite_hitbox.monitoring = false
	bite_hitbox_collision.set_deferred("disabled", true)

	if jogador != null:
		ponto_de_recuo.x = jogador.global_position.x - (direcao_do_olhar * distancia_de_recuo)

	estado_atual = Estado.RECUANDO
	velocity = Vector2.ZERO


func processar_recuo() -> void:
	if jogador == null:
		estado_atual = Estado.PARADO
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distancia_ate_recuo := global_position.distance_to(ponto_de_recuo)

	# Se ele chegou muito perto do ponto de recuo, encerra o recuo
	# Aumentei um pouquinho a tolerância para 8.0 para evitar travamentos físicos
	if distancia_ate_recuo <= 8.0:
		velocity = Vector2.ZERO

		if global_position.x > jogador.global_position.x:
			atualizar_direcao(-1)
		else:
			atualizar_direcao(1)

		preparar_ciclo_de_ataque()
		return

	var direcao := global_position.direction_to(ponto_de_recuo)

	if direcao.x < 0:
		atualizar_direcao(-1)
	elif direcao.x > 0:
		atualizar_direcao(1)

	velocity = direcao * velocidade_de_recuo

	move_and_slide()


func atualizar_direcao(direcao: int) -> void:
	direcao_do_olhar = direcao

	if sprite_olha_para_esquerda:
		sprite.flip_h = direcao > 0
	else:
		sprite.flip_h = direcao < 0

	bite_hitbox.position.x = abs(deslocamento_x_da_boca) * direcao


func verificar_sobreposicao_da_mordida() -> void:
	if ja_acertou_jogador:
		return

	var corpos := bite_hitbox.get_overlapping_bodies()

	for corpo in corpos:
		if corpo.is_in_group("player"):
			acertar_jogador(corpo)
			return


func acertar_jogador(corpo: Node) -> void:
	if ja_acertou_jogador:
		return

	if not corpo.has_method("take_damage"):
		return

	corpo.take_damage(dano)
	ja_acertou_jogador = true


func _on_bite_hitbox_body_entered(corpo: Node2D) -> void:
	if corpo.is_in_group("player"):
		acertar_jogador(corpo)

func _on_detection_area_body_entered(corpo: Node2D) -> void:
	if corpo.is_in_group("player"):
		jogador = corpo

		if estado_atual == Estado.PARADO:
			preparar_ciclo_de_ataque()


func _on_detection_area_body_exited(corpo: Node2D) -> void:
	if corpo == jogador:
		if estado_atual == Estado.PARADO:
			jogador = null

func take_damage(amount: int) -> void:
	if is_dead:
		return

	vida_atual -= amount
	print("[Inimigo] Recebeu dano: ", amount, " | Vida restante: ", vida_atual)

	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	is_dead = true
	estado_atual = Estado.CAINDO # Muda para o estado de queda livre
	
	# Desativa TODAS as camadas de colisão do peixe para ele não agarrar em nada enquanto cai
	collision_layer = 0
	collision_mask = 0
	
	# Desativa as áreas de ataque e detecção
	bite_hitbox.monitoring = false
	detection_area.monitoring = false
	
	print("[Inimigo] Morreu e começou a afundar!")
	emit_signal("morreu", self)
	explosion_sound.volume_db = -15.0
	explosion_sound.play()
	
	# Aguarda 2.5 segundos (tempo dele sair da tela) e deleta o inimigo do jogo
	get_tree().create_timer(2.5).timeout.connect(queue_free)

func can_be_hooked() -> bool:
	# O inimigo só pode ser fisgado se estiver vivo
	return not is_dead

func on_being_pulled(esta_sendo_puxado: bool) -> void:
	if esta_sendo_puxado:
		estado_atual = Estado.SENDO_PUXADO
	else:
		# Se ele foi puxado e já está morto, entra em queda livre
		if is_dead:
			estado_atual = Estado.CAINDO
		else:
			estado_atual = Estado.PARADO
			preparar_ciclo_de_ataque()

func processar_queda() -> void:
	# Define uma velocidade apenas para baixo (Eixo Y positivo)
	# 400.0 é um bom valor, mas você pode aumentar ou diminuir se quiser a queda mais rápida/lenta
	velocity = Vector2(0, 400.0) 
	move_and_slide()
