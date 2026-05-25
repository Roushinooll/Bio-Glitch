extends CharacterBody2D

signal morreu(inimigo_node)

@export var normal_speed: float = 80.0
@export var swim_direction: Vector2 = Vector2.LEFT

@export var dash_speed: float = 850.0
@export var prepare_time: float = 0.10
@export var dash_duration: float = 0.40
@export var dash_cooldown: float = 1.2

# --- NOVAS VARIÁVEIS DE RECUO ---
@export var retreat_speed: float = 150.0  # Velocidade que ele foge para a direita
@export var retreat_duration: float = 1.5 # Quanto tempo ele fica fugindo
var retreat_timer: float = 0.0

@export var lock_y_position: bool = true

var player: Node2D = null

var is_active: bool = false

# Agora os estados podem ser: "normal", "preparing", "dashing", "retreating"
var state: String = "normal" 
var prepare_timer: float = 0.0
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0

var start_y: float = 0.0
var player_inside_attack_area: bool = false

@onready var attack_area: Area2D = $AttackArea

@export var max_life: int = 3
var current_life: int = 3
var is_dead: bool = false


func _ready() -> void:
	current_life = max_life
	start_y = global_position.y
	find_player()
	
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		
	if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
		attack_area.body_exited.connect(_on_attack_area_body_exited)


func _physics_process(delta: float) -> void:
	if is_dead:
		move_and_slide()
		return
	
	if player == null:
		find_player()

	if not is_active:
		velocity = Vector2.ZERO
		move_and_slide()
		keep_y_locked()
		return

	if cooldown_timer > 0:
		cooldown_timer -= delta

	if state == "preparing":
		prepare_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		keep_y_locked()

		if prepare_timer <= 0:
			start_dash()
		return

	if state == "dashing":
		dash_timer -= delta
		velocity = swim_direction.normalized() * dash_speed
		velocity.y = 0
		move_and_slide()
		keep_y_locked()
		
		# --- NOVO: Checa se atropelou o player durante o dash ---
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider().is_in_group("player_principal"):
				hit_player(col.get_collider())
				break # Já bateu, não precisa checar mais de uma vez
		# --------------------------------------------------------

		if dash_timer <= 0:
			state = "normal"
			velocity = Vector2.ZERO
			cooldown_timer = dash_cooldown
		return

	# --- NOVO: Estado de recuo após acertar o player ---
	if state == "retreating":
		retreat_timer -= delta
		velocity = Vector2.RIGHT * retreat_speed # Foge para a direita
		velocity.y = 0
		move_and_slide()
		keep_y_locked()
		
		if retreat_timer <= 0:
			# Acabou de recuar, volta a olhar e caçar para a esquerda
			state = "normal"
			flip_sprite(false)
			cooldown_timer = dash_cooldown
		return

	# Comportamento Padrão
	if player_inside_attack_area and cooldown_timer <= 0:
		start_prepare_dash()
	else:
		normal_swim()


func find_player() -> void:
	player = get_tree().get_first_node_in_group("player_principal")

func normal_swim() -> void:
	velocity = swim_direction.normalized() * normal_speed
	velocity.y = 0
	move_and_slide()
	keep_y_locked()

func start_prepare_dash() -> void:
	state = "preparing"
	prepare_timer = prepare_time
	velocity = Vector2.ZERO

func start_dash() -> void:
	state = "dashing"
	dash_timer = dash_duration

func keep_y_locked() -> void:
	if lock_y_position:
		global_position.y = start_y

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		player_inside_attack_area = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		player_inside_attack_area = false


# --- NOVAS FUNÇÕES PARA ATACAR E RECUAR ---

func hit_player(target_player: Node2D) -> void:
	# Só ataca se estiver no meio do Dash
	if state != "dashing": return
	
	print("[Pirarucu] Bateu no Player!")
	
	# Dá o dano no player (se o player tiver a função take_damage)
	if target_player.has_method("take_damage"):
		target_player.take_damage(10) # Mude '1' para a quantidade de dano desejada
		
	# Inicia o Recuo
	state = "retreating"
	retreat_timer = retreat_duration
	flip_sprite(true) # Vira a imagem para a direita

func flip_sprite(is_retreating: bool) -> void:
	# ATENÇÃO AQUI: Troque "Sprite2D" pelo nome correto da sua imagem no Godot!
	# Se for um Sprite animado, provavelmente é "AnimatedSprite2D".
	var my_sprite = get_node_or_null("Sprite2D") 
	if my_sprite:
		my_sprite.flip_h = is_retreating

func can_be_hooked() -> bool:
	# Essa é a função que conversa com a Hitbox
	# Só permite ser pescado se estiver nadando de boas ou parando para preparar
	return state == "normal" or state == "preparing"

# ------------------------------------------


func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_life -= amount
	print("[Pirarucu] Tomou ", amount, " de dano. Vida restante: ", current_life)
	
	if current_life <= 0:
		die()

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	
	morreu.emit(self)
	
	$CollisionShape2D.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)
	
	lock_y_position = false
	velocity = Vector2(0, 1000.0) 
	
	await get_tree().create_timer(2.0).timeout
	queue_free()
