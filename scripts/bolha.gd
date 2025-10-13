# /scripts/bolha.gd
extends Area2D

# --- CONFIGURAÇÕES ---
# Velocidade de movimento em pixels por segundo.
@export var velocidade: int = 600
# Dano que esta bolha causa.
@export var dano: int = 30
# --- FUNÇÕES NATIVAS ---

# Chamada a cada frame para mover o projétil
func _process(delta: float):
	
	
	# Move para a direita (eixo X positivo) de forma suave (baseado em delta).
	position.x += velocidade * delta
	
	# Limpeza opcional: Remove a bolha quando sai da área de jogo.
	# Ajuste '1500' para o limite direito da sua tela.
	if position.x > 1500:
		queue_free()

# --- DETECÇÃO DE COLISÃO (SINAL) ---

# Conecte este método ao sinal 'body_entered' do nó Bolha (Area2D).
# 'body' será o nó que colidiu, esperado ser o Inimigo (CharacterBody2D).
func _on_body_entered(body: Node2D):
	# Verificação de segurança: O objeto colidido tem o método 'receber_dano'?
	if body.has_method("receber_dano"):
		# Se sim, aplica o dano no inimigo.
		body.receber_dano(dano)
		
		queue_free()
