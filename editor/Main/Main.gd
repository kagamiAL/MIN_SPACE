extends Control

var maps = {}

func open():
	$AnimationPlayer.play("show")

# Export to JSON (raw)
func export_json():
	var maps_cleaned = [];
	var map = $%MapTree.get_root().get_first_child()
	while map != null:
		maps_cleaned.append({
			"name": map.get_text(0),
			"data": self.maps[map] if map in self.maps else {}
		})
		map = map.get_next()
	return {
		"name": $%Properties/PropertyName.text,
		"author": $%Properties/PropertyAuthor.text,
		"song": $%Properties/PropertySong.tooltip_text,
		"maps": maps_cleaned
	}

# Load from JSON (parsed)
func load_json(input):
	maps = {}
	# Clears MapTree
	if $%MapTree.get_root() != null:
		var map = $%MapTree.get_root().get_first_child()
		var map_tree_maps = []
		while map != null:
			map_tree_maps.append(map)
			map = map.get_next()
		for map_1 in map_tree_maps:
			map_1.free()
	# Loads maps
	for map in input["maps"]:
		var item = $%MapTree.create_item()
		item.set_text(0, map["name"])
		item.set_editable(0, true)
		self.maps[item] = map["data"]
	# Sets properties
	$%Properties/PropertyName.text = input["name"] if "name" in input else ""
	$%Properties/PropertyAuthor.text = input["author"] if "author" in input else ""
	if "song" in input:
		$%Properties/PropertySong.text = input["song"]
		$%Properties/PropertySong.tooltip_text = input["song"]
	else:
		$%Properties/PropertySong.text = "Load file..."
		$%Properties/PropertySong.tooltip_text = ""
	# Hides subviewport
	$%SubViewportContainer.hide()

# Resets the editor, clearing all fields and maps.
func reset():
	maps = {}
	$%MapTree.clear()
	$%MapTree.create_item()
	$%SubViewportContainer.hide()
	for child in $%Properties.get_children():
		if child is LineEdit:
			child.text = ""
	$%Properties/PropertySong.text = "Load file..."
	$%Properties/PropertySong.tooltip_text = ""
	$%Status.text = "Editor reset."
	$%SaveButton.hide()

# Saves the map into user:///maps
func save() -> bool:
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir("user://maps/")
		if len($%Properties/PropertyName.text.strip_edges()) > 0:
			var file = FileAccess.open("user://maps/" + $%Properties/PropertyName.text + ".json", FileAccess.WRITE)
			file.store_string(JSON.stringify(export_json()))
			$%Status.text = "Saved circuit."
			$%SaveButton.hide()
			return true
		else:
			$AcceptDialog.dialog_text = "Could not save file. No name was found. Open the Properties tab to set one."
			$AcceptDialog.popup_centered()
	else:
		pass # TODO aaaa what happens when there's no user directory oh dear
	return false

func _ready():
	# Creates root map node
	$%MapTree.create_item()

func _on_new_map_pressed():
	var item = $%MapTree.create_item()
	item.set_text(0, "New Map")
	item.set_editable(0, true)


func _on_move_up_pressed():
	var selected = $%MapTree.get_selected()
	if selected:
		selected.move_before(selected.get_prev())

func _on_move_down_pressed():
	var selected = $%MapTree.get_selected()
	if selected:
		selected.move_after(selected.get_next())


func _on_delete_map_pressed():
	var selected = $%MapTree.get_selected()
	if selected:
		$%MapTree.get_root().remove_child(selected)
		$%Status.text = "Map \"%s\" removed." % selected.get_text(0)
	$%SubViewportContainer.hide()

func _on_map_tree_item_selected():
	$%SubViewportContainer.show()
	# Resets editor and tries to load new map
	$%Editor.reset()
	var selected = $%MapTree.get_selected()
	if selected and selected in maps:
		$%Editor.load_json(maps[selected])
		$%Status.text = "Map \"%s\" selected." % selected.get_text(0)


func _on_file_id_pressed(id):
	match id:
		0:
			$AnimationPlayer.play("hide")
		1:
			reset()
		2:
			$LoadDialog.show()
		3:
			save()
		4:
			$SaveDialog.show()

func _on_edit_id_pressed(id):
	# TODO: Save beforehand
	match id:
		0:
			$RunDialog.popup_centered()

# If the editor modified its TileMap, save the map.
func _on_editor_modified():
	$%SaveButton.show()
	var selected = $%MapTree.get_selected()
	if selected:
		maps[selected] = $%Editor.export_json()

func _on_save_dialog_file_selected(path : String):
	if len($%Properties/PropertyName.text.strip_edges()) > 0:
		# Ensure path ends in .zip
		path = path.replace(".zip", "") + ".zip"
		# Create .zip
		var writer = ZIPPacker.new()
		var err = writer.open(path)
		if err != OK:
			return err
		# Write map json
		writer.start_file("maps/" + $%Properties/PropertyName.text + ".json")
		writer.write_file(JSON.stringify(export_json()).to_utf8_buffer())
		writer.close_file()
		# Write music
		if $%Properties/PropertySong.text != "":
			var music_file = FileAccess.get_file_as_bytes("user://music/" + $%Properties/PropertySong.text)
			writer.start_file("music/" + $%Properties/PropertySong.text)
			writer.write_file(music_file)
			writer.close_file()
		# Clean up
		writer.close()
	else:
		$AcceptDialog.dialog_text = "Could not export circuit. No name was found. Open the Properties tab to set one."
		$AcceptDialog.popup_centered()
	$%Status.text = "File saved to %s." % path
	
func _on_load_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	load_json(JSON.parse_string(file.get_as_text()))
	file.close()
	$%Status.text = "Loaded %s." % path.get_file()

# Runs the circuit.
func _on_run_dialog_confirmed():
	# TODO: instantiate with loading the json from the circuit, otherwise don't
	# TODO: possibly: another subviewport that locks input?
	get_node("/root/SceneSwitch").play_circuit(export_json())


func _on_load_music_dialog_file_selected(path):
	$%SaveButton.show()
	var filename = path.get_file()
	# 1. Copy song file to user://music/
	DirAccess.make_dir_absolute("user://music")
	var dir = DirAccess.open(path.get_base_dir())
	if dir:
		dir.copy(path, "user://music/" + filename)
	# 2. Set $%Properties/PropertySong.text
	$%Properties/PropertySong.text = filename
	$%Properties/PropertySong.tooltip_text = filename

func _on_property_song_pressed():
	$LoadMusicDialog.show()


func _on_save_button_pressed() -> void:
	save()

func _on_modification() -> void:
	$%SaveButton.show()


func _on_property_author_text_changed(_new_text: String) -> void:
	$%SaveButton.show()


func _on_property_name_text_changed(_new_text: String) -> void:
	$%SaveButton.show()
