extends Camera2D

@export_range(0, 1) var move_speed : float

func _physics_process(delta):
	position = position.lerp(get_parent().global_position, move_speed * delta * 100)
