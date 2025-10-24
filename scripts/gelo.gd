# /scripts/gelo.gd
extends Area2D

# --- Configurações ---
@export var velocidade: int = 450
@export var dano: int = 5
@export var slow_factor: float = 0.5 # Fator de lentidão (0.5 = 50% da velocidade normal)
@export var slow_duration: float = 2.0 # Duração da lentidão em segundos

# --- Funções Nativas ---
func _process(delta: float):
	# Move para a direita
	position.x += velocidade * delta
	
	# Remove se sair da tela
	if position.x > get_viewport_rect().size.x + 50: # Usa o tamanho da viewport + margem
		queue_free()

# --- Detecção de Colisão (Sinal) ---
# Conecte este método ao sinal 'body_entered' do nó Gelo (Area2D).
func _on_body_entered(body: Node2D):
	# Verifica se colidiu com um inimigo que pode receber dano
	if body.has_method("receber_dano"):
		# Aplica o dano
		body.receber_dano(dano)
		
		if body.has_method("aplicar_lentidao"):
			body.aplicar_lentidao(slow_factor, slow_duration)
		
		queue_free()
