extends StaticBody3D

# Referência ao texto 3D que mostra a dica (ex: "Pressione E")
@onready var prompt_label: Label3D = $Label3D
var velocity = Vector3.ZERO
var direction = Vector3.UP
# Quando o player interage
func interact() -> void:
	print("Pegou o objeto!")
	queue_free()  # Remove o objeto da cena (como se fosse coletado)

# Mostra o aviso de interação
func show_bar() -> void:
	if prompt_label:
		prompt_label.visible = true

# Esconde o aviso de interação
func hide_bar()	 -> void:
	if prompt_label:
		prompt_label.visible = false

func _physics_process(delta: float) -> void:
	velocity += -direction*9.8*delta
	
move_and_slide()
