extends CharacterBody2D

@export var custo: int = 25
@export var vida: int = 100
@export var danoEspinho: int = 10
@export var intervalo_dano: float = 1.0

@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var inimigos_em_contato: Array = []
var dano_ativo: bool = false

func _ready():
	pass


func tomar_dano(dano: int):
	vida -= dano
	
	modulate = Color(1.0, 0.266, 0.277, 1.0)
	
	await get_tree().create_timer(0.3).timeout
	
	modulate = Color(1, 1, 1)
	
	if vida <= 0:
		morrer()


func morrer():
	if mapa and self in mapa.cavalos:
		mapa.cavalos.erase(self)
	queue_free()


func _on_ourico_colisao_body_entered(body: Node2D) -> void:
	if body.has_method("receber_dano"):
		inimigos_em_contato.append(body)
	
	if not dano_ativo:
		dano_ativo = true
		_espinho()


func _on_ourico_colisao_body_exited(body: Node2D) -> void:
	if body in inimigos_em_contato:
		inimigos_em_contato.erase(body)

	if inimigos_em_contato.is_empty():
		dano_ativo = false


func _espinho() -> void:
	while dano_ativo and vida > 0:
		for inimigo in inimigos_em_contato:
			if inimigo and inimigo.has_method("receber_dano"):
				inimigo.receber_dano(danoEspinho)
		
		await get_tree().create_timer(intervalo_dano).timeout
