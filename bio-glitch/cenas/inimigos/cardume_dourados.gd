extends Node2D

@export var dourado_scene: PackedScene

@export var fish_amount: int = 8
@export var fish_speed: float = 230.0
@export var fish_damage: int = 1

@export var direction: Vector2 = Vector2.LEFT

@export var chase_player: bool = true
@export var vertical_chase_strength: float = 0.65

@export var horizontal_spacing: float = 54.0
@export var vertical_spacing: float = 34.0
@export var random_offset: float = 30.0

@export var target_offset_range_x: float = 40.0
@export var target_offset_range_y: float = 120.0

@export var wave_speed_min: float = 2.0
@export var wave_speed_max: float = 5.0
@export var wave_strength_min: float = 10.0
@export var wave_strength_max: float = 35.0

@export var spawn_one_by_one: bool = true
@export var time_between_spawns: float = 0.13

@export var activate_on_player_enter: bool = true
@export var auto_start: bool = false
@export var start_only_once: bool = true

@onready var activation_area: Area2D = $ActivationArea
@onready var spawn_origin: Marker2D = $SpawnOrigin
@onready var timer: Timer = $Timer

var already_started := false
var current_fish_index := 0


func _ready() -> void:
	if dourado_scene == null:
		push_error("ERRO: Coloque a cena DouradoSuicida.tscn no campo Dourado Scene do Inspector.")
		return
	
	timer.wait_time = time_between_spawns
	timer.one_shot = false
	
	timer.timeout.connect(_on_timer_timeout)
	activation_area.body_entered.connect(_on_activation_area_body_entered)
	
	if auto_start:
		start_cardume()


func _on_activation_area_body_entered(body: Node2D) -> void:
	if not activate_on_player_enter:
		return
	
	if start_only_once and already_started:
		return
	
	# Mudamos aqui para ele só ativar quando o player correto entrar
	if body.is_in_group("alvo_dourados"):
		call_deferred("start_cardume")


func start_cardume() -> void:
	if start_only_once and already_started:
		return
	
	already_started = true
	current_fish_index = 0
	
	if spawn_one_by_one:
		spawn_next_fish()
		timer.start()
	else:
		spawn_all_fish()


func spawn_all_fish() -> void:
	for i in range(fish_amount):
		spawn_fish(i)


func spawn_next_fish() -> void:
	if current_fish_index >= fish_amount:
		timer.stop()
		return
	
	spawn_fish(current_fish_index)
	current_fish_index += 1


func _on_timer_timeout() -> void:
	spawn_next_fish()


func spawn_fish(index: int) -> void:
	var fish = dourado_scene.instantiate()
	get_parent().add_child(fish)
	
	fish.global_position = spawn_origin.global_position + get_fish_offset(index)
	
	var individual_target_offset := Vector2(
		randf_range(-target_offset_range_x, target_offset_range_x),
		randf_range(-target_offset_range_y, target_offset_range_y)
	)
	
	var individual_wave_offset := randf_range(0.0, TAU)
	var individual_wave_speed := randf_range(wave_speed_min, wave_speed_max)
	var individual_wave_strength := randf_range(wave_strength_min, wave_strength_max)
	
	if fish.has_method("setup"):
		fish.setup(
			direction,
			fish_speed,
			fish_damage,
			chase_player,
			vertical_chase_strength,
			individual_target_offset,
			individual_wave_offset,
			individual_wave_speed,
			individual_wave_strength
		)


func get_fish_offset(index: int) -> Vector2:
	var angle := index * 1.7
	var radius := sqrt(float(index)) * horizontal_spacing
	
	var x_offset := cos(angle) * radius
	var y_offset := sin(angle) * radius
	
	var random_x := randf_range(-random_offset, random_offset)
	var random_y := randf_range(-random_offset, random_offset)
	
	var offset := Vector2(x_offset + random_x, y_offset + random_y)
	
	return offset
