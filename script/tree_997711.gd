extends Node3D

# === Atributos da árvore ===
@export var health_max: float = 100.0
@export var health: float = 100.0
@export var damage_per_click: float = 20.0

# === Regeneração ===
@export var regen_rate: float = 2.0 # vida regenerada por segundo
@export var regen_delay: float = 3.0 # segundos para começar regenerar após dano
var regen_timer: float = 0.0

# === Barra de vida ===
@onready var progress_bar: ProgressBar = $CanvasLayer/ProgressBar
var is_player_looking: bool = false


# ======================================
# INICIALIZAÇÃO
# ======================================
func _ready() -> void:
	progress_bar.max_value = health_max
	progress_bar.value = health
	progress_bar.visible = false
	_update_bar_color()


# ======================================
# VISIBILIDADE
# ======================================
func show_bar():
	if health > 0:
		is_player_looking = true
		progress_bar.visible = true

func hide_bar():
	is_player_looking = false
	progress_bar.visible = false


# ======================================
# DANO
# ======================================
func damage_tree(amount: float) -> void:
	health = max(health - amount, 0)
	regen_timer = regen_delay # reinicia o timer

	progress_bar.value = health
	_update_bar_color()

	if health <= 0:
		print("🌲 Árvore destruída!")
		queue_free()


# ======================================
# REGENERAÇÃO (LENTA)
# ======================================
func _process(delta: float) -> void:
	# Se vida está cheia, não regenera
	if health >= health_max:
		return

	# Conta o tempo até começar regenerar
	if regen_timer > 0:
		regen_timer -= delta
		return

	# Regenera vida
	health = min(health + regen_rate * delta, health_max)

	# Atualiza barra se player estiver olhando
	if is_player_looking:
		progress_bar.value = health
		_update_bar_color()


# ======================================
# COR DA BARRA
# ======================================
func _update_bar_color() -> void:
	var ratio = health / health_max
	var color: Color

	if ratio > 0.6:
		color = Color(0.2, 1.0, 0.2) # verde
	elif ratio > 0.3:
		color = Color(1.0, 1.0, 0.2) # amarelo
	else:
		color = Color(1.0, 0.2, 0.2) # vermelho

	# Aplica cor diretamente ao preenchimento da barra
	var style = StyleBoxFlat.new()
	style.bg_color = color
	progress_bar.add_theme_stylebox_override("fill", style)
