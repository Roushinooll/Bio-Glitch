extends CharacterBody2D

@export var speed: float = 230.0
@export var damage: int = 1
@export var max_health: int = 2

var current_health: int

@export var direction: Vector2 = Vector2.LEFT

@export var sprite_faces_left: bool = true

@export var target_group: String = "alvo_dourados"
@export var chase_player: bool = true
@export var vertical_chase_strength: float = 0.65

@export var die_when_hit_player: bool = true
@export var destroy_when_out_of_screen: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hitbox_collision: CollisionShape2D = $HitboxArea/CollisionShape2D
@onready var explosion_sprite: AnimatedSprite2D = $ExplosionSprite
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var active := true
var already_hit := false
var target: Node2D = null

var target_offset := Vector2.ZERO
var wave_offset := 0.0
var wave_speed := 0.0
var wave_strength := 0.0


func _ready() -> void:
	current_health = max_health
	direction = direction.normalized()
	
	find_target()
	update_sprite_direction()
	
	explosion_sprite.visible = false
	
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	visible_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var move_direction := direction
	
	if chase_player and target != null and is_instance_valid(target):
		move_direction = get_suicide_direction()
	
	# Atualiza a direção interna para o flip do sprite acompanhar o movimento real
	direction = move_direction

	velocity = move_direction * speed
	move_and_slide()
	update_sprite_direction()


func setup(
	new_direction: Vector2,
	new_speed: float,
	new_damage: int,
	new_chase_player: bool = true,
	new_vertical_chase_strength: float = 0.65,
	new_target_offset: Vector2 = Vector2.ZERO,
	new_wave_offset: float = 0.0,
	new_wave_speed: float = 0.0,
	new_wave_strength: float = 0.0
) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	chase_player = new_chase_player
	vertical_chase_strength = new_vertical_chase_strength
	
	target_offset = new_target_offset
	wave_offset = new_wave_offset
	wave_speed = new_wave_speed
	wave_strength = new_wave_strength
	
	find_target()
	update_sprite_direction()


func find_target() -> void:
	var possible_targets = get_tree().get_nodes_in_group(target_group)
	
	if possible_targets.is_empty():
		target = null
		return
	
	var closest_target: Node2D = null
	var closest_distance := INF
	
	for possible_target in possible_targets:
		if possible_target is Node2D:
			var distance = global_position.distance_to(possible_target.global_position)
			
			if distance < closest_distance:
				closest_distance = distance
				closest_target = possible_target
	
	target = closest_target


func get_suicide_direction() -> Vector2:
	if target == null or not is_instance_valid(target):
		return direction
	
	var time_wave := sin(Time.get_ticks_msec() / 1000.0 * wave_speed + wave_offset) * wave_strength
	
	var target_position := target.global_position + target_offset
	target_position.y += time_wave

	# --- CORREÇÃO ---
	# Antes: o X ficava travado na direção de spawn, então ao passar pelo alvo
	# o peixe continuava reto para sempre.
	# Agora: aponta diretamente para o alvo em X e Y, perseguindo em todas as direções.
	var to_target := target_position - global_position
	return to_target.normalized()


func update_sprite_direction() -> void:
	if direction.x < 0:
		sprite.flip_h = not sprite_faces_left
	elif direction.x > 0:
		sprite.flip_h = sprite_faces_left


func _on_hitbox_body_entered(body: Node2D) -> void:
	if already_hit:
		return
	
	if body.is_in_group("enemy"):
		return
	
	# Só causa dano se for do grupo alvo correto (axolote), não o player principal
	if body.is_in_group(target_group):
		already_hit = true
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		if die_when_hit_player:
			die()
	elif body.is_in_group("player_principal") and not body.is_in_group(target_group):
		# Colide fisicamente mas não causa dano nem morre — apenas passa pelo player principal
		pass


func die() -> void:
	active = false
	
	body_collision.set_deferred("disabled", true)
	hitbox_collision.set_deferred("disabled", true)
	
	sprite.visible = false
	
	if explosion_sprite.sprite_frames != null and explosion_sprite.sprite_frames.has_animation("explode"):
		explosion_sprite.visible = true
		explosion_sprite.play("explode")
		await explosion_sprite.animation_finished
	
	queue_free()


func _on_screen_exited() -> void:
	if destroy_when_out_of_screen:
		queue_free()

func take_damage(amount: int) -> void:
	if not active or already_hit:
		return
		
	current_health -= amount
	
	if current_health <= 0:
		already_hit = true
		die()
