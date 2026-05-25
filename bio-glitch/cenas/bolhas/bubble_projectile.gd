extends Area2D

# Variáveis exportadas aparecem no Inspector
@export var speed: float = 300.0
@export var damage: int = 1
@export var max_lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var is_popping: bool = false

# Pega a referência dos nós filhos quando a cena carregar
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# 1. Toca a animação inicial
	anim_sprite.play("spawn")
	
	# 2. Conecta sinais via código (evita esquecer de clicar no painel de nós)
	body_entered.connect(_on_body_entered)
	anim_sprite.animation_finished.connect(_on_animation_finished)
	
	# 3. Cria um timer para destruir a bolha se ela não acertar nada
	var timer := get_tree().create_timer(max_lifetime)
	timer.timeout.connect(_on_lifetime_timeout)

func _process(delta: float) -> void:
	# Move a bolha todo frame apenas se não estiver estourando
	if not is_popping:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_popping: 
		return # Impede de causar dano duas vezes
	
	# --- LÓGICA DE ACERTAR O INIMIGO ---
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage) # Aplica o dano no inimigo
		pop_bubble() # Estoura a bolha
		return # Encerra a função aqui para não testar o resto à toa
		
	# --- LÓGICA DE ACERTAR PAREDES/CENÁRIO ---
	# Verifica se bateu no chão/paredes do cenário (TileMapLayer) ou objetos sólidos (StaticBody2D)
	if body is TileMapLayer or body is StaticBody2D:
		pop_bubble()

func pop_bubble() -> void:
	is_popping = true
	# Desativa a colisão imediatamente para não dar dano duplo
	col_shape.set_deferred("disabled", true)
	anim_sprite.play("pop")

func _on_animation_finished() -> void:
	# Troca de spawn para fly
	if anim_sprite.animation == "spawn" and not is_popping:
		anim_sprite.play("fly")
	# Se a animação que terminou foi o pop, apaga a bolha do jogo
	elif anim_sprite.animation == "pop":
		queue_free()

func _on_lifetime_timeout() -> void:
	# Estoura sozinho caso a bolha tenha ido muito longe
	if not is_popping:
		pop_bubble()
