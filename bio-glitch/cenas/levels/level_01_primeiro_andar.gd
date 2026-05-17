extends Node2D

@onready var players = $Players
@onready var glitch_ui = $UI/GlitchUI
@onready var objective_label = $UI/ObjectiveLabel
@onready var fade_black: ColorRect = $UI/FadeBlack

var glitch_activated := false


func _ready() -> void:
	
	block_players()
	Dialogic.start("level1_intro")
	await Dialogic.timeline_ended
	unblock_players()
	
func start_glitch_event() -> void:
	if glitch_activated:
		return
	
	glitch_activated = true
	
	block_players()
	
	shake_camera(glitch_ui.glitch_duration, 5.0)
	await glitch_ui.start_glitch()
	
	objective_label.visible = false
	
	Dialogic.start("serva_alerta_glitch")
	await Dialogic.timeline_ended
	
	await fade_to_black(1.0)
	await get_tree().create_timer(1.0).timeout
	
	get_tree().change_scene_to_file("res://cenas/levels/Level_01_Distopico.tscn")
	
func block_players() -> void:
	for child in players.get_children():
		if child.has_method("set_can_move"):
			child.set_can_move(false)
		else:
			block_recursive(child)


func unblock_players() -> void:
	for child in players.get_children():
		if child.has_method("set_can_move"):
			child.set_can_move(true)
		else:
			unblock_recursive(child)


func block_recursive(node: Node) -> void:
	if "can_move" in node:
		node.can_move = false
	
	for child in node.get_children():
		block_recursive(child)


func unblock_recursive(node: Node) -> void:
	if "can_move" in node:
		node.can_move = true
	
	for child in node.get_children():
		unblock_recursive(child)


func _on_glitch_trigger_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	
	start_glitch_event()
	
func shake_camera(duration: float, strength: float) -> void:
	var camera := get_viewport().get_camera_2d()
	
	if camera == null:
		return
	
	var original_offset := camera.offset
	var time := 0.0
	
	while time < duration:
		time += get_process_delta_time()
		
		camera.offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		
		await get_tree().process_frame
	
	camera.offset = original_offset

func fade_to_black(duration: float = 1.0) -> void:
	fade_black.visible = true
	
	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", 1.0, duration)
	
	await tween.finished

func fade_from_black(duration: float = 1.0) -> void:
	fade_black.visible = true
	
	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", 0.0, duration)
	
	await tween.finished
	
	fade_black.visible = false
