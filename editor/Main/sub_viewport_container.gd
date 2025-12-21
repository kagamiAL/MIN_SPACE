extends Control

func resize() -> void:
	var oversampling = get_viewport().get_oversampling()
	$Inner/SubViewport.get_viewport().oversampling_override = oversampling
	$Inner.scale = Vector2.ONE * 1/oversampling
	$Inner/SubViewport.size = size * oversampling
	$Inner/SubViewport.size_2d_override = size
	$Inner.draw_texture($Inner/SubViewport.get_texture(), Vector2.ZERO)

func _ready() -> void:
	resize()

func _process(_delta) -> void:
	var oversampling = get_viewport().get_oversampling()
	for child in $Inner.get_children():
		if "scale" in child:
			pass#child.scale = Vector2.ONE * 1/oversampling

func _on_inner_draw() -> void:
	resize()

func _on_visibility_changed() -> void:
	resize()

func _unhandled_key_input(event: InputEvent) -> void:
	$Inner/SubViewport.push_input(event)

func _gui_input(event: InputEvent) -> void:
	event.position *= get_viewport().get_oversampling()
	$Inner/SubViewport.push_input(event, false)
