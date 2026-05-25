extends CanvasLayer

@export_category("Configurações do QTE")
@export var qte_duration: float = 1.2 # Tempo total que o cursor leva para cruzar a barra (menor = mais difícil)
@export var success_start: float = 0.65 # Ponto inicial da área verde (0.0 a 1.0) - 0.65 significa 65% da barra
@export var success_width: float = 0.20 # Tamanho da área verde (0.20 significa 20% da barra)
@export var qte_action: String = "attack_fisgar" # Certifique-se de usar a mesma ação do Input Map

@export_category("Configurações de Puxão")
@export var pull_speed: float = 300.0
@export var pull_distance: float = 80.0 # Diminuí um pouco para o peixe chegar mais perto

signal qte_succeeded(enemy: Node2D)
signal qte_failed(enemy: Node2D)

var _active: bool = false
var _current_time: float = 0.0
var _target_enemy: Node2D = null
var _hitbox: Node2D = null
var _player: Node2D = null

var _pulling: bool = false
var _pull_target: Node2D = null

# Referências da UI
@onready var _panel: Control = $QTEPanel
@onready var _label: Label = $QTEPanel/Label
@onready var _bar_bg: ColorRect = $QTEPanel/TimerBarBG
@onready var _green_zone: ColorRect = $QTEPanel/GreenZone
@onready var _cursor: ColorRect = $QTEPanel/Cursor

var _bar_max_width: float = 200.0

func _ready() -> void:
	_panel.visible = false
	_bar_max_width = _bar_bg.size.x
	
	# Configura a posição e tamanho da zona verde visualmente baseado nos exports
	_green_zone.position.x = _bar_bg.position.x + (_bar_max_width * success_start)
	_green_zone.size.x = _bar_max_width * success_width
	_green_zone.color = Color(0.2, 0.9, 0.2) # Verde


func _process(delta: float) -> void:
	if _active:
		_current_time += delta
		
		# Calcula o progresso (de 0.0 a 1.0)
		var progress: float = _current_time / qte_duration
		
		# Move o cursor na tela
		_cursor.position.x = _bar_bg.position.x + (_bar_max_width * clamp(progress, 0.0, 1.0))

		# Se o jogador apertar o botão
		if Input.is_action_just_pressed(qte_action):
			_check_qte_input(progress)
			return

		# Se o tempo acabar e ele não apertar
		if progress >= 1.0:
			print("[QTE] Falhou! Tempo esgotado.")
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
	_current_time = 0.0
	_active       = true

	_show_qte_ui()
	print("[QTE] Iniciado! Pressione no momento exato!")


func _check_qte_input(current_progress: float) -> void:
	# Verifica se o progresso está dentro da zona verde
	var in_green_zone = current_progress >= success_start and current_progress <= (success_start + success_width)
	
	if in_green_zone:
		print("[QTE] Acertou na mosca!")
		_resolve_qte(true)
	else:
		print("[QTE] Apertou na hora errada!")
		_resolve_qte(false)


func _resolve_qte(success: bool) -> void:
	_active = false
	_hide_qte_ui()

	if is_instance_valid(_hitbox):
		_hitbox.queue_free()

	if success:
		print("[QTE] SUCESSO! Puxando inimigo e aplicando dano máximo.")
		emit_signal("qte_succeeded", _target_enemy)
		_start_pull(_target_enemy)
	else:
		print("[QTE] FALHA! Apenas dano base aplicado e inimigo escapou.")
		emit_signal("qte_failed", _target_enemy)
		_target_enemy = null


func _start_pull(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return

	_pull_target = enemy
	_pulling     = true

	if enemy.has_method("on_being_pulled"):
		enemy.on_being_pulled(true)


func _do_pull(delta: float) -> void:
	var to_player: Vector2 = _player.global_position - _pull_target.global_position
	var dist: float        = to_player.length()

	if dist <= pull_distance:
		_finish_pull()
		return

	if _pull_target is CharacterBody2D:
		_pull_target.velocity = to_player.normalized() * pull_speed
		_pull_target.move_and_slide()


func _finish_pull() -> void:
	_pulling = false

	if is_instance_valid(_pull_target):
		if _pull_target.has_method("on_being_pulled"):
			_pull_target.on_being_pulled(false)
			
		if "is_dead" in _pull_target and _pull_target.is_dead:
			# Arremessa o peixe morto e deleta ele após 2 segundos
			_pull_target.velocity = Vector2(0, 1000.0)
			get_tree().create_timer(2.0).timeout.connect(_pull_target.queue_free)

	print("[QTE] Pull finalizado.")
	_pull_target  = null
	_target_enemy = null


func _show_qte_ui() -> void:
	_panel.visible = true
	_cursor.position.x = _bar_bg.position.x # Reseta o cursor
	if _label:
		_label.text = "FISGUE!"

func _hide_qte_ui() -> void:
	_panel.visible = false
