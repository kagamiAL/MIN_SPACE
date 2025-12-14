extends Node2D

signal modified

@export var marker_offset : Vector2

var pan_start : Vector2;

var marker_position : Vector2i = Vector2i(0, 0)

# Updates AddMarker
# TODO: find a way to make this not hard-coded
func _on_option_button_item_selected(index):
	match index: # TODO: index -> id
		# Block
		0:
			$AddMarker.region_rect.position = Vector2(0,0)
		# Slope
		1:
			$AddMarker.region_rect.position = Vector2(64,64)
		# Goal
		2:
			$AddMarker.region_rect.position = Vector2(128,0)
		# Trampoline
		3:
			$AddMarker.region_rect.position = Vector2(0,64)
		# Speed
		4:
			$AddMarker.region_rect.position = Vector2(64*3,64)
		# Spike :3
		5:
			$AddMarker.region_rect.position = Vector2(64,0)
		# spike shooter
		6:
			$AddMarker.region_rect.position = Vector2(128,64)

# yeah i'm using degrees instead of radians... i'm a sellout......
func _on_right_90_pressed():
	$AddMarker.rotation_degrees -= 90
	# Wrap around 0 >= r >= 270
	if $AddMarker.rotation_degrees == -90:
		$AddMarker.rotation_degrees = 270


func _on_left_90_pressed():
	$AddMarker.rotation_degrees += 90
	if $AddMarker.rotation_degrees == 360:
		$AddMarker.rotation_degrees = 0

# Clears tilemap and resets camera position/zoom
func reset():
	$Camera2D.position = Vector2(0, 0)
	$Camera2D.zoom = Vector2(1, 1)
	$TileMap.clear()

# Exports to a JSON (not string)
func export_json():
	return $TileMap.export_json()

# Loads from a JSON (parsed)
func load_json(input):
	$TileMap.load_json(input)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_mouse_control_gui_input(event)

func _on_mouse_control_gui_input(event):
	if event is InputEventMouseMotion:
		var mouse_position = $%MouseControl.get_local_mouse_position()
		var global_mouse_position = $AddMarker.get_global_mouse_position()
		# Marker
		marker_position = Vector2i(
			floor(global_mouse_position.x / 64),
			floor(global_mouse_position.y / 64)
		)
		$AddMarker.position = Vector2(marker_position * 64) + marker_offset
		# Panning
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			if pan_start.x != 0 and pan_start.y != 0:
				$Camera2D.position -= (mouse_position - pan_start) * 1/$Camera2D.zoom
			pan_start = mouse_position
	# Resetting panning
	if event is InputEventMouseButton and (pan_start.x != 0 or pan_start.y != 0):
			pan_start.x = 0
			pan_start.y = 0
	# Zooming
	if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$Camera2D.zoom *= 1.25
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$Camera2D.zoom *= 0.75
	# Add
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Get an alternate tile (yes Godot has hard-coded tiles
		# for each rotation) based on the rotation of the marker
		var alt = $TileMap.ROTATION_KEY[int($AddMarker.rotation_degrees)]
		# Sets the tile
		$TileMap.erase_at(marker_position)
		match $%TileOptionButton.get_selected_id():
			# Block
			0:
				$TileMap.set_cell(0, marker_position, 1, Vector2i(0, 0))
			# Slope
			1:
				$TileMap.set_cell(0, marker_position, 1, Vector2i(1, 1), alt)
			# Goal
			2:
				$TileMap.set_cell(3, marker_position, 1, Vector2i(2, 0))
			# Trampoline
			3:
				$TileMap.set_cell(1, marker_position, 1, Vector2i(0, 1), alt)
			# Speed
			4:
				$TileMap.set_cell(0, marker_position, 2, Vector2i(0, 0), 2)
			# Spike :3
			5:
				$TileMap.set_cell(2, marker_position, 1, Vector2i(1, 0), alt)
			# Spike shooter
			6:
				$TileMap.set_cell(0, marker_position, 2, Vector2i(0, 0), 1)
		$TileMap.call_deferred("set_tile_scene_rotation", marker_position, $AddMarker.rotation)
		emit_signal("modified")
	# Erase
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		$TileMap.erase_at(marker_position)
		emit_signal("modified")
