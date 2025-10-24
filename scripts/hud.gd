extends CanvasLayer

signal planta_selecionada(planta_id: int)
signal selection_complete 

@onready var oxygen_label: Label = $OxygenLabel 
@onready var pause = get_tree().get_root().find_child("Pause", true, false)

# --- AJUSTE O CAMINHO E OS NOMES SE NECESSÁRIO ---
@onready var card_buttons_paths: Array[NodePath] = [ # Mudei para NodePath para depuração
	"Control/VBoxContainer/BtnPlanta1", # <--- VERIFIQUE ESTE CAMINHO
	"Control/VBoxContainer/BtnPlanta2",
	"Control/VBoxContainer/BtnPlanta3",
	"Control/VBoxContainer/BtnPlanta4",
	"Control/VBoxContainer/BtnPlanta5",
	"Control/VBoxContainer/BtnPlanta6"  # <--- VERIFIQUE ESTE CAMINHO
]
# Nome do nó filho TextureRect
var texture_rect_child_name = "TextureRect" # <--- VERIFIQUE ESTE NOME
# --- FIM DOS AJUSTES ---

# Define o tamanho fixo que queremos para os nossos cards
var fixed_card_size = Vector2(30, 16) # <- Ajuste este valor se precisar

var card_buttons: Array = [] # Array para guardar os nós dos botões

func _ready() -> void:
	
	print("--- Iniciando _ready() do HUD ---") # DEBUG
	
	for i in range(card_buttons_paths.size()):
		var button_path = card_buttons_paths[i]
		var button = get_node_or_null(button_path) # Tenta pegar o botão pelo caminho
		
		# --- DEBUG: Verifica se o botão foi encontrado ---
		if button:
			print("Botão %d encontrado em: %s" % [i+1, button_path])
			card_buttons.append(button) # Adiciona o botão encontrado ao array
			
			# Conecta o sinal
			button.pressed.connect(func(): _on_button_pressed(i + 1))
			
			# Configura o layout (como antes)
			button.custom_minimum_size = fixed_card_size
			
			# Tenta encontrar o nó filho TextureRect
			var texture_rect = button.get_node_or_null(texture_rect_child_name) as TextureRect
			if texture_rect:
				print("  Nó filho '%s' encontrado dentro de %s." % [texture_rect_child_name, button.name])
				# Configura o TextureRect (como antes)
				texture_rect.anchors_preset = Control.PRESET_FULL_RECT
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			else:
				# --- DEBUG: ERRO CRÍTICO se não achar o filho ---
				push_error("  ERRO: Nó filho '%s' NÃO ENCONTRADO dentro de %s! Verifique o nome na cena." % [texture_rect_child_name, button.name])
		else:
			# --- DEBUG: ERRO CRÍTICO se não achar o botão ---
			push_error("ERRO: Botão %d NÃO ENCONTRADO no caminho: %s! Verifique o caminho no script e na cena." % [i+1, button_path])
			card_buttons.append(null) # Adiciona null para manter o tamanho do array
			
	if GameData:
		GameData.oxygen_changed.connect(_on_oxygen_changed)
		_on_oxygen_changed(GameData.oxygen_points)
	else:
		push_error("GameData (Autoload) não encontrado!")

	self.selection_complete.connect(_on_selection_complete)
	
	print("HUD _ready() finalizado.") # DEBUG


func _on_button_pressed(planta_id: int) -> void:
	print("Planta escolhida:", planta_id)
	emit_signal("planta_selecionada", planta_id)


func _on_oxygen_changed(new_value: int) -> void:
	if oxygen_label:
		oxygen_label.text = str(new_value)


func _on_pause_pressed() -> void:
	if pause:
		pause.visible = true
		get_tree().paused = true

# Função SÓ troca a textura do TextureRect filho
func _on_selection_complete():
	print("--- Iniciando _on_selection_complete ---")
	
	if not GameData:
		push_error("GameData não encontrado em _on_selection_complete!")
		return
		
	var selected_textures = GameData.selected_characters_textures
	
	if selected_textures.is_empty():
		print("HUD: GameData.selected_textures está VAZIO. Tentando de novo em 0.1s...")
		await get_tree().create_timer(0.1).timeout 
		_on_selection_complete() 
		return
		
	print("Texturas selecionadas encontradas no GameData: ", selected_textures) 

	# --- DEBUG: Verifica o tamanho do array de botões ---
	if card_buttons.size() != 6:
		push_error("ERRO: O array card_buttons tem %d elementos, deveria ter 6!" % card_buttons.size())
		return

	for i in range(card_buttons.size()): # Loop deve ir de 0 a 5
		var slot_id = i + 1
		var button = card_buttons[i] # Pega o botão do array preenchido no _ready
		
		# --- DEBUG: Pula se o botão for null (não encontrado no _ready) ---
		if not button:
			print("AVISO: Pulando Slot %d porque o botão não foi encontrado no _ready()." % slot_id)
			continue 

		print("Processando Slot %d (Botão: %s)" % [slot_id, button.name])

		if selected_textures.has(slot_id):
			var texture_path = selected_textures[slot_id]
			print("  Caminho da textura para o slot %d: %s" % [slot_id, texture_path])
			
			# Encontra o nó TextureRect filho usando o nome correto
			var texture_rect = button.get_node_or_null(texture_rect_child_name) as TextureRect
			
			if texture_rect:
				var loaded_texture = load(texture_path)
				if loaded_texture:
					texture_rect.texture = loaded_texture # Apenas define a textura
					print("      SUCESSO: Textura carregada para o slot %d!" % slot_id) # DEBUG
				else:
					push_error("      ERRO: Falha ao carregar textura: %s" % texture_path)
			else:
				# Este erro não deveria acontecer se o _ready() funcionou
				push_error("      ERRO INESPERADO: Nó filho '%s' não encontrado em _on_selection_complete para %s" % [texture_rect_child_name, button.name])
				
		else:
			# Limpa a textura se não foi selecionado
			var texture_rect = button.get_node_or_null(texture_rect_child_name) as TextureRect
			if texture_rect:
				texture_rect.texture = null 
			push_warning("  AVISO: Nenhuma textura selecionada para o slot " + str(slot_id))
			# button.disabled = true
