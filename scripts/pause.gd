extends CanvasLayer

func ready():
	visible = false
	
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true


func _on_resume_btn_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
