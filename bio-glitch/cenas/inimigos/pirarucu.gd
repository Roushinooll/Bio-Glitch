extends CharacterBody2D

@export var normal_speed: float = 80.0
@export var swim_direction: Vector2 = Vector2.LEFT

@export var dash_speed: float = 850.0
@export var prepare_time: float = 0.10
@export var dash_duration: float = 0.40
@export var dash_cooldown: float = 1.2

@export var lock_y_position: bool = true

var player: Node2D = null

var is_active: bool = false

var state: String = "normal"
var prepare_timer: float = 0.0
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0

var start_y: float = 0.0
var player_inside_attack_area: bool = false


func _ready() -> void:
	start_y = global_position.y
	find_player()


func _physics_process(delta: float) -> void:
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

		if dash_timer <= 0:
			state = "normal"
			velocity = Vector2.ZERO
			cooldown_timer = dash_cooldown

		return

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
	player_inside_attack_area = false
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

func show_warning_ui() -> void:
	var warning_label = get_tree().get_first_node_in_group("pirarucu_warning_ui")

	if warning_label != null and warning_label.has_method("show_warning"):
		warning_label.show_warning()



func _on_warning_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		show_warning_ui()


func _on_start_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_principal"):
		is_active = true
