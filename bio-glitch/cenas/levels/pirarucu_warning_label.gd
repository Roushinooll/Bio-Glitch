extends Label

var warning_running: bool = false

func show_warning() -> void:
	if warning_running:
		return

	warning_running = true
	visible = true
	text = "CUIDADO!"

	await get_tree().create_timer(1.2).timeout

	visible = false
	warning_running = false
