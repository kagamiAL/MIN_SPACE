extends Node2D

@onready var tilemap_scene = load("res://scenes/Tiles/savedtilemap/SavedTileMap.tscn") as PackedScene

@export var level_index: int;

var maps = []
var map_node

var _circuit_json;

# Loads from a parsed circuit (not map) JSON
func load_json(input):
	_circuit_json = input
	for map in input["maps"]:
		var tilemap = tilemap_scene.instantiate()
		tilemap.load_json(map["data"])
		tilemap.name = map["name"]
		maps.append(tilemap)
	if "song" in input and FileAccess.file_exists(input["song"]):
		if input["song"].ends_with(".ogg"):
			var audio_stream = AudioStreamOggVorbis.load_from_file(input["song"])
			audio_stream.loop = true
			$SoundTrack.stream = audio_stream
		if input["song"].ends_with(".mp3"):
			var audio_stream = AudioStreamMP3.new()
			var file = FileAccess.open(input["song"], FileAccess.READ)
			audio_stream.data = file.get_buffer(file.get_length())
			audio_stream.loop = true
			$SoundTrack.stream = audio_stream
		if input["song"].ends_with(".wav"):
			var audio_stream = AudioStreamWAV.new()
			var file = FileAccess.open(input["song"], FileAccess.READ)
			audio_stream.data = file.get_buffer(file.get_length())
			audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			$SoundTrack.stream = audio_stream
		
	load_current_level()
	$SoundTrack.call_deferred("play")

func load_current_level():
	if map_node:
		remove_child(map_node)
	$Player.reset()
	await get_tree().physics_frame
	map_node = maps[level_index]
	map_node.z_index = -1
	add_child(map_node)
	$LevelIndicator.set_label(map_node.name, level_index + 1, len(maps))

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
		$GameWin.show()
		$Player.hide()
	else:
		load_current_level()

func _on_player_died():
	load_current_level()

# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.physics_ticks_per_second = DisplayServer.screen_get_refresh_rate() # Hack to make physics smooth
	print("Physics engine set to %d FPS" % Engine.physics_ticks_per_second)


func _on_level_indicator_restart_pressed():
	get_node("/root/SceneSwitch").play_circuit(_circuit_json)
