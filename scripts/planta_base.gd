extends CharacterBody2D

# --- PROPRIEDADES DE CONFIGURAÇÃO (APARECEM NO INSPECTOR) ---
@export var custo: int = 25       # Custo em O₂ para colocar a Alga
@export var vida: int = 75       
@export var recarga: float = 5.0  # Tempo entre as gerações de Oxigênio
@export var oxygen_amount: float = 12.5 # Quantidade de O₂ gerada por ciclo

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

var tempo_recarga: float = 0.0

func _ready() -> void:
	anim.play("idle")

func _process(delta):
	if tempo_recarga > 0:
		tempo_recarga -= delta
	else:
		# Quando o tempo zera, chama a ação principal: gerar O₂
		atacar() 

# --- FUNÇÃO DE AÇÃO PRINCIPAL (GERAR OXIGÊNIO) ---
# O Cavalo-Marinho e outras unidades atacantes SOBRESCREVERÃO este método.
func atacar():
	  # 1. Reseta o tempo de recarga
	tempo_recarga = recarga
	
	# 2. LEITURA SEGURA: Obtém o valor de forma segura.
	# Usamos a palavra-chave 'self.' para garantir que a variável do nó seja lida.
	var valor_oxigenio = self.oxygen_amount
	
	# 3. VERIFICAÇÃO DE SEGURANÇA: Garante que o valor não é nulo antes de somar.
	if valor_oxigenio == null:
		push_error("ERRO: oxygen_amount não inicializado. Usando valor padrão (25).")
		valor_oxigenio = 25
	
	# 4. AÇÃO DA ALGA: Adiciona Oxigênio ao sistema global (Autoload GameData)
	GameData.add_oxygen(valor_oxigenio) 
	
	# 5. Animação de produção
	anim.play("atacando")
	await anim.animation_finished
	anim.play("idle")

# --- LÓGICA DE DANO (MANTIDA) ---
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
