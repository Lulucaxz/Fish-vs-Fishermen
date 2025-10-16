extends CanvasLayer

@onready var selecao: CanvasLayer = $"."
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)
@onready var hud = get_tree().get_root().find_child("HUD", true, false)

func _ready() -> void:
	get_tree().paused = true
	
	hud.visible = false
	selecao.visible = true
	
func _process(delta: float) -> void:
	pass

func _on_ready_btn_pressed() -> void:
	get_tree().paused = false
	
	hud.visible = true
	selecao.visible = false
