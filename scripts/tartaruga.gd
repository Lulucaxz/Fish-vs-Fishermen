extends CharacterBody2D

@export var custo: int = 50    
@export var vida: int = 350    

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

func _ready():
	if mapa:
		anim.play('tartura_idle')

func tomar_dano(dano):
	vida -= dano
	
	modulate = Color(1.0, 0.266, 0.277, 1.0) 
		 
	await get_tree().create_timer(0.3).timeout 
		
	modulate = Color(1, 1 , 1)
	
	if vida <= 0:
		morrer()
			
func morrer():
	if mapa and self in mapa.plantas:
		mapa.plantas.erase(self)
	queue_free()
