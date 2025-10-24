extends CharacterBody2D

@export var vida: int = 275
@export var dano: int = 25

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var current_speed: float = 0.0      # Velocidade que ele está usando agora
var is_slowed: bool = false            # Flag para saber se está lento
@onready var slow_timer = $SlowTimer

var speed: float = 7.0
var inmgBase_pos = Vector2i()

var tempoAttack: float = 0.0
var intervalo_ataque: float = 1.0

func _ready():
	if mapa:
		add_to_group("inimigos")
	anim.play('pescador_walk')
	current_speed = speed
	
	
func atacar(alvo):
		anim.play("pescador_attack")
		alvo.tomar_dano(dano)

# TOMAR DANO

func receber_dano(dano_cavalo):
	vida -= dano_cavalo
	
	modulate = Color(1.0, 0.266, 0.277, 1.0) 
		 
	await get_tree().create_timer(0.3).timeout 
		
	modulate = Color(1, 1 , 1)
	
	if vida <= 0:
		morte()
		
func morte():
	queue_free()

func _process(delta):
	tempoAttack += delta
	inmgBase_pos = mapa.tilemap_layer.local_to_map(position)
	
	var celula_esquerda = Vector2i(inmgBase_pos.x, inmgBase_pos.y)
	var planta_alvo = null

	for grupo in [mapa.tartarugas, mapa.baiacus, mapa.cavalos, mapa.plantas, mapa.brigoes, mapa.pxBois, mapa.pinguins, mapa.lagostas]:
		for item in grupo:
			var planta_pos = item["pos"]
			if planta_pos.distance_to(position) < 10:  
				planta_alvo = item["node"]
				break
		if planta_alvo:
			break

	if planta_alvo and is_instance_valid(planta_alvo):
		if tempoAttack >= intervalo_ataque:
			atacar(planta_alvo)
			tempoAttack = 0
		else:
			anim.play("pescador_attack")
	else:
		if position.x > 2:
			position.x -= current_speed * delta
			anim.play("pescador_walk")
		else:
			mapa.derrota()
			morte()
			
			
func aplicar_lentidao(factor: float, duration: float):
	print("--- aplicar_lentidao CHAMADA ---") # DEBUG
	print("  Velocidade ANTES: ", current_speed) # DEBUG
	
	if slow_timer and not slow_timer.is_stopped(): 
		print("  Inimigo já lento, reiniciando timer.")
	elif not is_slowed: 
		print("  Aplicando lentidão pela primeira vez.")
		is_slowed = true
		current_speed = speed * factor # Reduz a velocidade
		modulate = Color(0.5, 0.5, 1.0) # Fica azul
	
	print("  Velocidade DEPOIS: ", current_speed) # DEBUG
	print("  Duração definida: ", duration) # DEBUG
	
	if slow_timer:
		slow_timer.wait_time = duration
		slow_timer.start()
		print("  SlowTimer (re)iniciado.") # DEBUG

# --- NOVA FUNÇÃO: Restaurar Velocidade (Chamada pelo Timer) ---
func restaurar_velocidade():
	print("--- restaurar_velocidade CHAMADA ---") # DEBUG
	if is_slowed: # Só restaura se estava realmente lento
		is_slowed = false
		current_speed = speed # Volta à velocidade 'speed' original
		modulate = Color(1.0, 1.0, 1.0) # Restaura a cor
		print("  Velocidade restaurada para: ", current_speed) # DEBUG
	else:
		print("  Velocidade não restaurada (não estava lento).") # DEBUG

# --- Conexão do Sinal do SlowTimer ---
# Conecte este método ao sinal 'timeout' do nó Timer chamado "SlowTimer".
func _on_SlowTimer_timeout():
	print("--- _on_SlowTimer_timeout CHAMADO ---") # DEBUG
	restaurar_velocidade()
