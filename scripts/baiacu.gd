extends CharacterBody2D

@export var custo: int = 200
@export var vida: int = 10

@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
var HitKill: int = 99999

func _ready():
	mapa

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

func _on_baiacu_colisao_body_entered(body: Node2D) -> void:
	if body.has_method("receber_dano"):
		# Se sim, aplica o dano no inimigo.
		body.receber_dano(HitKill)
		
		queue_free()
