extends "res://scenes/UI/Dialog.gd"

func open():
	$%DEFAULT.grab_focus()
	$AnimationPlayer.play("show")

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
	# Literally just https://docs.godotengine.org/en/stable/classes/class_zipreader.html
	# since we're just unzipping whatever was selected into the user directory.
	# This is slightly modified to validate a valid map pack (has a maps/ and music/ directory)
	var reader = ZIPReader.new()
	reader.open(path)
	var root_dir = DirAccess.open("user://")
	var files = reader.get_files()
	for file_path in files:
		# Create directories if they don't exist...
		if file_path.ends_with("/"):
			if file_path == "music/" || file_path == "maps/":
				root_dir.make_dir_recursive(file_path)
			continue
		# Create files
		if "music/" in file_path || ("maps/" in file_path && ".json" in file_path.get_file()):
			root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
			var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
			var buffer = reader.read_file(file_path)
			file.store_buffer(buffer)
	# Reload buttons
	clear_buttons()
	load_buttons()
