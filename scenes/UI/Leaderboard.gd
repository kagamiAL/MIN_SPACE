extends "res://scenes/UI/Dialog.gd"

@onready var leader_board_data = get_node("/root/LeaderboardData")
@onready var scores = $%Content
@onready var score_template = load("res://scenes/UI/score_template.tscn")

func _on_button_button_down():
	self.visible = false

func _clear_all(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()

func _update_leaderboard():
	_clear_all(scores)
	for data in leader_board_data.get_leaderboard():
		print(data)
		var score = score_template.instantiate()
		score.text = ("- %s: %.2f") % [data[1], data[0]]
		scores.add_child(score)
