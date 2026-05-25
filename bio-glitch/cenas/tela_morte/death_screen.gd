extends CanvasLayer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_button_pressed() -> void:
	var caminho_da_fase = "res://cenas/levels/Level_01_Distopico.tscn"
	
	var err = get_tree().change_scene_to_file(caminho_da_fase)
	
	if err != OK:
		print("ERRO: Caminho da cena não encontrado! Verifique o caminho em _on_retry_button_pressed()")
