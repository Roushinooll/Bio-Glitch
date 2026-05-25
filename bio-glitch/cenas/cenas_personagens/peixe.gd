extends CharacterBody2D

var speed: float = 200.0
var can_move := true

@export var margin: float = 30.0

# --- NOVAS VARIÁVEIS DE ATAQUE ---
@export var bubble_scene: PackedScene
@export var attack_cooldown: float = 0.4

var last_direction: Vector2 = Vector2.RIGHT
var can_attack: bool = true

# Pega o marcador da boca do peixe
@onready var spawn_point: Marker2D = $BubbleSpawnPoint
# ---------------------------------

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector = Vector2(
		Input.get_action_strength("move_right2") - Input.get_action_strength("move_left2"),
		Input.get_action_strength("move_down2") - Input.get_action_strength("move_up2")
	).normalized()

	# --- NOVA LÓGICA DE DIREÇÃO ---
	# Só atualiza a direção se o jogador estiver apertando algum botão de movimento
	if input_vector != Vector2.ZERO:
		last_direction = input_vector
		update_spawn_point_position()
	# ------------------------------

	velocity = input_vector * speed
	move_and_slide()
	limit_inside_player1_camera()
	
	# --- NOVA LÓGICA DE ATIRAR ---
	if Input.is_action_just_pressed("attack2") and can_attack:
		shoot_bubble()
	# -----------------------------

# --- NOVAS FUNÇÕES ---
func update_spawn_point_position() -> void:
	# Isso garante que a bolha saia da boca dependendo de onde o peixe olha.
	# Multiplicamos a direção pela distância que a boca fica do centro do player.
	# O valor '20.0' é a distância em pixels. Aumente ou diminua conforme o tamanho do seu sprite.
	spawn_point.position = last_direction * 20.0

func shoot_bubble() -> void:
	# Proteção caso você esqueça de arrastar a cena no Inspector
	if bubble_scene == null:
		push_warning("Atenção: A cena da bolha não foi arrastada no Inspector do Player!")
		return
		
	# Inicia o cooldown
	can_attack = false
	
	# Instancia a bolha
	var bubble = bubble_scene.instantiate()
	
	# Adicionamos a bolha na raiz do jogo (get_parent()), NÃO no player.
	# Se adicionar no player, a bolha vai seguir o peixe depois de atirada.
	get_parent().add_child(bubble)
	
	# Coloca a bolha na posição do Marker2D
	bubble.global_position = spawn_point.global_position
	# Define para qual lado a bolha vai viajar
	bubble.direction = last_direction
	
	# Espera o tempo de cooldown acabar para poder atirar de novo
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
# ---------------------

# Sua função mantida 100% igual
func limit_inside_player1_camera() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var camera_center := camera.get_screen_center_position()
	var viewport_size := get_viewport_rect().size
	var camera_zoom := camera.zoom

	var visible_size := viewport_size * camera_zoom
	var half_visible_size := visible_size / 2.0

	var left_limit := camera_center.x - half_visible_size.x + margin
	var right_limit := camera_center.x + half_visible_size.x - margin
	var top_limit := camera_center.y - half_visible_size.y + margin
	var bottom_limit := camera_center.y + half_visible_size.y - margin

	global_position.x = clamp(global_position.x, left_limit, right_limit)
	global_position.y = clamp(global_position.y, top_limit, bottom_limit)

func take_damage(amount: int) -> void:
	var player_principal = get_tree().get_first_node_in_group("player_principal")
	
	if player_principal != null and player_principal.has_method("take_damage"):
		player_principal.take_damage(amount)
