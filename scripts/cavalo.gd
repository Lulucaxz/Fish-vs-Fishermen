# /scripts/cavalo.gd
extends Node2D

@export var custo: int = 50    
@export var vida: int = 150        

@export var CenaBolha: PackedScene
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

# --- FUNÇÕES DE ATAQUE ---
func on_ready():
	atirar_bolha()

func atirar_bolha():
	# 1. Verifica se a cena está configurada
	if not CenaBolha:
		print("ERRO: 'CenaBolha' não está configurada no Inspector do Cavalo-Marinho!")
		return
		
	# 2. Instancia uma nova cópia da bolha
	var bolha_instancia = CenaBolha.instantiate()
	
	# 3. Define a posição de disparo
	# Ajuste Vector2(50, 0) para o ponto exato de onde a bolha deve sair (a "boca" do cavalo-marinho).
	bolha_instancia.global_position = global_position + Vector2(5, 0) 
	
	# 4. Adiciona a bolha ao nó pai (Main.tscn, Mapa, etc.) para que ela exista no jogo.
	get_parent().add_child(bolha_instancia)
	
	# Lógica de Animação (Se houver AnimatedSprite2D)
	# $AnimatedSprite2D.play("ataque")

# --- CONEXÃO DE SINAIS ---

# Conecte este método ao sinal 'timeout' do nó TimerAtaque.
func _on_timer_ataque_timeout():
	print("Pssaram 3 segundos! Atirando") # <- Adicione esta linha
	# A cada 'timeout' do Timer, disparamos a bolha.
	atirar_bolha()


func _on_timeratack_timeout() -> void:
	pass # Replace with function body.

func tomar_dano(dano):
		vida -= dano
		if vida <= 0:
			morrer()
			
	
func morrer():
	if mapa and self in mapa.cavalos:
		mapa.cavalos.erase(self)
	queue_free()
