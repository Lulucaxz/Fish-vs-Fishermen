extends CharacterBody2D

@export var custo: int = 75
@export var vida: int = 150
@export var danoBrigao: int = 35
@export var intervalo_ataque: float = 1.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var inimigo_em_contato: Node2D = null
var atacando: bool = false


func _ready():
	if mapa:
		anim.play("brigao_idle")


func tomar_dano(dano: int):
	vida -= dano

	modulate = Color(1.0, 0.266, 0.277, 1.0)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1)

	if vida <= 0:
		morrer()


func morrer():
	if mapa and self in mapa.plantas:
		mapa.plantas.erase(self)
	queue_free()


func _on_brigao_colisao_body_entered(body: Node2D) -> void:
	if body.has_method("receber_dano"):
		inimigo_em_contato = body
		if not atacando:
			atacando = true
			_loop_ataque_continuo()


func _on_brigao_colisao_body_exited(body: Node2D) -> void:
	if body == inimigo_em_contato:
		inimigo_em_contato = null
		atacando = false


func _loop_ataque_continuo() -> void:
	while atacando and vida > 0 and inimigo_em_contato:
		if inimigo_em_contato and inimigo_em_contato.has_method("receber_dano"):
			anim.play("brigao_attack")
			
			inimigo_em_contato.receber_dano(danoBrigao)
			
			await get_tree().create_timer(intervalo_ataque).timeout
			
			if anim:
				anim.play("brigao_idle")
		else:
			atacando = false
