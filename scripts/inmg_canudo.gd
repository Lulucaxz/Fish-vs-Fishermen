extends CharacterBody2D

@export var vida: int = 150
@export var dano: int = 10

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var speed: int = 12
var inmgCanudo_pos = Vector2i()

var tempoAttack: float = 0.0
var intervalo_ataque: float = 1.0

func _ready():
	if mapa:
		add_to_group("inimigos")
	anim.play('canudo_walk')
	
	
func atacar(alvo):
		anim.play("canudo_attack")
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
	if not mapa.waveAtiva:
		return
	
	tempoAttack += delta
	inmgCanudo_pos = mapa.tilemap_layer.local_to_map(position)
	
	var celula_esquerda = Vector2i(inmgCanudo_pos.x, inmgCanudo_pos.y)
	var planta_alvo = null

	for grupo in [mapa.tartarugas, mapa.baiacus, mapa.cavalos, mapa.plantas, mapa.brigoes]:
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
			anim.play("canudo_attack")
	else:
		if position.x > 2:
			position.x -= speed * delta
			anim.play("canudo_walk")
		else:
			mapa.derrota()
			morte()
	
