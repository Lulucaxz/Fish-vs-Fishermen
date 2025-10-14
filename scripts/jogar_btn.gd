extends Button

@onready var hover_image = $HoverImage
var tween: Tween


var vertical_offset = -52

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if hover_image:
		hover_image.visible = false
		hover_image.modulate.a = 0
		hover_image.top_level = true
		hover_image.mouse_filter = Control.MOUSE_FILTER_IGNORE  # IMPORTANTE!

func _on_mouse_entered():
	if disabled or not hover_image:
		return
	
	# Cancela animação anterior imediatamente
	if tween:
		tween.kill()
	
	# Posiciona o hover
	_position_hover_image()
	
	hover_image.visible = true
	
	# Animação rápida
	tween = create_tween()
	tween.tween_property(hover_image, "modulate:a", 1.0, 0.15)

func _on_mouse_exited():
	if disabled or not hover_image:
		return
	
	if tween:
		tween.kill()
	
	# Animação rápida de saída
	tween = create_tween()
	tween.tween_property(hover_image, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): 
		if hover_image and hover_image.modulate.a < 0.1:
			hover_image.visible = false
	)

func _position_hover_image():
	if not hover_image:
		return
	
	var button_global_pos = global_position
	var button_size = size
	
	hover_image.global_position = Vector2(
		button_global_pos.x + (button_size.x - hover_image.size.x) / 2,
		button_global_pos.y + button_size.y + vertical_offset
	)
	
	# DEBUG
	print("Botão: ", name, " | Hover em: ", hover_image.global_position)
