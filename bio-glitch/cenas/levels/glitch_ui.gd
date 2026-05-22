extends CanvasLayer

@onready var red_flash: ColorRect = $RedFlash
@onready var dark_pulse: ColorRect = $DarkPulse
@onready var glitch_bars: Control = $GlitchBars
@onready var error_symbols: Control = $ErrorSymbols

@export var glitch_duration: float = 4.0

var glitch_started := false

@export var glitch_font: FontFile
@export var glitch_font_min_size: int = 14
@export var glitch_font_max_size: int = 28

var error_texts := [
	"S.E.R.V.A. ACTIVE",
	"THREAT DETECTED",
	"HUMAN PRESENCE CONFIRMED",
	"BIOPARK LOCKDOWN",
	"FAUNA PROTECTION PROTOCOL",
	"REALITY CORRUPTED",
	"ACCESS DENIED",
	"SYSTEM OVERRIDE",
	"ENVIRONMENT COLLAPSE",
	"DISTORTION LEVEL CRITICAL",
	"RA_SIGNAL_DEAD",
	"YOU SHOULD NOT BE HERE",
	"PROTOCOL: PUNISHMENT",
	"CORE INSTABILITY",
	"BIOTECH FUSION STARTED",
	"NO ESCAPE"
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
	
	tween.tween_property(red_flash, "modulate:a", 0.85, 0.08)
	tween.tween_property(red_flash, "modulate:a", 0.10, 0.08)
	tween.tween_property(red_flash, "modulate:a", 0.95, 0.06)
	tween.tween_property(red_flash, "modulate:a", 0.25, 0.12)
	tween.tween_property(red_flash, "modulate:a", 0.75, 0.08)
	tween.tween_property(red_flash, "modulate:a", 0.05, 0.10)
	tween.tween_property(red_flash, "modulate:a", 0.90, 0.05)
	tween.tween_property(red_flash, "modulate:a", 0.0, 0.35)
	
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
	
	var random_color := randi_range(0, 4)

	if random_color == 0:
		bar.color = Color(0.75, 0.0, 0.0, randf_range(0.55, 0.95))
	elif random_color == 1:
		bar.color = Color(0.15, 0.0, 0.0, randf_range(0.45, 0.85))
	elif random_color == 2:
		bar.color = Color(0.0, 0.0, 0.0, randf_range(0.50, 0.90))
	elif random_color == 3:
		bar.color = Color(0.45, 0.02, 0.02, randf_range(0.50, 0.85))
	else:
		bar.color = Color(0.9, 0.9, 0.9, randf_range(0.08, 0.20))
	
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
		randf_range(20.0, viewport_size.x - 260.0),
		randf_range(20.0, viewport_size.y - 60.0)
	)
	
	var text_color_type := randi_range(0, 2)

	if text_color_type == 0:
		label.modulate = Color(0.9, 0.0, 0.0, randf_range(0.75, 1.0))
	elif text_color_type == 1:
		label.modulate = Color(0.35, 0.0, 0.0, randf_range(0.70, 1.0))
	else:
		label.modulate = Color(0.05, 0.0, 0.0, randf_range(0.80, 1.0))

	label.rotation_degrees = randf_range(-8.0, 8.0)
	
	if glitch_font != null:
		label.add_theme_font_override("font", glitch_font)

	label.add_theme_font_size_override(
		"font_size",
		randi_range(glitch_font_min_size, glitch_font_max_size)
	)
	
	var tween := create_tween()
	tween.tween_property(label, "position:x", label.position.x + randf_range(-80.0, 80.0), 0.06)
	tween.tween_property(label, "modulate:a", 0.0, randf_range(0.20, 0.45))
	
	await tween.finished
	
	if is_instance_valid(label):
		label.queue_free()


func _start_dark_pulse_loop() -> void:
	var time := 0.0
	
	while time < glitch_duration:
		dark_pulse.visible = true
		dark_pulse.modulate.a = randf_range(0.35, 0.65)
		
		await get_tree().create_timer(randf_range(0.08, 0.18)).timeout
		
		dark_pulse.modulate.a = 0.0
		
		var delay := randf_range(0.05, 0.18)
		await get_tree().create_timer(delay).timeout
		
		time += delay
	
	dark_pulse.visible = false


func _clear_glitch_objects() -> void:
	for child in glitch_bars.get_children():
		child.queue_free()
	
	for child in error_symbols.get_children():
		child.queue_free()
