

extends Area2D

@export var travel_speed: float    = 500.0   # Velocidade de avanço (px/s)
@export var max_range:   float    = 280.0   # Alcance máximo antes de se destruir (px)
@export var base_damage: int = 0

var _direction:      Vector2 = Vector2.RIGHT  
var _distance_traveled: float = 0.0           
var _hit_enemy:      bool    = false        #Isso aqui define se vai ser single ou multi target   


var _owner_player: Node2D = null

#Sinal para o qte
signal enemy_hooked(enemy: Node2D, hitbox: Area2D)


@onready var _debug_rect: ColorRect = $DebugRect  # Debug do ataque a bolinha amarela la


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _hit_enemy:
		return

	var step: float = travel_speed * delta
	position += _direction * step
	_distance_traveled += step

	if _distance_traveled >= max_range:
		queue_free()


func launch(from_position: Vector2, direction: Vector2, owner_player: Node2D) -> void:
	global_position = from_position
	_direction      = direction.normalized()
	_owner_player   = owner_player
	_hit_enemy      = false
	_distance_traveled = 0.0

	if _direction.x < 0 and _debug_rect:
		_debug_rect.position.x = -_debug_rect.size.x


func _on_body_entered(body: Node2D) -> void:
	print("[DEBUG HITBOX] Encostei em: ", body.name)
	if _hit_enemy:
		return

	if not body.is_in_group("enemy"):
		return

	if body.has_method("can_be_hooked") and not body.can_be_hooked():
		print("[HITBOX] A isca bateu e deslizou! Peixe invulnerável no momento.")
		return

	_hit_enemy = true

	if body.has_method("take_damage"):
		body.take_damage(base_damage)

	set_physics_process(false)

	emit_signal("enemy_hooked", body, self)
