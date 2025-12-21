extends "res://scenes/UI/Dialog.gd"

@onready var leader_board_data = get_node("/root/LeaderboardData")
@onready var score_template = load("res://scenes/UI/score_template.tscn")

func _on_button_button_down():
	self.visible = false

func _clear_all():
	for n in $%TabContainer.get_children():
		$%TabContainer.remove_child(n)
		n.queue_free()

func _update_leaderboard():
	_clear_all()
	for data in leader_board_data.get_leaderboard():
		print(data)
		var score = score_template.instantiate()
		score.set_score(data[1], data[0])
		# Add score to list for its map -- or create new list
		var found = false
		for c in $%TabContainer.get_children():
			if c.name == data[2]:
				c.add_child(score)
				found = true
				break
		if not found:
			var container = VBoxContainer.new()
			container.add_theme_constant_override("separation", $%Content.get_theme_constant("separation"))
			container.add_child(score)
			container.name = data[2]
			$%TabContainer.add_child(container)
