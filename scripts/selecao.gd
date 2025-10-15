extends CanvasLayer

@onready var selecao: CanvasLayer = $"."
@onready var mapa = get_tree().get_root().find_child("Mapa1", true, false)

func _ready() -> void:
	get_tree().paused = true
	selecao.visible = true
	
func _process(delta: float) -> void:
	pass

func _on_ready_btn_pressed() -> void:
	get_tree().paused = false
	selecao.visible = false
