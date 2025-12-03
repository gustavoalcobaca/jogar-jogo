extends CharacterBody3D

# ========================
# CONFIGURAÇÕES DO JOGADOR
# ========================
@export_category("Configurações do jogador")
@export var speed: float = 10.0
@export var jump_force: float = 3.0
@export var run_speed: float = 20.0

# Vida
@export var health_max: float = 100.0
@export var health: float = 100.0

# Stamina
@export var stamina_max: float = 100.0
@export var stamina: float = 100.0
@export var stamina_drain: float = 0.0
@export var stamina_recovery: float = 2.0

# Sanidade
@export var sanity_max: float = 100.0
@export var sanity: float = 100.0
@export var sanity_recovery: float = 1.0
@export_range(0.0, 1.0, 0.1) var sanity_alpha_incomplete: float = 0.5
@onready var sanity_bar: ProgressBar = $CanvasLayer/SanityBar
var inside_sanity_zone: bool = false

# Interação
@onready var raycast: RayCast3D = $Node3D/Node3D/vertical/Camera3D/raycast
var current_interactable: Node = null

# Mira
@onready var crosshair: Control = $CanvasLayer/Crosshair

# Mouse
@export_category("Configurações do mouse")
@export var mouse_sensitivity: float = 0.2
@export var camera_limite_down: float = -45.0
@export var camera_limite_up: float = 45.0

# Animação
@onready var animation_tree: AnimationTree = $AnimationTree

# Gravidade e controle
#var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity: float = 20.8
var cam_ver: float = 0.0
var is_running: bool = false

# Câmera e headbob
@onready var camera: Camera3D = $Node3D/Node3D/vertical/Camera3D
@onready var camera_vertical: Node3D = $Node3D/Node3D/vertical
var t_bob: float = 0.0
const BOB_FREQ: float = 1.0
const BOB_AMP: float = 0.1
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 5.0

# ========================
# READY
# ========================
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Barras
	$CanvasLayer/StaminaBar.max_value = stamina_max
	$CanvasLayer/StaminaBar.value = stamina
	$CanvasLayer/HealthBar.max_value = health_max
	$CanvasLayer/HealthBar.value = health
	update_health_bar_color()

	sanity_bar.max_value = sanity_max
	sanity_bar.value = sanity
	sanity_bar.visible = false

	# Centralizar mira
	var viewport_size: Vector2 = get_viewport().size
	crosshair.position = viewport_size / 2.0 - crosshair.size / 2.0

	animation_tree.active = true

# ========================
# INPUT (mouse e ações)
# ========================
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		cam_ver -= event.relative.y * mouse_sensitivity
		cam_ver = clamp(cam_ver, camera_limite_down, camera_limite_up)
		camera_vertical.rotation_degrees.x = cam_ver

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("interact"):
		activate()

	if Input.is_action_just_pressed("mouse_left_click"):
		_check_tree_hit()

# ========================
# INTERAÇÃO COM OBJETOS
# ========================
func check_hover_collision() -> void:
	if raycast.is_colliding():
		print("opa")
		var col := raycast.get_collider()
		# cast seguro para Node se existir
		var obj: Node = col as Node
		if obj and obj.has_method("show_bar") and obj.has_method("hide_bar"):
			if current_interactable != obj and current_interactable and current_interactable.has_method("hide_bar"):
				current_interactable.hide_bar()

			obj.show_bar()
			current_interactable = obj
			return

	# Se não colidiu ou não é interagível
	if current_interactable and current_interactable.has_method("hide_bar"):
		current_interactable.hide_bar()
	current_interactable = null

# ========================
# CLIQUE NA ÁRVORE
# ========================
func _check_tree_hit() -> void:
	if raycast.is_colliding():
		var col := raycast.get_collider()
		var obj: Node = col as Node
		if obj and obj.has_method("damage_tree"):
			# se damage_tree espera um int
			obj.damage_tree(20)

func activate() -> void:
	if raycast.is_colliding():
		var col := raycast.get_collider()
		var hit: Node = col as Node
		if hit and hit.has_method("interact"):
			hit.interact()

# ========================
# VIDA / DANO
# ========================
func take_damage(amount: float) -> void:
	health = max(health - amount, 0)
	update_health_bar_color()

	if health == 0:
		die()

func die() -> void:
	print("💀 Player morreu!")

func update_health_bar_color() -> void:
	var ratio: float = health / health_max
	var style: StyleBoxFlat = StyleBoxFlat.new()

	if ratio > 0.6:
		style.bg_color = Color.GREEN
	elif ratio > 0.3:
		style.bg_color = Color.YELLOW
	else:
		style.bg_color = Color.RED

	$CanvasLayer/HealthBar.add_theme_stylebox_override("fill", style)

# ========================
# MOVIMENTO / FÍSICA
# ========================
func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	check_hover_collision()

	# Pular
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	# Corrida + stamina
	if Input.is_action_pressed("run") and stamina > 0:
		is_running = true
		stamina -= stamina_drain * delta
	else:
		is_running = false
		stamina = min(stamina + stamina_recovery * delta, stamina_max)

	# Movimento
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed: float = run_speed if is_running else speed

	if direction.length() > 0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# HEADBOB
	if is_on_floor() and direction.length() > 0.1:
		t_bob += delta * BOB_FREQ * (run_speed if is_running else speed)
		camera_vertical.position.x = cos(t_bob * 0.5) * (BOB_AMP * 0.5)
		camera_vertical.position.y = 1.7 + sin(t_bob) * BOB_AMP
	else:
		t_bob = 0
		camera_vertical.position = Vector3(0, 1.7, 0)

	# FOV Dinâmico
	var target_fov: float = BASE_FOV + (FOV_CHANGE if is_running else 0.0)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Aplicar movimento
	move_and_slide()

	# Atualizar barras
	$CanvasLayer/StaminaBar.value = stamina
	$CanvasLayer/HealthBar.value = health
	update_health_bar_color()

	# ========================
	# SANIDADE
	# ========================
	if inside_sanity_zone:
		sanity -= sanity_recovery * delta * 2.0
	else:
		sanity = min(sanity + sanity_recovery * delta, sanity_max)

	sanity = clamp(sanity, 0, sanity_max)
	sanity_bar.value = sanity

# ========================
# SANITY ZONE SIGNALS
# ========================
func _on_sanityzone_body_entered(body: Node) -> void:
	if body == self:
		inside_sanity_zone = true
		sanity_bar.visible = true

func _on_sanityzone_body_exited(body: Node) -> void:
	if body == self:
		inside_sanity_zone = false
		sanity_bar.visible = false
