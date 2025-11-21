extends CanvasLayer

var t : float
var n : String

func set_time(time : float):
	$%Time.text = str(time)
	t = time

func set_map_name(name : String):
	n = name

func animate_show():
	$AnimationPlayer.play("show")

func _on_main_menu_pressed():
	get_node("/root/SceneSwitch").goto_scene("res://scenes/Main/Main.tscn")


func _on_restart_pressed() -> void:
	get_parent().reset()


func _on_name_text_changed(new_text: String) -> void:
	var c = $%Name.caret_column
	var r = RegEx.new()
	r.compile("[A-Z]")
	$%Name.text = ""
	for i in r.search_all(new_text.to_upper()):
		$%Name.text += i.get_string()
	$%Name.caret_column = c
	$%SaveButton.disabled = len($%Name.text) == 0


func _on_save_pressed() -> void:
	get_node("/root/LeaderboardData").append_leaderboard(n, t, $%Name.text)
	$%SaveButton.disabled = true
	$%Name.editable = false
