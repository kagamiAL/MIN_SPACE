extends Control

@export var button_scene: PackedScene

func open():
	$%Back.grab_focus()
	show()

func _on_back_pressed():
	self.hide()
