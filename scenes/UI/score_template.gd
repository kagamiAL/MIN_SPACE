extends PanelContainer

func set_score(name: String, time: float):
	$%Name.text = name
	$%Time.text = "%.2f" % time
