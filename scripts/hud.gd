extends CanvasLayer

signal planta_selecionada(planta_id: int)

@onready var oxygen_label: Label = $OxygenLabel # Rótulo para o saldo de O₂
@onready var pause = get_tree().get_root().find_child("Pause", true, false)

func _ready() -> void:
	# Conecta os botões de planta à função _on_button_pressed
	$Control/HBoxContainer/BtnPlanta1.pressed.connect(func(): _on_button_pressed(1))
	$Control/HBoxContainer/BtnPlanta2.pressed.connect(func(): _on_button_pressed(2))
	$Control/HBoxContainer/BtnPlanta3.pressed.connect(func(): _on_button_pressed(3))
	$Control/HBoxContainer/BtnPlanta4.pressed.connect(func(): _on_button_pressed(4))
	$Control/HBoxContainer/BtnPlanta5.pressed.connect(func(): _on_button_pressed(5))
	$Control/HBoxContainer/BtnPlanta6.pressed.connect(func(): _on_button_pressed(6))
	
	# Conexão do sistema de Oxigênio (O₂) global
	GameData.oxygen_changed.connect(_on_oxygen_changed)
	
	# Define o valor inicial do Label
	_on_oxygen_changed(GameData.oxygen_points)
	
	print("HUD encontrado e conectado!")


func _on_button_pressed(planta_id: int) -> void:
	print("Planta escolhida:", planta_id)
	emit_signal("planta_selecionada", planta_id)


# Função chamada automaticamente pelo GameData para atualizar o saldo
func _on_oxygen_changed(new_value: int) -> void:
	oxygen_label.text = str(new_value)


func _on_pause_pressed() -> void:
	pause.visible = true
	get_tree().paused = true
