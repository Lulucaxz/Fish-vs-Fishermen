extends Node2D

@export var waveLimit: int = 5

@onready var tilemap_layer: TileMapLayer = $TileMap/TileMapLayer
@onready var inimigos_scene: Array[PackedScene] = [
	load("res://scenes/inmg_base.tscn"),
	load("res://scenes/inmg_isopor.tscn")
]

@onready var spawnTime = $SpawnTime
var planta_selecionada_id: int = -1

# Dicionário com os caminhos das plantas
var plantas_paths := {
	1: "res://scenes/algas.tscn",
	2: "res://scenes/cavalo.tscn"
}

var plantas: Array = []
var cavalos: Array = []

var inmgPos_linha: int = 6
var inmgLimit: int = waveLimit

func _ready() -> void:
	# Tenta localizar o HUD em qualquer lugar da árvore de cena
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud:
		hud.planta_selecionada.connect(_on_planta_selecionada)
		# Inicializa o display de O₂ na HUD com o saldo atual
		GameData.oxygen_changed.emit(GameData.oxygen_points) 
		print("HUD encontrado e conectado!")
	else:
		push_warning("HUD não encontrado! Verifique o nome do nó HUD na cena principal.")
	spawnTime.start()

func _on_planta_selecionada(planta_id: int) -> void:
	planta_selecionada_id = planta_id
	print("Planta selecionada no mapa:", planta_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if planta_selecionada_id == -1:
			return

		var mouse_pos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = tilemap_layer.local_to_map(mouse_pos)
		var world_pos: Vector2 = tilemap_layer.map_to_local(cell)
		
		if cell.x < 2 or cell.y < 0 or cell.x > 16 or cell.y > 6:
			print("Célula clicada:", cell)
			print("Fora do mapa")
			return

		# 1. Carrega o caminho da planta e a cena
		var path = plantas_paths.get(planta_selecionada_id, "")
		if path == "":
			push_warning("Caminho da planta não encontrado!")
			planta_selecionada_id = -1
			return

		var planta_scene: PackedScene = load(path)
		if not planta_scene:
			push_warning("Cena da planta não encontrada: " + str(path))
			planta_selecionada_id = -1
			return
			
		# 2. OBTÉM O CUSTO POR INSTANCIAÇÃO TEMPORÁRIA (CORREÇÃO DE COMPATIBILIDADE)
		var custo_planta: int = 0
		var temp_planta = planta_scene.instantiate()
		
		if temp_planta:
			custo_planta = temp_planta.custo # Lê a propriedade diretamente
			temp_planta.queue_free() # Remove o objeto temporário imediatamente
		
		if custo_planta == 0:
			push_warning("ERRO: Custo da planta é 0 ou não foi lido! Verifique a variável @export 'custo'.")
			return
		
		# 3. VERIFICA E GASTA OXIGÊNIO (PAGAMENTO)
		if not GameData.spend_oxygen(custo_planta):
			print("Oxigênio insuficiente! Saldo: ", GameData.oxygen_points, " | Custo:", custo_planta)
			return # Sai da função, impede a colocação
			
		# 4. INSTANCIAÇÃO FINAL (Pagamento bem-sucedido)
		var planta = planta_scene.instantiate()
		
		add_child(planta)
		planta.position = world_pos
		
		# 5. Adiciona aos arrays de rastreamento
		var planta_data = {
			'pos': world_pos,
			'node': planta
		}
		
		if planta_selecionada_id == 4: # Cavalo-Marinho
			cavalos.append(planta_data)
		else: # Alga ou outra planta genérica
			plantas.append(planta_data)
		
		planta_selecionada_id = -1  # Limpa a seleção


func _on_spawn_time_timeout() -> void:
	spawn()
	
func spawn():
	if get_tree().get_nodes_in_group("inimigos").size() >= waveLimit:
		return
	
	var inmgLinha = randi() % inmgPos_linha 
	
	var celulaInmg = Vector2i(18, inmgLinha) 
	
	var inmgPos_mundo = tilemap_layer.map_to_local(celulaInmg) 
	
	if inimigos_scene:
		var waveScene = inimigos_scene[randi() % inimigos_scene.size()]
		var inmg = waveScene.instantiate()
		inmg.position = inmgPos_mundo
		inmg.position.y -= 8
		inmg.z_index = inmgLinha
		add_child(inmg)
