extends CharacterBody2D

signal warning_started(enemy_name: String)
signal warning_ended(enemy_name: String)

enum State {
	IDLE,
	MOVE_TO_ATTACK_POINT,
	ATTACK,
	RETREAT
}

@export var enemy_name: String = "Pirarara"

@export var speed: float = 110.0
@export var retreat_speed: float = 130.0
@export var damage: int = 1

@export var attack_distance: float = 55.0
@export var attack_point_tolerance: float = 25.0
@export var retreat_distance: float = 120.0
@export var attack_hold_time: float = 0.18

@export var sprite_faces_left: bool = true
@export var mouth_offset_x: float = -28.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var warning_area: Area2D = $WarningArea
@onready var detection_area: Area2D = $DetectionArea
@onready var bite_hitbox: Area2D = $BiteHitBox
@onready var bite_hitbox_collision: CollisionShape2D = $BiteHitBox/CollisionShape2D

var player: Node2D = null
var state: State = State.IDLE

var facing_direction: int = -1
var attack_timer: float = 0.0
var already_hit_player: bool = false

var attack_point: Vector2 = Vector2.ZERO
var retreat_point: Vector2 = Vector2.ZERO


func _ready() -> void:
	bite_hitbox.monitoring = false
	bite_hitbox_collision.disabled = true

	warning_area.body_entered.connect(_on_warning_area_body_entered)
	warning_area.body_exited.connect(_on_warning_area_body_exited)

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	bite_hitbox.body_entered.connect(_on_bite_hitbox_body_entered)

	update_facing(-1)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			process_idle()

		State.MOVE_TO_ATTACK_POINT:
			process_move_to_attack_point()

		State.ATTACK:
			process_attack(delta)

		State.RETREAT:
			process_retreat()


func process_idle() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if player != null:
		prepare_attack_cycle()


func prepare_attack_cycle() -> void:
	if player == null:
		state = State.IDLE
		return

	if global_position.x > player.global_position.x:
		facing_direction = -1
	else:
		facing_direction = 1

	update_facing(facing_direction)

	attack_point = player.global_position - Vector2(facing_direction * attack_distance, 0)
	retreat_point = player.global_position - Vector2(facing_direction * retreat_distance, 0)

	state = State.MOVE_TO_ATTACK_POINT


func process_move_to_attack_point() -> void:
	if player == null:
		state = State.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_point = player.global_position - Vector2(facing_direction * attack_distance, 0)
	retreat_point = player.global_position - Vector2(facing_direction * retreat_distance, 0)

	var distance_to_attack_point := global_position.distance_to(attack_point)

	if distance_to_attack_point <= attack_point_tolerance:
		velocity = Vector2.ZERO
		start_attack()
		return

	var direction := global_position.direction_to(attack_point)
	velocity = direction * speed

	move_and_slide()


func start_attack() -> void:
	state = State.ATTACK
	velocity = Vector2.ZERO
	attack_timer = attack_hold_time
	already_hit_player = false

	bite_hitbox.monitoring = true
	bite_hitbox_collision.set_deferred("disabled", false)

	call_deferred("check_bite_overlap")


func process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	attack_timer -= delta

	if attack_timer <= 0:
		end_attack()


func end_attack() -> void:
	bite_hitbox.monitoring = false
	bite_hitbox_collision.set_deferred("disabled", true)

	if player != null:
		retreat_point = player.global_position - Vector2(facing_direction * retreat_distance, 0)

	state = State.RETREAT
	velocity = Vector2.ZERO


func process_retreat() -> void:
	if player == null:
		state = State.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_retreat_point := global_position.distance_to(retreat_point)

	if distance_to_retreat_point <= 4.0:
		global_position = retreat_point
		velocity = Vector2.ZERO

		if global_position.x > player.global_position.x:
			update_facing(-1)
		else:
			update_facing(1)

		prepare_attack_cycle()
		return

	var direction := global_position.direction_to(retreat_point)

	if direction.x < 0:
		update_facing(-1)
	elif direction.x > 0:
		update_facing(1)

	velocity = direction * retreat_speed

	move_and_slide()


func update_facing(direction: int) -> void:
	facing_direction = direction

	if sprite_faces_left:
		sprite.flip_h = direction > 0
	else:
		sprite.flip_h = direction < 0

	bite_hitbox.position.x = abs(mouth_offset_x) * direction


func check_bite_overlap() -> void:
	if already_hit_player:
		return

	var bodies := bite_hitbox.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("player"):
			hit_player(body)
			return


func hit_player(body: Node) -> void:
	if already_hit_player:
		return

	if not body.has_method("take_damage"):
		return

	body.take_damage(damage)
	already_hit_player = true


func _on_bite_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hit_player(body)


func _on_warning_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		warning_started.emit(enemy_name)


func _on_warning_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		warning_ended.emit(enemy_name)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

		if state == State.IDLE:
			prepare_attack_cycle()


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		if state == State.IDLE:
			player = null
