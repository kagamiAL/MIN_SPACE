extends TileMap

# names are lowercase
# values are stored as layer, id, atlas_coords
const ENTITY_CONVERSION_KEY = {
	"block": [0, 1, Vector2i(0, 0)],
	"slope": [0, 1, Vector2i(1, 1)],
	"goal": [3, 1, Vector2i(2, 0)],
	"trampoline": [1, 1, Vector2i(0, 1)],
	"speed": [0, 2, Vector2i(0, 0), 2],
	"spike": [2, 1, Vector2i(1, 0)],
	"spikeshooter": [0, 2, Vector2i(0, 0), 1]
}

# Rotation <-> alternative tile conversion
const ROTATION_KEY = {
	270: TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	180: TileSetAtlasSource.TRANSFORM_FLIP_V | TileSetAtlasSource.TRANSFORM_FLIP_H,
	90: TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_TRANSPOSE,
	0: 0
}

var _tile_rotation_queue = []

# Exports to a JSON (not string)
func export_json():
	var exported = []
	for layer in range(get_layers_count()):
		for tile_pos in get_used_cells(layer):
			var type = ENTITY_CONVERSION_KEY.find_key([
				layer,
				get_cell_source_id(layer, tile_pos),
				get_cell_atlas_coords(layer, tile_pos)
			])
			if type:
				exported.append({
					"type": type,
					"position": [tile_pos.x, tile_pos.y],
					"rotation": ROTATION_KEY.find_key(get_cell_alternative_tile(layer, tile_pos))
				})
	# Loop for EACH kind of scene
	for speed in get_used_cells_by_id(ENTITY_CONVERSION_KEY["speed"][0], ENTITY_CONVERSION_KEY["speed"][1], ENTITY_CONVERSION_KEY["speed"][2], ENTITY_CONVERSION_KEY["speed"][3]):
		exported.append({
			"type": "speed",
			"position": [speed.x, speed.y],
			"rotation": int(rad_to_deg(get_tile_scene_rotation(speed)))
		})
	for spikeshooter in get_used_cells_by_id(ENTITY_CONVERSION_KEY["spikeshooter"][0], ENTITY_CONVERSION_KEY["spikeshooter"][1], ENTITY_CONVERSION_KEY["spikeshooter"][2], ENTITY_CONVERSION_KEY["spikeshooter"][3]):
		exported.append({
			"type": "spikeshooter",
			"position": [spikeshooter.x, spikeshooter.y],
			"rotation": int(rad_to_deg(get_tile_scene_rotation(spikeshooter)))
		})
	return exported

# Gets tile scenes at positions
func get_tile_scenes(tile_position: Vector2i):
	var scenes = []
	for child in get_children():
		var child_position = local_to_map(child.position)
		if int(child_position.x) == tile_position.x and int(child_position.y) == tile_position.y:
			scenes.append(child)
	return scenes

func set_tile_scene_rotation(tile_position: Vector2i, tile_rotation: float):
	var tile_scenes = get_tile_scenes(tile_position)
	for tile_scene in tile_scenes:
		tile_scene.rotation = tile_rotation

# Rotation in rad
func get_tile_scene_rotation(tile_position: Vector2i) -> float:
	var tile_scenes = get_tile_scenes(tile_position)
	return get_tile_scenes(tile_position)[0].rotation if tile_scenes else 0

# Loads from a JSON (parsed)
func load_json(input):
	for tile in input:
		if "type" in tile.keys() and tile["type"] in ENTITY_CONVERSION_KEY.keys():
			var entity = ENTITY_CONVERSION_KEY[tile["type"]]
			var alternate_tile = ROTATION_KEY[int(tile["rotation"])] if tile["rotation"] and int(tile["rotation"]) in ROTATION_KEY else 0
			set_cell(
				entity[0],
				Vector2(tile["position"][0], tile["position"][1]),
				entity[1],
				entity[2],
				entity[3] if len(entity) > 3 else alternate_tile
			)
			if is_inside_tree():
				call_deferred("set_tile_scene_rotation",
					Vector2i(tile["position"][0], tile["position"][1]),
					deg_to_rad(int(tile["rotation"]))
				)
			else:
				_tile_rotation_queue.append([
					Vector2i(tile["position"][0], tile["position"][1]),
					deg_to_rad(int(tile["rotation"]))
				])

func erase_at(erase_position: Vector2i):
	for layer in range(get_layers_count()):
		set_cell(layer, erase_position, -1)

func _on_tree_entered():
	if get_tree():
		await get_tree().process_frame
	for tile_rotation in _tile_rotation_queue:
		call_deferred("set_tile_scene_rotation", tile_rotation[0], tile_rotation[1])
