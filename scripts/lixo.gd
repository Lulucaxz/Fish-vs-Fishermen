# /scripts/lixo.gd
extends CharacterBody2D

# --- PROPRIEDADES DE ESTADO ---
@export var vida_maxima: int = 30
@export var velocidade_movimento: int = 50
var vida_atual: int

# --- FUNÇÕES NATIVAS ---

func _ready():
	# Inicializa a vida
	vida_atual = vida_maxima

func _physics_process(delta: float):
	# Move o inimigo para a esquerda (X negativo)
	velocity = Vector2(-velocidade_movimento, velocity.y)
	move_and_slide()

# --- LÓGICA DE DANO ---

# Função chamada pelo projétil (Bolha)
func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("Lixo recebeu dano. Vida restante: ", vida_atual)
	
	if vida_atual <= 0:
		print("Lixo destruído!")
		# Remove o inimigo da cena (morre)
		queue_free()
