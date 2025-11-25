extends Node3D

@export var letter_mat: StandardMaterial3D
@onready var player = get_tree().current_scene.get_node("CharacterBody3D")
@onready var letter_2d: TextureRect = get_tree().current_scene.get_node("UI/TextureRect")
@onready var interact_text = get_tree().current_scene.get_node("UI/interact_text")



func _ready() -> void:
	set_material()

func set_material():
	$MeshInstance3D.material_override = letter_mat

var letter_opened = false

func interact(player_speed: float, sensitivty: float, letter_visibility: bool):
	print("ajdaksjdkasjdka")
	player.SPEED = player_speed
	player.get_node("head").sensitivty = sensitivty 
	letter_2d.visible = letter_visibility
	letter_2d.texture = letter_mat.albedo_texture
	await get_tree().create_timer(0.1, false).timeout
	letter_opened = letter_visibility
	player.get_node("head/raycast").enabled = !letter_visibility
	
	
func _process(_delta: float) -> void:
	if letter_opened:
		if Input.is_action_just_pressed("interact"):
			interact(5.0,0.2, false)
			if !interact_text.visible:
				interact_text.visible = true 
		else:
			if interact_text.visible:
				interact_text.visible = false
		
	else:
		if interact_text.visible:
			interact_text.visible = false
