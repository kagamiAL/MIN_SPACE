extends Control

@export var button_scene: PackedScene

func open():
	$AnimationPlayer.play("show")
	$%Back.grab_focus()

func _on_back_pressed():
	$AnimationPlayer.play("hide")
