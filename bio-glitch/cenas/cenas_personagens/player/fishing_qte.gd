extends CanvasLayer

@export var qte_window:       float  = 1.5    # Tempo do qte
@export var pull_speed:       float  = 300.0  # Velocidade com que o inimigo é puxado 
@export var pull_distance:    float  = 180.0  # Distância mínima do pullaté o player
@export var qte_action:       String = "qte_fisgar" 
@export var pull_damage_bonus: int   = 10     #Aumenta o dano se der qte

signal qte_succeeded(enemy: Node2D) 
signal qte_failed(enemy: Node2D)     

var _active:          bool    = false
var _timer:           float   = 0.0
var _target_enemy:    Node2D  = null
var _hitbox:          Node2D  = null   
var _player:          Node2D  = null   

var _pulling:         bool    = false
var _pull_target:     Node2D  = null

#Debug
@onready var _panel:      Control  = $QTEPanel
@onready var _label:      Label    = $QTEPanel/Label
@onready var _timer_bar:  ColorRect = $QTEPanel/TimerBar
@onready var _bar_bg:     ColorRect = $QTEPanel/TimerBarBG

# Calcular o progresso da barra
var _bar_max_width: float = 200.0


func _ready() -> void:
	# Começa escondido
	_panel.visible = false
	_bar_max_width = _timer_bar.size.x if _timer_bar else 200.0


func _process(delta: float) -> void:
	if _active:
		_timer -= delta
		_update_timer_bar()

		if Input.is_action_just_pressed(qte_action):
			_resolve_qte(true)
			return

		if _timer <= 0.0:
			_resolve_qte(false)
		return

	if _pulling and is_instance_valid(_pull_target) and is_instance_valid(_player):
		_do_pull(delta)


func start(enemy: Node2D, hitbox: Node2D, player: Node2D) -> void:
	if _active or _pulling:
		return  

	_target_enemy = enemy
	_hitbox       = hitbox
	_player       = player
	_timer        = qte_window
	_active       = true

	_show_qte_ui()
	print("[QTE] Iniciado! Pressione F para fisgar!")


func _resolve_qte(success: bool) -> void:
	_active = false
	_hide_qte_ui()

	if is_instance_valid(_hitbox):
		_hitbox.queue_free()

	if success:
		print("[QTE] SUCESSO! Puxando inimigo...")
		emit_signal("qte_succeeded", _target_enemy)
		_start_pull(_target_enemy)
	else:
		print("[QTE] FALHA! Apenas dano base aplicado.")
		emit_signal("qte_failed", _target_enemy)
		_target_enemy = null


func _start_pull(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return

	_pull_target = enemy
	_pulling     = true

	if enemy.has_method("receber_dano") and pull_damage_bonus > 0:
		enemy.receber_dano(pull_damage_bonus)

	if enemy.has_method("on_being_pulled"):
		enemy.on_being_pulled(true)


func _do_pull(delta: float) -> void:
	var to_player: Vector2 = _player.global_position - _pull_target.global_position
	var dist: float        = to_player.length()

	if dist <= pull_distance:
		_finish_pull()
		return

	var move_step: Vector2 = to_player.normalized() * pull_speed * delta

	if _pull_target is CharacterBody2D:
		_pull_target.velocity = to_player.normalized() * pull_speed
		_pull_target.move_and_slide()
	else:
		_pull_target.global_position += move_step


func _finish_pull() -> void:
	_pulling = false

	if is_instance_valid(_pull_target):
		if _pull_target.has_method("on_being_pulled"):
			_pull_target.on_being_pulled(false)

	print("[QTE] Pull finalizado.")
	_pull_target  = null
	_target_enemy = null



func _show_qte_ui() -> void:
	_panel.visible = true
	if _label:
		_label.text = "[ Pressione F para fisgar! ]"
	_update_timer_bar()


func _hide_qte_ui() -> void:
	_panel.visible = false


func _update_timer_bar() -> void:
	if not _timer_bar:
		return
	var ratio: float = clamp(_timer / qte_window, 0.0, 1.0)
	_timer_bar.size.x = _bar_max_width * ratio
	#Muda a cor conforme a necessidade 
	if ratio > 0.5:
		_timer_bar.color = Color(0.2, 0.9, 0.2)  
	elif ratio > 0.25:
		_timer_bar.color = Color(0.9, 0.8, 0.1)  
	else:
		_timer_bar.color = Color(0.9, 0.2, 0.1)  
