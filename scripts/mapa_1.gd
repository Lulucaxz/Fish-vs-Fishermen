extends Node2D

@export var waveLimit: int = 10

@onready var tilemap_layer: TileMapLayer = $TileMap/TileMapLayer
@onready var hud = get_tree().get_root().find_child("HUD", true, false)

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

# contador de quantos já foram spawnados na wave atual
var spawned_this_wave: int = 0

var jogo_ativo: bool = true
var planta_selecionada_id: int = -1
var is_removing: bool = false # Variável para rastrear o estado de remoção

# Dicionário com os caminhos das plantas
var plantas_paths := {
	1: "res://scenes/algas.tscn",
	2: "res://scenes/cavalo.tscn",
	3: "res://scenes/ourico.tscn",
	4: "res://scenes/tartaruga.tscn",
	5: "res://scenes/brigao.tscn",
	6: "res://scenes/baiacu.tscn"
}

var plantas: Array = []
var cavalos: Array = []
var baiacus: Array = []
var ouricos: Array = []
var brigoes: Array = []
var tartarugas: Array = []

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
	# Tenta localizar o HUD em qualquer lugar da árvore de cena
	if hud:
		hud.planta_selecionada.connect(_on_planta_selecionada)
		# CONEXÃO DO MODO REMOÇÃO: Garantida pelo nome correto do sinal
		if hud.has_signal("modo_remocao_ativado"):
			hud.modo_remocao_ativado.connect(_on_modo_remocao_ativado)

		# Inicializa o display de O₂ na HUD com o saldo atual
		GameData.oxygen_changed.emit(GameData.oxygen_points)
		print("HUD encontrado e conectado!")
	else:
		push_warning("HUD não encontrado! Verifique o nome do nó HUD na cena principal.")
	
	waveTime.start()

	await get_tree().create_timer(30.0).timeout
	iniciar_wave(wave_atual)

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

	if wave_atual < total_waves:
		waveTime.start()  # tempo de transição pra próxima wave
	elif wave_atual < total_waves and inimigos_vivos.is_empty():
		vitoria()

# NOVO MÉTODO: Alterna para o modo de remoção
func _on_modo_remocao_ativado() -> void:
	is_removing = !is_removing
	planta_selecionada_id = -1
	print("Modo Remoção: ", "ON" if is_removing else "OFF", " -> Sinal RECEBIDO COM SUCESSO!")

func _on_planta_selecionada(planta_id: int) -> void:
	planta_selecionada_id = planta_id
	is_removing = false
	print("Planta selecionada no mapa:", planta_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		var mouse_pos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = tilemap_layer.local_to_map(mouse_pos)
		var world_pos: Vector2 = tilemap_layer.map_to_local(cell)

		# 1. TRATAMENTO DO MODO REMOÇÃO (PRIORIDADE)
		if is_removing:
			handle_plant_removal(cell)
			return

		if planta_selecionada_id == -1:
			return

		# 2. VERIFICAÇÃO DE LIMITES
		if cell.x < 2 or cell.y < 0 or cell.x > 16 or cell.y > 5:
			print("Fora do mapa")
			return

		# 3. BLOQUEIO DE CÉLULA OCUPADA
		if is_cell_occupied(cell):
			print("CÉLULA OCUPADA!")
			return

		# 4. Carrega o caminho da planta e a cena
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

		# 5. OBTÉM O CUSTO POR INSTANCIAÇÃO TEMPORÁRIA
		var custo_planta: int = 0
		var temp_planta = planta_scene.instantiate()

		if temp_planta:
			custo_planta = temp_planta.custo
			temp_planta.queue_free()

		if custo_planta == 0:
			push_warning("ERRO: Custo da planta é 0 ou não foi lido!")
			return

		# 6. VERIFICA E GASTA OXIGÊNIO (PAGAMENTO)
		if not GameData.spend_oxygen(custo_planta):
			print("Oxigênio insuficiente! Saldo: ", GameData.oxygen_points, " | Custo:", custo_planta)
			return

		# 7. INSTANCIAÇÃO FINAL (Pagamento bem-sucedido)
		var planta = planta_scene.instantiate()

		add_child(planta)
		planta.position = world_pos

		# 8. Adiciona aos arrays de rastreamento
		var planta_data = {
			'pos': world_pos,
			'node': planta
		}

		if planta_selecionada_id == 1: # ALGA
			plantas.append(planta_data)
		elif planta_selecionada_id == 2:
			cavalos.append(planta_data)
		elif planta_selecionada_id == 3:
			ouricos.append(planta_data)
		elif planta_selecionada_id == 4:
			tartarugas.append(planta_data)
		elif planta_selecionada_id == 5:
			brigoes.append(planta_data)
		elif planta_selecionada_id == 6:
			baiacus.append(planta_data)

		planta_selecionada_id = -1

# --- NOVO MÉTODO CRÍTICO: HOSPEDA A LÓGICA DE DANO POR SEGUNDO ---
func apply_poison_dps(target: Node2D, damage: int, duration: float, interval: float) -> void:
	# Esta função roda no contexto seguro do mapa, garantindo que o veneno persista.
	var total_ticks: int = ceil(duration / interval)
	var cor_roxa = Color(0.8, 0.2, 1.0, 1.0) # Cor Roxo para feedback visual

	# 1. INÍCIO DO VENENO: Aplica a cor roxa (se a função existir no inimigo)
	if target.has_method("set_modulate_color"):
		target.cor_base = cor_roxa # Assumindo que a variável cor_base existe no inimigo
		target.modulate = cor_roxa

	for i in range(total_ticks):
		if not is_instance_valid(target) or not target.has_method("receber_dano"):
			break

		target.receber_dano(damage)
		await get_tree().create_timer(interval).timeout

	# 2. FIM DO VENENO: Retorna a cor base ao normal
	if is_instance_valid(target) and target.has_method("set_modulate_color"):
		target.cor_base = Color.WHITE
		target.modulate = Color.WHITE

# --- LÓGICA DE REMOÇÃO ---
func handle_plant_removal(target_cell: Vector2i) -> void:
	var all_units = plantas + cavalos + baiacus + ouricos + brigoes + tartarugas
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

# MÉTODO PARA LIBERAÇÃO DE CÉLULAS APÓS MORTE (Chamado pela planta)
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

# --- FUNÇÃO DE BLOQUEIO ---
func is_cell_occupied(target_cell: Vector2i) -> bool:
	var all_units = plantas + cavalos + baiacus + ouricos + brigoes + tartarugas

	for unit_data in all_units:
		var unit_world_pos = unit_data['pos']
		var unit_cell = tilemap_layer.local_to_map(unit_world_pos)

		if unit_cell == target_cell:
			return true

	return false

# Conexões de Timer (mantenha os nomes iguais aos sinais que você tem no editor)
func _on_wave_time_timeout() -> void:
	wave_atual += 1
	iniciar_wave(wave_atual)
	unlocked_wave()

func unlocked_wave():
	waveAtiva = true
	# O waveTime já chama iniciar_wave, spawnTime é controlado pela iniciar_wave
	# Se quiser, podemos mostrar UI aqui ("Wave X unlocked")
	# spawnTime.start()  # não necessário porque iniciar_wave já inicia spawnTime

# Ajustado: agora contamos quantos foram spawnados nesta wave
func _on_spawn_time_timeout() -> void:
	if not spawn_ativo:
		return

	var config = waves_config[wave_atual - 1]
	var tipos = config["tipos"]

	# Se já spawnamos a quantidade total desta wave, pare o timer (espera inimigos morrerem)
	if spawned_this_wave >= config["quantidade"]:
		# Já gerou todos os inimigos desta wave; só espera matar os vivos
		spawnTime.stop()
		spawn_ativo = false
		# Se não houver inimigos vivos, finaliza imediatamente
		if inimigos_vivos.is_empty():
			finalizar_wave()
		return

	# Escolhe tipo aleatório entre os tipos permitidos nesta wave
	var tipo = tipos[randi() % tipos.size()]
	var inimigo_scene = inimigos_scene[tipo]
	var inimigo = inimigo_scene.instantiate()

	# Define posição usando a lógica do seu spawn original (map -> local)
	var inmgLinha = randi() % inmgPos_linha
	var inmgCol = (randi() % inmgPos_col) + 13
	var celulaInmg = Vector2i(inmgCol, inmgLinha)
	var inmgPos_mundo = tilemap_layer.map_to_local(celulaInmg)

	# Ajustes finos de posição e z_index como seu spawn()
	inimigo.position = inmgPos_mundo
	inimigo.position.y -= 8
	inimigo.z_index = inmgLinha

	add_child(inimigo)
	inimigo.add_to_group("inimigos")

	# adiciona ao controle de vivos
	inimigos_vivos.append(inimigo)
	spawned_this_wave += 1

	# Conecta sinal de morte — use o sinal correto que seus inimigos emitem ("morreu" por exemplo)
	if inimigo.has_signal("morreu"):
		inimigo.connect("morreu", Callable(self, "_on_inimigo_morreu").bind(inimigo))
	# caso seu inimigo use outro sinal, ajuste para o nome certo aqui.

func _on_inimigo_morreu(inimigo):
	if inimigos_vivos.has(inimigo):
		inimigos_vivos.erase(inimigo)

	# Se já spawnamos todos e não há mais vivos, finaliza a wave
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
