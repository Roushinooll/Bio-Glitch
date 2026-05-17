extends Node2D

@onready var players = $Players
@onready var objective_label = $UI/ObjectiveLabel
var primeiro_objetivo_concluido := false

func _ready() -> void:
	
	objective_label.visible = false

	
	block_players()
	Dialogic.start("level1_intro")
	await Dialogic.timeline_ended
	unblock_players()
	
	objective_label.visible = true

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


func _on_trigger_primeiro_objetivoa_2d_body_entered(body: Node2D) -> void:
	if primeiro_objetivo_concluido:
		return
	
	if body.name != "Player":
		return
	
	primeiro_objetivo_concluido = true
	objective_label.text = "Objetivo: Investigue a anomalia encontrada no corredor."
