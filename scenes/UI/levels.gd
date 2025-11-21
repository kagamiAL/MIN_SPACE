extends "res://scenes/UI/Dialog.gd"

func open():
	$%DEFAULT.grab_focus()
	show()

func clear_buttons():
	for child in $%Levels.get_children():
		if child != $%DEFAULT:
			child.queue_free()

func load_buttons():
	var dir = DirAccess.open("user://maps/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			print_debug(file_name)
			if file_name.ends_with(".json"):
				var file = FileAccess.open("user://maps/" + file_name, FileAccess.READ)
				var circuit = JSON.parse_string(file.get_as_text())
				var button = button_scene.instantiate()
				button.text = "%s\n%s" % [circuit["name"], circuit["author"]]
				button.circuit = circuit
				$%Levels.add_child(button)
			file_name = dir.get_next()

func _on_reload_pressed():
	clear_buttons()
	load_buttons()


func _on_tree_entered():
	clear_buttons()
	load_buttons()


func _on_add_pressed():
	$FileDialog.show()


func _on_file_dialog_file_selected(path):
	# Copy file
	var dir = DirAccess.open("user://")
	dir.make_dir("maps")
	if OS.has_feature("windows"):
		path = path.replace("\\", "/")
	dir.copy(path, "user://maps/" + path.split("/")[-1])
	# Reload buttons
	clear_buttons()
	load_buttons()
