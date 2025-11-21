extends Node
var time = Time.get_time_dict_from_system()

var leader_board := []

func _save_leaderboard():
	var leader_board_file = FileAccess.open("user://leaderboard.csv", FileAccess.WRITE)
	for data in leader_board:
		leader_board_file.store_line(str(data[0]) + "," + data[1] + "," + data[2])

func _load_leaderboard():
	if not FileAccess.file_exists("user://leaderboard.csv"):
		return # Error! We don't have a save to load.
	var leader_board_file = FileAccess.open("user://leaderboard.csv", FileAccess.READ)
	while leader_board_file.get_position() < leader_board_file.get_length():
		var line = leader_board_file.get_line()
		var values = line.split(",")
		leader_board.append([float(values[0]), values[1], values[2]])

func _sort_leaderboard():
	leader_board.sort_custom(func(a, b): return a[0] < b[0])

func get_leaderboard():
	_sort_leaderboard()
	return leader_board

func append_leaderboard(map_name: String, score: float, player_name: String):
	leader_board.append([score, player_name, map_name])
	_sort_leaderboard()
	_save_leaderboard()

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_leaderboard()
