extends CharacterBody2D

@export var custo: int = 25
@export var vida: int = 100
@export var danoEspinho: int = 10
@export var intervalo_dano: float = 1.0


@export var tempo_de_vida: float = 15.0 

@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
# NOVO: Referência ao nó TimerAutodestruicao
@onready var timer_autodestruicao: Timer = $TimerAutodestruicao 

var inimigos_em_contato: Array = []
var dano_ativo: bool = false

func _ready():
	# NOVO: Configura e inicia o timer de autodestruição
	timer_autodestruicao.wait_time = tempo_de_vida
	timer_autodestruicao.one_shot = true
	# Conecta o sinal timeout do Timer à nova função
	timer_autodestruicao.start()
	print("Ouriço plantado! Tempo de vida: ", tempo_de_vida, "s")


func tomar_dano(dano: int):
	vida -= dano
	
	modulate = Color(1.0, 0.266, 0.277, 1.0)
	
	await get_tree().create_timer(0.3).timeout
	
	modulate = Color(1, 1, 1)
	
	if vida <= 0:
		morrer()


func morrer():
	if is_instance_valid(mapa):
		mapa.remove_plant_from_tracking(self) 
		
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
	while dano_ativo:
		for inimigo in inimigos_em_contato:
			if is_instance_valid(inimigo):
				inimigo.receber_dano(danoEspinho)
		
		# Aguarda o intervalo antes de aplicar dano novamente
		await get_tree().create_timer(intervalo_dano).timeout
		
		# Garante que o dano_ativo permaneça verdadeiro se ainda houver inimigos
		if inimigos_em_contato.is_empty():
			dano_ativo = false
			break # Sai do loop while
			
# NOVO: Função chamada pelo Timer
func _on_timer_autodestruicao_timeout():
	morrer()
