extends PanelContainer

func set_score(player_name: String, time: float):
	$%Name.text = player_name
	$%Time.text = "%.2f" % time
