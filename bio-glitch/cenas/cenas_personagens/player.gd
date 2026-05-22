extends CharacterBody2D

signal life_changed(current_life: int, max_life: int)
signal player_died

var speed: float = 200.0
var can_move := true

@export var max_life: int = 100
var current_life: int
var is_dead: bool = false

func _ready() -> void:
	add_to_group("player_principal")
	print("Player entrou no grupo")
	
	current_life = max_life
	print("Vida inicial do player:", current_life)
	
	life_changed.emit(current_life, max_life)

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
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
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
