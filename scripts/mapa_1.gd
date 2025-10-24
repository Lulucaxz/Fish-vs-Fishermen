extends Node2D

@export var waveLimit: int = 10

@onready var tilemap_layer: TileMapLayer = $TileMap/TileMapLayer
@onready var hud = get_tree().get_root().find_child("HUD", true, false)
@onready var selecao_peixe = get_tree().get_root().find_child("SelecaoPeixe", true, false)

@onready var inimigos_scene: Array[PackedScene] = [
	load("res://scenes/inmg_base.tscn"),
	load("res://scenes/inmg_isopor.tscn"),
	load("res://scenes/inmg_canudo.tscn"),
	load("res://scenes/inmg_garrafa.tscn"),
	load("res://scenes/inmg_barril.tscn")
]

@onready var spawnTime = $SpawnTime
@onready var waveTime = $WaveTime

var wave_atual: int = 1
var total_waves: int = 5
var inimigos_vivos: Array = []
var spawn_ativo: bool = false
var spawned_this_wave: int = 0
var jogo_ativo: bool = true
var planta_selecionada_id: int = -1 
var is_removing: bool = false 
	
var plantas_paths: Dictionary = {}

var plantas: Array = []
var cavalos: Array = []
var baiacus: Array = []
var ouricos: Array = []
var brigoes: Array = []
var tartarugas: Array = []
var pxBois: Array = []
var pinguins: Array = []
var lagostas: Array = []

var inmgPos_linha: int = 6
var inmgPos_col: int = 16
var waveAtiva: bool = false

var waves_config = [
	{ "tipos": [0], "quantidade": 5, "intervalo": 1.2 },
	{ "tipos": [0, 1], "quantidade": 7, "intervalo": 2 },
	{ "tipos": [0, 1, 2], "quantidade": 9, "intervalo": 2 },
	{ "tipos": [0, 1, 2, 3], "quantidade": 10, "intervalo": 2.3 },
	{ "tipos": [0, 1, 2, 3, 4], "quantidade": 12, "intervalo": 2.5 }
]

func _ready() -> void:
	plantas_paths = {
		1: "res://scenes/algas.tscn",
		2: "res://scenes/cavalo.tscn",
		3: "res://scenes/ourico.tscn",
		4: "res://scenes/tartaruga.tscn",
		5: "res://scenes/brigao.tscn",
		6: "res://scenes/baiacu.tscn"
	}
	print("MAPA_1: Caminhos padrão carregados inicialmente.") # DEBUG

	# --- NOVO: Conecta ao sinal da tela de seleção ---
	if selecao_peixe:
		if selecao_peixe.has_signal("selection_finalized"):
			selecao_peixe.selection_finalized.connect(_load_paths_from_gamedata)
			print("MAPA_1: Conectado ao sinal 'selection_finalized'.") # DEBUG
		else:
			push_warning("MAPA_1: Nó 'SelecaoPeixe' não tem o sinal 'selection_finalized'!")
	else:
		push_warning("MAPA_1: Nó 'SelecaoPeixe' não encontrado para conectar o sinal!")
	
	if hud:
		hud.planta_selecionada.connect(_on_planta_selecionada)
		if hud.has_signal("modo_remocao_ativado"):
			hud.modo_remocao_ativado.connect(_on_modo_remocao_ativado)
		GameData.oxygen_changed.emit(GameData.oxygen_points)
		print("HUD encontrado e conectado!")
	else:
		push_warning("HUD não encontrado! Verifique o nome do nó HUD na cena principal.")
	
	waveTime.start()

	await get_tree().create_timer(30.0).timeout
	iniciar_wave(wave_atual)

func _load_paths_from_gamedata():
	print("MAPA_1: Sinal 'selection_finalized' recebido!") # DEBUG
	if GameData and not GameData.selected_characters_paths.is_empty():
		plantas_paths = GameData.selected_characters_paths
		print("MAPA_1: Caminhos selecionados carregados do GameData: ", plantas_paths) # DEBUG
	else:
		# Mantém os padrões se o GameData estiver vazio por algum motivo
		push_warning("MAPA_1: GameData.selected_characters_paths está vazio ao receber o sinal! Mantendo padrões.")

func iniciar_wave(num: int):
	if num > total_waves:
		vitoria()
		return
	var config = waves_config[num - 1]
	spawn_ativo = true
	spawned_this_wave = 0
	spawnTime.wait_time = config["intervalo"]
	spawnTime.start()
	print("Wave %d iniciada com inimigos %s" % [num, str(config["tipos"])])

func finalizar_wave():
	spawn_ativo = false
	spawnTime.stop()
	print("Wave %d finalizada!" % wave_atual)
	
	# Verifica se ainda há waves restantes
	if wave_atual < total_waves:
		# Se sim, inicia o timer para a próxima wave
		waveTime.start()
	# Se esta FOI a última wave (e sabemos que inimigos_vivos está vazio)
	elif wave_atual == total_waves:
		# Chama a vitória, pois o jogo acabou!
		vitoria()

func _on_modo_remocao_ativado() -> void:
	is_removing = !is_removing
	planta_selecionada_id = -1
	print("Modo Remoção: ", "ON" if is_removing else "OFF", " -> Sinal RECEBIDO COM SUCESSO!")

func _on_planta_selecionada(planta_id: int) -> void:
	planta_selecionada_id = planta_id
	is_removing = false
	print("Slot de planta selecionado no mapa:", planta_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		var mouse_pos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = tilemap_layer.local_to_map(mouse_pos)
		var world_pos: Vector2 = tilemap_layer.map_to_local(cell)

		if is_removing:
			handle_plant_removal(cell)
			return

		if planta_selecionada_id == -1:
			return 

		if cell.x < 2 or cell.y < 0 or cell.x > 16 or cell.y > 5:
			print("Fora do mapa")
			return

		if is_cell_occupied(cell):
			print("CÉLULA OCUPADA!")
			return

		var path = plantas_paths.get(planta_selecionada_id, "")
		if path == "":
			push_warning("Caminho da planta não encontrado para o slot: " + str(planta_selecionada_id))
			planta_selecionada_id = -1
			return

		var planta_scene: PackedScene = load(path)
		if not planta_scene:
			push_warning("Cena da planta não encontrada: " + str(path))
			planta_selecionada_id = -1
			return

		var custo_planta: int = 0
		var temp_planta = planta_scene.instantiate()

		if temp_planta:
			# --- CORREÇÃO DO ERRO AQUI ---
			# Substituí 'temp_planta.has("custo")' por '"custo" in temp_planta'
			if "custo" in temp_planta:
			# --- FIM DA CORREÇÃO ---
				custo_planta = temp_planta.custo
			temp_planta.queue_free()

		if custo_planta == 0:
			push_warning("ERRO: Custo da planta é 0 ou não foi lido!")
			return

		if not GameData.spend_oxygen(custo_planta):
			print("Oxigênio insuficiente! Saldo: ", GameData.oxygen_points, " | Custo:", custo_planta)
			return

		var planta = planta_scene.instantiate()
		add_child(planta)
		planta.position = world_pos
		
		#Conecta o sinal 'morreu' do peixe à função de remoção
		if planta.has_signal("morreu"):
			# O .bind(planta) é crucial para passar a referência do peixe
			planta.morreu.connect(remove_plant_from_tracking.bind(planta))
		else:
			push_warning("A cena " + path + " não tem o sinal 'morreu'!")

		var planta_data = {
			'pos': world_pos,
			'node': planta
		}

		if "algas.tscn" in path:
			plantas.append(planta_data)
		elif "cavalo.tscn" in path:
			cavalos.append(planta_data)
		elif "ourico.tscn" in path:
			ouricos.append(planta_data)
		elif "tartaruga.tscn" in path:
			tartarugas.append(planta_data)
		elif "brigao.tscn" in path:
			brigoes.append(planta_data)
		elif "baiacu.tscn" in path:
			baiacus.append(planta_data)
		elif "pxboi.tscn" in path:
			pxBois.append(planta_data)
		elif "lagosta-boxeadora.tscn" in path:
			lagostas.append(planta_data)
		elif "pinguim.tscn" in path:
			pinguins.append(planta_data)
		else:
			plantas.append(planta_data) 
			push_warning("Tipo de planta não rastreado: " + path)

		planta_selecionada_id = -1

func apply_poison_dps(target: Node2D, damage: int, duration: float, interval: float) -> void:
	var total_ticks: int = ceil(duration / interval)
	var cor_roxa = Color(0.8, 0.2, 1.0, 1.0) 

	if target.has_method("set_modulate_color"):
		target.cor_base = cor_roxa 
		target.modulate = cor_roxa

	for i in range(total_ticks):
		if not is_instance_valid(target) or not target.has_method("receber_dano"):
			break
		target.receber_dano(damage)
		await get_tree().create_timer(interval).timeout

	if is_instance_valid(target) and target.has_method("set_modulate_color"):
		target.cor_base = Color.WHITE
		target.modulate = Color.WHITE

func handle_plant_removal(target_cell: Vector2i) -> void:
	var all_units = plantas + cavalos + baiacus + ouricos + brigoes + tartarugas + pxBois
	var removed_successfully = false

	for unit_data in all_units:
		var unit_world_pos = unit_data['pos']
		var unit_cell = tilemap_layer.local_to_map(unit_world_pos)

		if unit_cell == target_cell:
			var plant_node = unit_data['node']
			if is_instance_valid(plant_node):
				plant_node.morrer()
				print("Planta removida manualmente na célula: ", target_cell)
				removed_successfully = true
			break
	is_removing = false
	if not removed_successfully:
		print("Nenhuma planta encontrada para remover.")

func remove_plant_from_tracking(plant_node: Node2D) -> void:
	var all_arrays = [plantas, cavalos, baiacus, ouricos, brigoes, tartarugas]

	for array in all_arrays:
		var index_to_remove = -1
		for i in range(array.size()):
			if array[i].get('node') == plant_node:
				index_to_remove = i
				break
		if index_to_remove != -1:
			array.remove_at(index_to_remove)
			print("Célula liberada com sucesso!")
			return

func is_cell_occupied(target_cell: Vector2i) -> bool:
	var all_units = plantas + cavalos + baiacus + ouricos + brigoes + tartarugas
	for unit_data in all_units:
		var unit_world_pos = unit_data['pos']
		var unit_cell = tilemap_layer.local_to_map(unit_world_pos)
		if unit_cell == target_cell:
			return true
	return false

func _on_wave_time_timeout() -> void:
	wave_atual += 1
	iniciar_wave(wave_atual)
	unlocked_wave()

func unlocked_wave():
	waveAtiva = true

func _on_spawn_time_timeout() -> void:
	if not spawn_ativo:
		return
	var config = waves_config[wave_atual - 1]
	var tipos = config["tipos"]

	if spawned_this_wave >= config["quantidade"]:
		spawnTime.stop()
		spawn_ativo = false
		if inimigos_vivos.is_empty():
			finalizar_wave()
		return

	var tipo = tipos[randi() % tipos.size()]
	var inimigo_scene = inimigos_scene[tipo]
	var inimigo = inimigo_scene.instantiate()

	var inmgLinha = randi() % inmgPos_linha
	var inmgCol = (randi() % inmgPos_col) + 13
	var celulaInmg = Vector2i(inmgCol, inmgLinha)
	var inmgPos_mundo = tilemap_layer.map_to_local(celulaInmg)

	inimigo.position = inmgPos_mundo
	inimigo.position.y -= 8
	inimigo.z_index = inmgLinha
	add_child(inimigo)
	inimigo.add_to_group("inimigos")

	inimigos_vivos.append(inimigo)
	spawned_this_wave += 1

	if inimigo.has_signal("morreu"):
		inimigo.connect("morreu", Callable(self, "_on_inimigo_morreu").bind(inimigo))

func _on_inimigo_morreu(inimigo):
	if inimigos_vivos.has(inimigo):
		inimigos_vivos.erase(inimigo)
	var config = waves_config[wave_atual - 1]
	if spawned_this_wave >= config["quantidade"] and inimigos_vivos.is_empty():
		finalizar_wave()

func _on_game_time_timeout():
	vitoria()

func vitoria():
	if not jogo_ativo:
		return
	jogo_ativo = false
	get_tree().change_scene_to_file("res://scenes/tela_vitoria.tscn")

func derrota():
	if not jogo_ativo:
		return
	jogo_ativo = false
	get_tree().change_scene_to_file("res://scenes/tela_endgame.tscn")
