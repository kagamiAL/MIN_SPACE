extends RigidBody2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.kill()
	queue_free()


func _on_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index):
	queue_free()
