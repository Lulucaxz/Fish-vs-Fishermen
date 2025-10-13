extends Node

# Pontos de Oxigênio (o recurso para gastar)
var oxygen_points: int = 100

# Sinal emitido sempre que os pontos de Oxigênio mudam (para o HUD atualizar)
signal oxygen_changed(new_value: int)

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
