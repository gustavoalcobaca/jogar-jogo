extends StaticBody3D

# Referência ao texto 3D que mostra a dica (ex: "Pressione E")
@onready var prompt_label: Label3D = $Label3D

# Quando o player interage
func interact() -> void:
	print("Pegou o objeto!")
	queue_free()  # Remove o objeto da cena (como se fosse coletado)

# Mostra o aviso de interação
func show_prompt() -> void:
	if prompt_label:
		prompt_label.visible = true

# Esconde o aviso de interação
func hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false
