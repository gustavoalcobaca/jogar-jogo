extends CharacterBody3D

# Variáveis de movimento do player
@export_category("Configurações do jogador")
@export var speed = 5.0
@export var jump_force = 4.5
@export var run_speed = 10.0

# Configuração de vida 
@export var health_max = 100.0
@export var health = 100.0

# Configurações da barra de stamina
@export var stamina_max = 100.0
@export var stamina = 100.0
@export var stamina_drain = 15.0
@export var stamina_recovery = 2.0


# Configurações da barra de sanidade
@export var sanity_max = 100.0
@export var sanity = 100.0
@export var sanity_recovery = 1.0 # velocidade de recuperação fora da zona
@export_range(0.0, 1.0, 0.1) var sanity_alpha_incomplete := 0.5 # transparência configurável
@onready var sanity_bar = $CanvasLayer/SanityBar
var inside_sanity_zone = false

# Configuração de pegar objeto
func check_hover_collision():
	if raycast.is_colliding():
		var hover_collider = raycast.get_collider()
		if hover_collider and is_instance_valid(hover_collider) and hover_collider.has_method("interact") and hover_collider.has_method("show_prompt"):
			if current_interactable != hover_collider:
				if current_interactable:
					current_interactable.hide_prompt()
				current_interactable = hover_collider
				current_interactable.show_prompt()
				
		else:
			hide_current_prompt()
	else:
		hide_current_prompt()
		
func hide_current_prompt():
	if current_interactable:
		current_interactable.hide_prompt()
		current_interactable = null

# pega objeto
@onready var raycast = $Node3D/Node3D/vertical/Camera3D/raycast
var current_interactable = null

# Mira (crosshair)
@onready var crosshair = $CanvasLayer/Crosshair

# Configuração do mouse
@export_category("Configurações do mouse")
@export var mouse_sensitivity := 0.2
@export var camera_limite_down := -45.0
@export var camera_limite_up := 10.0

# ✅ Configuração da movimentação e animação (corrigido)
@onready var animation_tree: AnimationTree = $AnimationTree

# Gravidade do projeto
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var cam_ver := 0.0
var is_running = false
var cursor_locked = true

func activate():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit and hit.has_method("interact"):
			hit.interact()



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Stamina
	$CanvasLayer/StaminaBar.max_value = stamina_max
	$CanvasLayer/StaminaBar.value = stamina
	
	
	# Vida
	$CanvasLayer/HealthBar.max_value = health_max
	$CanvasLayer/HealthBar.value = health
	update_health_bar_color()
	
	# Sanidade (começa invisível)
	sanity_bar.max_value = sanity_max
	sanity_bar.value = sanity
	sanity_bar.visible = false

	# Centraliza a mira
	var viewport_size_i = get_viewport().size
	var viewport_size = Vector2(viewport_size_i) # converte Vector2i → Vector2
	crosshair.position = viewport_size / 2 - Vector2(crosshair.size) / 2

	# ✅ Ativa o AnimationTree (se necessário)
	animation_tree.active = true


func _input(event: InputEvent) -> void: 
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		cam_ver -= event.relative.y * mouse_sensitivity
		cam_ver = clamp(cam_ver, camera_limite_down, camera_limite_up)
		#$Node3D/Node3D.rotation_degrees.x = cam_ver
		$Node3D/Node3D/vertical/Camera3D.rotation_degrees.x = cam_ver
		
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("interact"):
		activate()


# Função do sistema de vida 
func take_damage(amount: float) -> void:
	health -= amount
	health = max(health, 0) # não deixa vida ficar negativa
	update_health_bar_color()
	if health == 0:
		die()


# Mostra o game over na tela
func die() -> void:
	print("Player morreu!")
	# Aqui você pode reiniciar a cena ou abrir tela de game over


# Sistema de cor da barra de vida
func update_health_bar_color() -> void:
	var ratio = health / health_max
	var style = StyleBoxFlat.new()

	if ratio > 0.6:
		style.bg_color = Color(0, 1, 0) # Verde
	elif ratio > 0.3:
		style.bg_color = Color(1, 1, 0) # Amarelo
	else:
		style.bg_color = Color(1, 0, 0) # Vermelho

	$CanvasLayer/HealthBar.add_theme_stylebox_override("fill", style)


func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	check_hover_collision()

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
		
	# Corrida (stamina)
	if Input.is_action_pressed("run") and stamina > 0:
		is_running = true
		stamina -= stamina_drain * delta
	else:
		is_running = false
		stamina = min(stamina + stamina_recovery * delta, stamina_max)
		
	# Sanidade (drena dentro da zona / recupera fora)
	if inside_sanity_zone and sanity > 0:
		sanity -= 2 * delta
		sanity = max(sanity, 0)
	elif not inside_sanity_zone and sanity < sanity_max:
		sanity += sanity_recovery * delta
		sanity = min(sanity, sanity_max)

	# Atualiza barra de sanidade
	sanity_bar.value = sanity

	if sanity < sanity_max:
		sanity_bar.visible = true
		sanity_bar.modulate.a = sanity_alpha_incomplete
	else:
		sanity_bar.visible = false

	if sanity == 0:
		print("Player perdeu a sanidade!")
	
	# Movimento
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = speed
	if is_running:
		current_speed = run_speed

	if direction.length() > 0.0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
	# ✅ Atualiza o parâmetro do AnimationTree
	animation_tree.set("parameters/blend_position", input_dir.length())

	move_and_slide()
	
	# Atualiza as barras
	$CanvasLayer/StaminaBar.value = stamina
	$CanvasLayer/HealthBar.value = health
	update_health_bar_color()



# Funções da sanidade (ligadas ao Area3D SanityZone)
func _on_sanityzone_body_entered(body: Node) -> void:
	if body == self:
		inside_sanity_zone = true
		print("Sanidade agora está visível (drenando)")


func _on_sanityzone_body_exited(body: Node) -> void:
	if body == self:
		inside_sanity_zone = false
		print("Sanidade se recuperando fora da zona") 
