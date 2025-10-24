extends CharacterBody2D

@export var custo: int = 200
@export var vida: int = 10
@export var dano_veneno: int = 50    # Dano que o veneno causa por tick
@export var duracao_veneno: float = 3.0 # Duração total do veneno (segundos)
@export var intervalo_veneno: float = 0.5 # Intervalo de dano (tick)

@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
var inimigo_alvo: Node2D = null 

func _ready():
	pass

func tomar_dano(dano):
	vida -= dano
	
	modulate = Color(1.0, 0.266, 0.277, 1.0) 
	await get_tree().create_timer(0.3).timeout 
	modulate = Color(1, 1 , 1)
	
	if vida <= 0:
		morrer()
			
# --- MORTE DO BAIACU (INICIA O VENENO) ---
func morrer():
	if is_instance_valid(mapa) and is_instance_valid(inimigo_alvo):
		# 1. Transfere a responsabilidade do DPS para o mapa (o nó seguro)
		mapa.apply_poison_dps(
			inimigo_alvo,
			self.dano_veneno,
			self.duracao_veneno,
			self.intervalo_veneno
		) 
		
	# 2. Remove o Baiacu do rastreamento do mapa (libera a célula)
	if is_instance_valid(mapa):
		mapa.remove_plant_from_tracking(self) 
		
	queue_free() # Remove o nó da cena (o DPS continua)

func _on_baiacu_colisao_body_entered(body: Node2D) -> void:
	# Armazena o inimigo que está em contato para ser envenenado na morte
	if body.has_method("receber_dano"):
		inimigo_alvo = body
