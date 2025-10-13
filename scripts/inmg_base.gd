extends CharacterBody2D

@export var vida: int = 200
@export var dano: int = 25

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var speed: int = 8
var inmgBase_pos = Vector2i()

var tempoAttack: float = 0.0
var intervalo_ataque: float = 1.0

func _ready():
	if mapa:
		add_to_group("inimigos")
	anim.play('pescador_walk')
	
	
func atacar(alvo):
		anim.play("pescador_attack")
		alvo.tomar_dano(dano)

# TOMAR DANO

func receber_dano(dano_cavalo):
	vida -= dano_cavalo
	if vida <= 0:
		morte()
		
func morte():
	queue_free()

func _process(delta):
	tempoAttack += delta
	inmgBase_pos = mapa.tilemap_layer.local_to_map(position)
	
	var celula_esquerda = Vector2i(inmgBase_pos.x, inmgBase_pos.y)
	var planta_alvo = null

	for c in mapa.cavalos:
		var celula_cavalo = mapa.tilemap_layer.local_to_map(c["pos"])
		if celula_cavalo == celula_esquerda:
			planta_alvo = c['node']
			break

	for p in mapa.plantas:
		var celula_planta = mapa.tilemap_layer.local_to_map(p["pos"])
		if celula_planta == celula_esquerda:
			planta_alvo = p['node']
			break

	if planta_alvo and is_instance_valid(planta_alvo):
		if tempoAttack >= intervalo_ataque:
			atacar(planta_alvo)
			tempoAttack = 0
		else:
			anim.play("pescador_attack")
	else:
		if position.x > 2:
			position.x -= speed * delta
			anim.play("pescador_walk")
		else:
			position.x = position.x
			morte()
