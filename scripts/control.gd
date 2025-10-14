extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/HBoxContainer/MainButtons
@onready var options: Panel = $Options
@onready var jogar_btn: Button = $MarginContainer/HBoxContainer/MainButtons/jogar_btn
@onready var config_btn: Button = $MarginContainer/HBoxContainer/MainButtons/config_btn
@onready var credit_btn: Button = $MarginContainer/HBoxContainer/MainButtons/credit_btn
@onready var sair_btn: Button = $MarginContainer/HBoxContainer/MainButtons/sair_btn

func _process(delta):
	pass

func _ready():
	jogar_btn.visible = true
	config_btn.visible = true
	credit_btn.visible = true
	sair_btn.visible = true
	options.visible = false

func _on_credit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits-video.tscn")


func _on_sair_btn_pressed() -> void:
	get_tree().quit()


func _on_config_btn_pressed() -> void:
	jogar_btn.visible = false
	config_btn.visible = false
	credit_btn.visible = false
	sair_btn.visible = false
	options.visible = true


func _on_sair_config_pressed() -> void:
	_ready()


func _on_jogar_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
