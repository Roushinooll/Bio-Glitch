extends CharacterBody2D

var speed: float = 200.0
var can_move := true

@export var margin: float = 30.0

func _physics_process(delta: float) -> void:
	
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector = Vector2(
		Input.get_action_strength("move_right2") - Input.get_action_strength("move_left2"),
		Input.get_action_strength("move_down2") - Input.get_action_strength("move_up2")
	).normalized()

	velocity = input_vector * speed
	move_and_slide()

	limit_inside_player1_camera()
	

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
