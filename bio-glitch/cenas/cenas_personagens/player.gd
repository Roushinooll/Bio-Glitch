extends CharacterBody2D

signal life_changed(current_life: int, max_life: int)
signal player_died

var speed: float = 200.0
var can_move := true

const HITBOX_SCENE = preload("res://cenas/cenas_personagens/player/FishingHitbox.tscn")
const QTE_SCENE    = preload("res://cenas/cenas_personagens/player/FishingQTE.tscn")

@export var attack_cooldown: float = 1.2   # Tempo de recarga entre ataques (s)


var _facing_direction: float = 1.0

var _cooldown_timer: float = 0.0

var _qte_node: Node = null

var _active_hitbox: Node = null


@export var max_life: int = 100
var current_life: int
var is_dead: bool = false

func _ready() -> void:
	add_to_group("player_principal")
	print("Player entrou no grupo")
	
	current_life = max_life
	print("Vida inicial do player:", current_life)
	
	life_changed.emit(current_life, max_life)

	_qte_node = QTE_SCENE.instantiate()
	add_child(_qte_node)

	_qte_node.qte_succeeded.connect(_on_qte_succeeded)
	_qte_node.qte_failed.connect(_on_qte_failed)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
		_facing_direction = 1.0
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
		_facing_direction = -1.0
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1

	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_life -= amount
	current_life = clamp(current_life, 0, max_life)

	print("Player tomou dano:", amount)
	print("Vida atual:", current_life)

	life_changed.emit(current_life, max_life)

	if current_life <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_life += amount
	current_life = clamp(current_life, 0, max_life)

	print("Player curou:", amount)
	print("Vida atual:", current_life)

	life_changed.emit(current_life, max_life)

func die() -> void:
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	
	print("Player morreu")
	player_died.emit()

#Area do ataque 
func _handle_attack_input(delta: float) -> void:
	# Desconta o cooldown
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		return

	#confirma se apertou E para atacar
	if Input.is_action_just_pressed("attack_fisgar"):
		_launch_fishing_attack()


##Direção da hitbox
func _launch_fishing_attack() -> void:
	if is_instance_valid(_active_hitbox):
		return

	_cooldown_timer = attack_cooldown

	var hitbox = HITBOX_SCENE.instantiate()
	get_parent().add_child(hitbox)
	_active_hitbox = hitbox

	var launch_offset := Vector2(_facing_direction * 60.0, 0.0)
	var launch_pos    := global_position + launch_offset
	var direction     := Vector2(_facing_direction, 0.0)

	hitbox.launch(launch_pos, direction, self)

	hitbox.enemy_hooked.connect(_on_enemy_hooked)

	print("[Player] Ataque de fisgar lançado para ", "direita" if _facing_direction > 0 else "esquerda")


## Marca o hit na hitgox
func _on_enemy_hooked(enemy: Node2D, hitbox: Area2D) -> void:
	print("[Player] Inimigo fisgado: ", enemy.name)

	# Inicia o QTE passando o inimigo, a hitbox e a referência ao player
	if _qte_node and _qte_node.has_method("start"):
		_qte_node.start(enemy, hitbox, self)

	# tira hitbox do bixo
	_active_hitbox = null


func _on_qte_succeeded(enemy: Node2D) -> void:
	print("[Player] QTE bem-sucedido! Inimigo sendo puxado.")

## Se o qte falhar
func _on_qte_failed(enemy: Node2D) -> void:
	print("[Player] QTE falhou. Apenas dano base aplicado.")
