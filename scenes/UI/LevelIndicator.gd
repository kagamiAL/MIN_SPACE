extends Control

@onready var level: Label = $%Level

signal restart_pressed

func set_label(level_name: String, new_level: int, levels: int):
	$%ProgressBar.max_value = levels
	$%ProgressBar.value = new_level
	level.text = level_name

func _on_restart_pressed():
	$CanvasLayer/PanelContainer/HBoxContainer/Restart.release_focus()
	emit_signal("restart_pressed")


func _on_main_pressed():
	get_node("/root/SceneSwitch").goto_scene("res://scenes/Main/Main.tscn")
