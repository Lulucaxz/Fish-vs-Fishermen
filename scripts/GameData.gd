extends Node

# Pontos de Oxigênio (o recurso para gastar)
var oxygen_points: int = 50

# Sinal emitido sempre que os pontos de Oxigênio mudam (para o HUD atualizar)
signal oxygen_changed(new_value: int)

# --- NOVO: ARMAZENAMENTO DA SELEÇÃO ---
# (Isto estava faltando no seu arquivo )
# Mapeia o slot do HUD (1-6) para o caminho da CENA (.tscn) do personagem
var selected_characters_paths: Dictionary = {}
# Mapeia o slot do HUD (1-6) para o caminho da TEXTURA (.png) do card
var selected_characters_textures: Dictionary = {}
# --- FIM NOVO ---


# Função para adicionar Oxigênio
func add_oxygen(amount: int):
	oxygen_points += amount
	emit_signal("oxygen_changed", oxygen_points)
	print("Oxigênio adicionado! Total: ", oxygen_points)

# Função para gastar Oxigênio (Usada no mapa para colocar plantas)
func spend_oxygen(amount: int) -> bool:
	if oxygen_points >= amount:
		oxygen_points -= amount
		emit_signal("oxygen_changed", oxygen_points)
		print("Oxigênio gasto. Restante: ", oxygen_points)
		return true # Gasto bem-sucedido
	else:
		# print("Oxigênio insuficiente!")
		return false # Gasto falhou
