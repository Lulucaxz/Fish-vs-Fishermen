extends Control

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	
func _on_menu_btn_pressed() -> void:
	if GameData:
		GameData.reset_game_state()
	
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
