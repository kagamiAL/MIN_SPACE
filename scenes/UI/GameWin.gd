extends CanvasLayer

func set_time(time : float):
	$%Time.text = str(time)
	get_node("/root/LeaderboardData").append_leaderboard(time)

func animate_show():
	$AnimationPlayer.play("show")

func _on_main_menu_pressed():
	get_node("/root/SceneSwitch").goto_scene("res://scenes/Main/Main.tscn")


func _on_restart_pressed() -> void:
	get_parent().reset()
