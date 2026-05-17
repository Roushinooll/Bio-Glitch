extends CanvasLayer

@onready var red_flash: ColorRect = $RedFlash
@onready var dark_pulse: ColorRect = $DarkPulse
@onready var glitch_bars: Control = $GlitchBars
@onready var error_symbols: Control = $ErrorSymbols

@export var glitch_duration: float = 4.0

var glitch_started := false

var error_texts := [
	"ERROR",
	"SYSTEM FAILURE",
	"RA_SIGNAL_LOST",
	"BIOPARK_CORE_ERROR",
	"404",
	"GLITCH",
	"WARNING",
	"S.E.R.V.A. OFFLINE",
	"DATA CORRUPTED",
	"REALITY SYNC FAILED"
]


func _ready() -> void:
	visible = false
	
	red_flash.visible = false
	dark_pulse.visible = false
	
	red_flash.modulate.a = 0.0
	dark_pulse.modulate.a = 0.0
	
	_clear_glitch_objects()


func start_glitch() -> void:
	if glitch_started:
		return
	
	glitch_started = true
	visible = true
	
	_clear_glitch_objects()
	
	_start_glitch_bars_loop()
	_start_error_symbols_loop()
	_start_dark_pulse_loop()
	
	await _red_flash_effect()
	await get_tree().create_timer(glitch_duration).timeout
	
	_clear_glitch_objects()
	
	red_flash.visible = false
	dark_pulse.visible = false
	
	visible = false


func _red_flash_effect() -> void:
	red_flash.visible = true
	red_flash.modulate.a = 0.0
	
	var tween := create_tween()
	
	tween.tween_property(red_flash, "modulate:a", 0.65, 0.15)
	tween.tween_property(red_flash, "modulate:a", 0.30, 0.25)
	tween.tween_property(red_flash, "modulate:a", 0.75, 0.15)
	tween.tween_property(red_flash, "modulate:a", 0.15, 0.30)
	tween.tween_property(red_flash, "modulate:a", 0.55, 0.20)
	tween.tween_property(red_flash, "modulate:a", 0.0, 0.45)
	
	await tween.finished


func _start_glitch_bars_loop() -> void:
	var time := 0.0
	
	while time < glitch_duration:
		_create_random_glitch_bar()
		
		var delay := randf_range(0.04, 0.12)
		await get_tree().create_timer(delay).timeout
		time += delay


func _create_random_glitch_bar() -> void:
	var bar := ColorRect.new()
	glitch_bars.add_child(bar)
	
	var viewport_size := get_viewport().get_visible_rect().size
	
	var bar_height := randf_range(4.0, 28.0)
	var bar_width := randf_range(80.0, viewport_size.x)
	
	bar.size = Vector2(bar_width, bar_height)
	bar.position = Vector2(
		randf_range(-100.0, viewport_size.x - 50.0),
		randf_range(0.0, viewport_size.y)
	)
	
	var random_color := randi_range(0, 3)
	
	if random_color == 0:
		bar.color = Color(1.0, 0.0, 0.0, randf_range(0.35, 0.75))
	elif random_color == 1:
		bar.color = Color(0.0, 1.0, 1.0, randf_range(0.25, 0.60))
	elif random_color == 2:
		bar.color = Color(1.0, 1.0, 1.0, randf_range(0.15, 0.40))
	else:
		bar.color = Color(0.0, 0.0, 0.0, randf_range(0.30, 0.65))
	
	var tween := create_tween()
	tween.tween_property(bar, "position:x", bar.position.x + randf_range(-80.0, 180.0), randf_range(0.08, 0.20))
	tween.tween_property(bar, "modulate:a", 0.0, randf_range(0.10, 0.25))
	
	await tween.finished
	
	if is_instance_valid(bar):
		bar.queue_free()


func _start_error_symbols_loop() -> void:
	var time := 0.0
	
	while time < glitch_duration:
		_create_error_symbol()
		
		var delay := randf_range(0.12, 0.25)
		await get_tree().create_timer(delay).timeout
		time += delay


func _create_error_symbol() -> void:
	var label := Label.new()
	error_symbols.add_child(label)
	
	var viewport_size := get_viewport().get_visible_rect().size
	
	label.text = error_texts.pick_random()
	label.position = Vector2(
		randf_range(20.0, viewport_size.x - 220.0),
		randf_range(20.0, viewport_size.y - 60.0)
	)
	
	label.modulate = Color(1.0, 0.05, 0.05, randf_range(0.65, 1.0))
	label.rotation_degrees = randf_range(-4.0, 4.0)
	
	label.add_theme_font_size_override("font_size", randi_range(14, 28))
	
	var tween := create_tween()
	tween.tween_property(label, "position:x", label.position.x + randf_range(-30.0, 30.0), 0.10)
	tween.tween_property(label, "modulate:a", 0.0, randf_range(0.30, 0.60))
	
	await tween.finished
	
	if is_instance_valid(label):
		label.queue_free()


func _start_dark_pulse_loop() -> void:
	var time := 0.0
	
	while time < glitch_duration:
		dark_pulse.visible = true
		dark_pulse.modulate.a = randf_range(0.10, 0.25)
		
		await get_tree().create_timer(randf_range(0.05, 0.10)).timeout
		
		dark_pulse.modulate.a = 0.0
		
		var delay := randf_range(0.10, 0.25)
		await get_tree().create_timer(delay).timeout
		
		time += delay
	
	dark_pulse.visible = false


func _clear_glitch_objects() -> void:
	for child in glitch_bars.get_children():
		child.queue_free()
	
	for child in error_symbols.get_children():
		child.queue_free()
