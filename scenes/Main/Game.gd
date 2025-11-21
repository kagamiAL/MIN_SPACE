extends Node2D

@onready var game_over_scene = load("res://scenes/UI/GameOver.tscn") as PackedScene

var maps: Dictionary = {};
var map_node: Node2D;
var player;

@export var level_index: int;

func reset():
	level_index = 0
	$LevelIndicator.set_label("Level %d" % level_index, level_index, 7)
	load_current_level()
	$Player.show()
	$Player.reset_time()
	$GameWin.hide()

func set_up_maps_from_dir(path: String):
	var regex = RegEx.new()
	regex.compile("\\d+")
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			print_debug(file_name) # human visual on file name found, remove for production
			if file_name.ends_with(".remap"):
				file_name = file_name.replace(".remap", "")
			if not dir.current_is_dir():
				var result = regex.search(file_name)
				if result:
					maps[int(result.get_string())] = load(path + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func load_current_level():
	if map_node:
		map_node.queue_free()
		await map_node.tree_exited
	# Stop player
	$Player.stop()
	# Add map
	map_node = maps[level_index].instantiate()
	map_node.z_index = -1
	add_child(map_node)
	await get_tree().process_frame
	# THEN reset player
	$Player.reset()
	await get_tree().physics_frame

#Returns true if player won game
func next_level() -> bool:
	if (level_index < maps.size() - 1):
		level_index += 1
		return false
	return true

func get_current_level() -> int:
	return level_index

func increment_level():
	level_index += 1

func _on_player_won():
	$AnimationPlayer.play("goal_reached")
	$WinSound.play()
	if next_level():
		$GameWin.set_time($Player.get_time_elapsed())
		$GameWin.set_map_name("MIN SPACE")
		$GameWin.animate_show()
		$Player.hide()
	else:
		$LevelIndicator.set_label("Level %d" % level_index, level_index, 7)
		load_current_level()

func _on_player_died():
	load_current_level()

# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.physics_ticks_per_second = int(DisplayServer.screen_get_refresh_rate()) # Hack to make physics smooth
	print("Physics engine set to %d FPS" % Engine.physics_ticks_per_second)
	set_up_maps_from_dir("res://scenes/Maps")
	load_current_level()
	$SoundTrack.play()


func _on_level_indicator_restart_pressed() -> void:
	reset()
