extends CanvasLayer

signal selection_finalized

@onready var selecao: CanvasLayer = $"."
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
@onready var hud = get_tree().get_root().find_child("HUD", true, false)

@onready var escolhidos_container = $MainContainer/EscolhidosContainer
@onready var personagens_container = $MainContainer/PersonagensContainer
@onready var last_row_container = $LastRowContainer
@onready var ready_btn = $ReadyContainer/ready_btn
@onready var feedback_label = $ChooseContainer/Label
@onready var ready_btn_label = $ReadyContainer/ready_btn

var current_selection_data: Array[Dictionary] = []

var character_data_map: Dictionary = {
    "BtnPlanta1": {
        "scene": "res://scenes/algas.tscn",
        "texture": "res://assets/Icones_HUD/card-algas.png"
    },
    "BtnPlanta2": {
        "scene": "res://scenes/cavalo.tscn",
        "texture": "res://assets/Icones_HUD/card-cavalo.png"
    },
    "BtnPlanta3": {
        "scene": "res://scenes/ourico.tscn",
        "texture": "res://assets/ourico-card.png"
    },
    "BtnPlanta4": {
        "scene": "res://scenes/tartaruga.tscn",
        "texture": "res://assets/card-tartaruga.png"
    },
    "BtnPlanta5": {
        "scene": "res://scenes/brigao.tscn",
        "texture": "res://assets/card-brigao.png"
    },
    "BtnPlanta6": {
        "scene": "res://scenes/baiacu.tscn",
        "texture": "res://assets/baiacu-card.png"
    },
    "BtnPlanta7": {
        "scene": "res://scenes/pxboi.tscn", 
        "texture": "res://assets/pxboi-card.png"
    },
    "BtnPlanta8": {
        "scene": "res://scenes/pinguim.tscn", 
        "texture": "res://assets/pinguim-card.png"
    },
    "BtnPlanta9": {
        "scene": "res://scenes/lagosta-boxeadora.tscn", 
        "texture": "res://assets/lagosta-card.png"
    }
}


func _ready() -> void:
    get_tree().paused = true
    
    hud.visible = false
    selecao.visible = true
    
    if ready_btn:
        ready_btn.pressed.connect(_on_ready_btn_pressed)
    else:
        push_error("Botão 'Ready' (ready_btn) não foi encontrado em selecao.gd!")
    
    for child in personagens_container.get_children():
        if child is Button:
            child.pressed.connect(_on_character_button_pressed.bind(child))
        
    for i in range(1, 7):
        var slot_panel = escolhidos_container.get_node("Slot" + str(i))
        if slot_panel:
            var deselect_btn = Button.new()
            deselect_btn.flat = true
            deselect_btn.anchors_preset = Control.PRESET_FULL_RECT
            slot_panel.add_child(deselect_btn)
            deselect_btn.pressed.connect(_on_slot_button_pressed.bind(i - 1))
            
            var texture_node = slot_panel.get_node("peixe-selecionado") as TextureRect
            if texture_node:
                # 1. Faz o TextureRect preencher o 'Slot'
                texture_node.anchors_preset = Control.PRESET_FULL_RECT
                
                # --- LINHA DO ERRO REMOVIDA ---
                # texture_node.layout_mode = Control.LAYOUT_MODE_ANCHORS (REMOVIDA)
                
                # 2. Configurações de textura
                texture_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                texture_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
            
    _update_ready_button_state()
    
func _process(delta: float) -> void:
    pass

func _on_character_button_pressed(button_node: Button) -> void:
    if current_selection_data.size() >= 6:
        feedback_label.text = "SELEÇÃO CHEIA! (Clique no slot para remover)"
        return
        
    var char_name = button_node.name
    if not character_data_map.has(char_name):
        push_warning("Dados não encontrados para o botão: " + char_name)
        return
        
    var data = character_data_map[char_name]
    
    current_selection_data.append(data)
    button_node.disabled = true
    
    _update_selection_ui()
    _update_ready_button_state()

func _on_slot_button_pressed(slot_index: int) -> void:
    if slot_index >= current_selection_data.size():
        return
        
    var removed_data = current_selection_data[slot_index]
    current_selection_data.remove_at(slot_index)
    
    var btn_name_to_enable = ""
    for btn_name in character_data_map:
        if character_data_map[btn_name]["scene"] == removed_data["scene"]:
            btn_name_to_enable = btn_name
            break
    
    var btn_node = personagens_container.find_child(btn_name_to_enable, true, false)
    if not btn_node: 
         btn_node = last_row_container.find_child(btn_name_to_enable, true, false)
         
    if btn_node:
        btn_node.disabled = false
    
    _update_selection_ui()
    _update_ready_button_state()

func _update_selection_ui() -> void:
    for i in range(1, 7):
        var slot_panel = escolhidos_container.get_node("Slot" + str(i))
        var texture_rect = slot_panel.get_node("peixe-selecionado") as TextureRect
        
        if i - 1 < current_selection_data.size():
            var data = current_selection_data[i-1]
            texture_rect.texture = load(data["texture"])
        else:
            texture_rect.texture = null
            
func _update_ready_button_state() -> void:
    if current_selection_data.size() == 6:
        ready_btn.disabled = false
        ready_btn_label.text = "READY"
        feedback_label.text = "CHOOSE YOUR CHARACTERS"
    else:
        ready_btn.disabled = true
        var restantes = 6 - current_selection_data.size()
        ready_btn_label.text = "Faltam %d" % restantes

func _on_ready_btn_pressed() -> void:
    if current_selection_data.size() != 6:
        push_error("Botão 'Ready' foi pressionado sem 6 personagens!")
        return
        
    # Salva os dados no GameData (como antes) 
    for i in range(current_selection_data.size()):
        var data = current_selection_data[i]
        var slot_id = i + 1
        GameData.selected_characters_paths[slot_id] = data["scene"]
        GameData.selected_characters_textures[slot_id] = data["texture"]

    # --- NOVO: EMITIR O SINAL ---
    emit_signal("selection_finalized")
    print("Sinal 'selection_finalized' emitido.") # DEBUG
    # --- FIM NOVO ---

    # Continua o jogo (como antes) 
    get_tree().paused = false
    hud.visible = true
    selecao.visible = false
    
    if hud.has_signal("selection_complete"):
        hud.emit_signal("selection_complete") # Avisa o HUD para atualizar texturas [cite: 148]
    else:
        push_warning("Crie o sinal 'selection_complete' no seu script do HUD!")
