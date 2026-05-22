extends CanvasLayer

@onready var life_bar: TextureProgressBar = $LifeContainer/CenterContainer/LifeBox/LifeBar
@onready var life_text: Label = $LifeContainer/CenterContainer/LifeBox/LifeText

func _ready() -> void:
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player_principal")
	
	if player == null:
		print("ERRO: HUD não encontrou nenhum player no grupo player_principal")
		return
	
	player.life_changed.connect(update_life)
	update_life(player.current_life, player.max_life)
	
	print("HUD conectada ao player")

func update_life(current_life: int, max_life: int) -> void:
	life_bar.max_value = max_life
	life_bar.value = current_life
	
	life_text.text = str(current_life) + " / " + str(max_life)
