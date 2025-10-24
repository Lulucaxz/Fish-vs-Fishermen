# /scripts/pinguim.gd
extends CharacterBody2D # Ou Node2D, dependendo da sua base

# --- Propriedades Exportadas ---
@export var custo: int = 150       # Custo para colocar o Pinguim
@export var vida: int = 175       # Vida do Pinguim
@export var gelo_scene: PackedScene # Arraste a cena 'gelo.tscn' aqui no Inspector
@export var attack_interval: float = 2.8 # Tempo (segundos) entre cada disparo

# --- Referências ---
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
@onready var attack_timer = $TimerAtaque # IMPORTANTE: Adicione um nó Timer chamado "AttackTimer" ao Pinguim

func _ready() -> void:
	# Configura e inicia o timer de ataque
	if attack_timer:
		attack_timer.wait_time = attack_interval
		attack_timer.one_shot = false # Para atirar repetidamente
		attack_timer.start()

# --- Função de Ataque ---
func atirar_gelo():
	# 1. Verifica se a cena do gelo está configurada
	if not gelo_scene:
		push_error("ERRO: 'gelo_scene' não está configurada no Inspector do Pinguim!")
		return
		
	# 2. Instancia uma nova cópia do gelo
	var gelo_instancia = gelo_scene.instantiate()
	
	# 3. Define a posição de disparo
	# AJUSTE Vector2(X, Y) para o ponto exato de onde o gelo deve sair do Pinguim.
	# Use o modo "Visível -> Réguas de Colisão" no editor 2D para ajudar a encontrar a coordenada.
	gelo_instancia.global_position = global_position + Vector2(20, -5) # Exemplo: 20 pixels à frente, 5 pixels acima
	
	# 4. Adiciona o gelo à cena principal (geralmente o pai do Pinguim)
	get_parent().add_child(gelo_instancia)
	
	# (Opcional) Tocar animação de ataque, se houver
	# if $AnimatedSprite2D:
	#    $AnimatedSprite2D.play("ataque")

# --- Conexão de Sinal do Timer ---
# Conecte este método ao sinal 'timeout' do nó Timer chamado "AttackTimer".
func _on_timer_ataque_timeout() -> void:
	atirar_gelo()

# --- Funções de Dano e Morte (Adaptadas) ---
func tomar_dano(dano):
	vida -= dano
	
	modulate = Color(1.0, 0.266, 0.277, 1.0) 
	await get_tree().create_timer(0.3).timeout 
	modulate = Color(1, 1 , 1)
	
	if vida <= 0:
		morrer()
			
func morrer():
	if mapa and mapa.has_method("remove_plant_from_tracking"):
		mapa.remove_plant_from_tracking(self) 
	else:
		push_warning("Função 'remove_plant_from_tracking' não encontrada no mapa!")

	queue_free()
