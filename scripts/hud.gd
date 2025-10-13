# /scripts/hud.gd (Atualizado para o Marcador de Oxigênio)
extends CanvasLayer

signal planta_selecionada(planta_id: int)

# --- NOVO: REFERÊNCIA AO RÓTULO ---
@onready var oxygen_label: Label = $OxygenLabel

func _ready() -> void:
	# Conecta os botões existentes (mantido do seu código)
	$Control/HBoxContainer/BtnPlanta1.pressed.connect(func(): _on_button_pressed(1))
	$Control/HBoxContainer/BtnPlanta2.pressed.connect(func(): _on_button_pressed(2))
	$Control/HBoxContainer/BtnPlanta3.pressed.connect(func(): _on_button_pressed(3))
	$Control/HBoxContainer/BtnPlanta4.pressed.connect(func(): _on_button_pressed(4))
	$Control/HBoxContainer/BtnPlanta5.pressed.connect(func(): _on_button_pressed(5))
	$Control/HBoxContainer/BtnPlanta6.pressed.connect(func(): _on_button_pressed(6))
	
	# --- CONEXÃO DO SISTEMA DE OXIGÊNIO ---
	
	# 1. Conecta o sinal global do GameData à função local _on_oxygen_changed
	GameData.oxygen_changed.connect(_on_oxygen_changed)
	
	# 2. Chama a função uma vez para definir o valor inicial (ex: 200 O₂)
	_on_oxygen_changed(GameData.oxygen_points)


func _on_button_pressed(planta_id: int) -> void:
	print("Planta escolhida:", planta_id)
	emit_signal("planta_selecionada", planta_id)

# --- NOVA FUNÇÃO: ATUALIZA O RÓTULO ---
# Esta função é chamada automaticamente toda vez que GameData.add_oxygen() ou GameData.spend_oxygen() são usados.
func _on_oxygen_changed(new_value: int) -> void:
	# Atualiza o texto do Label com o novo saldo de Oxigênio
	oxygen_label.text = str(new_value)
