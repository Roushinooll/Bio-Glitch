extends Node2D

@onready var players = $Players
@onready var fade_black: ColorRect = $UI/FadeBlack


func _ready() -> void:
	
	block_players()
	
	await get_tree().create_timer(0.2).timeout
	await fade_from_black(1.0)
	
	unblock_players()

func fade_from_black(duration: float = 1.0) -> void:
	fade_black.visible = true
	fade_black.modulate.a = 1.0
	
	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", 0.0, duration)
	
	await tween.finished
	
	fade_black.visible = false

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
