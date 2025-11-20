extends RigidBody2D

signal died

signal won

const SLOWDOWN = 10

const JUMP_VELOCITY = -600.0

const SKEW_SPEED = 0.1

@export var SPEED = 20

@export var trampoline_bounce_amt = 0

@onready var initial_time = Time.get_ticks_msec()

@export_range(0, 1) var jump_slow_factor : float = 1

# Stores instantaneous collisions with tiles
var _collisions = []

# When normalising the linear velocity to a 0-1 value, this specifies the "maximum" linear velocity
var NORMALISE_VELOCITY_AMT = 1500.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Used to set position of a rigidbody since it is updated on every physics process
var reset_state = false
var moveVector: Vector2


#Used to shoot raycast to prevent clipping in walls
var last_position: Vector2;

# Stores the time since the last time ContactAudio was playing.
var contact_audio_request_timestamp = 0

func _process(delta):
	$%Time.text = "%.2f" % get_time_elapsed()

func get_time_elapsed():
	return ((Time.get_ticks_msec() - initial_time) / 1000.)

func _physics_process(delta):
	#Prevent wall clipping
	detect_wall_clipping()

	# Add the gravity.
	if not is_on_floor():
		linear_velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		$AnimationPlayer.play("jump")
		$JumpAudio.play()
		linear_velocity.y = JUMP_VELOCITY
		linear_velocity.x *= jump_slow_factor

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		linear_velocity.x += direction * SPEED * delta
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0, SLOWDOWN)

	$RayCast2D.position = global_position
	for object in get_colliding_bodies():
		if object is TileMap:
			for collision in _collisions:
				var layer = object.get_layer_for_body_rid(collision)
				handle_tile_collision(layer)

	# Who up rolling they boulder (rolling SFX)
	# TODO hard coded stop hard coding magic numbers idiot
	var normalised_linear_velocity = min(abs(linear_velocity.length()), NORMALISE_VELOCITY_AMT)/NORMALISE_VELOCITY_AMT
	$RollingTheyBoulder.volume_db = normalised_linear_velocity/10
	if is_on_floor() and linear_velocity.x != 0:
		if not $RollingTheyBoulder.playing: $RollingTheyBoulder.play()
	else:
		$RollingTheyBoulder.stop()
		
	# Zooming based on velocity
	$Camera2D.zoom.x = lerp($Camera2D.zoom.x, 1 - normalised_linear_velocity/3, 0.01)
	$Camera2D.zoom.y = $Camera2D.zoom.x

func handle_tile_collision(tilemap_layer):
	match tilemap_layer:
		# Static bodies
		0:
			pass

		# Trampolines
		1:
			linear_velocity.y = -trampoline_bounce_amt
			$JumpAudio.play()

		# Spikes
		2:
			kill()

		# Goals
		3:
			stop()
			emit_signal("won")

func stop():
	set_process(false)
	set_physics_process(false)
	set_deferred("freeze", true)
	$RollingTheyBoulder.stop()

func kill():
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation == "die":
		return
	# Killing is fun!
	# - Thi Dinh
	# Can't _process/move
	_collisions.clear()
	set_process(false)
	set_physics_process(false)
	set_deferred("freeze", true)
	linear_velocity = Vector2()
	# Hide sprite
	#$Sprite.hide()
	$%Time.hide()
	# Play death sound
	$RollingTheyBoulder.stop()
	$DeathAudio.play()
	# All our food keeps BLOWING UP
	$AnimationPlayer.play("die")

func reset():
	# Restart velocity + position
	position = Vector2.ZERO
	# Reset things
	set_process(true)
	set_physics_process(true)
	set_deferred("freeze", false)
	linear_velocity = Vector2()
	# Show sprite
	$Sprite.show()
	$%Time.show()
	$AnimationPlayer.play("RESET")

func is_on_floor():
	return $RayCast2D.is_colliding()

func _integrate_forces(state):
	if reset_state:
		state.transform = Transform2D(0.0, moveVector)
		reset_state = false

func move_body(targetPos: Vector2):
	moveVector = targetPos;
	reset_state = true;

func detect_wall_clipping():
	if last_position:
		#Since RayCast2D Node is a weirdo we will directly calculate a raycast
		var space_state = get_world_2d().direct_space_state
		#Shoot a ray from last position to current
		var query = PhysicsRayQueryParameters2D.create(last_position, self.global_position)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			print("Player collided with ", result.collider.name)
			move_body(last_position)
			return
	last_position = self.global_position

func _on_area_2d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		_collisions.append(body_rid)

func _on_area_2d_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		_collisions.remove_at(_collisions.find(body_rid))

# Makes a sound when it hits a body
func _on_body_entered(body):
	if (not contact_audio_request_timestamp\
	   or (Time.get_ticks_msec() - contact_audio_request_timestamp) > 50)\
		and not $ContactAudio.playing:
		if contact_audio_request_timestamp:
			var difference = Time.get_ticks_msec() - contact_audio_request_timestamp
			# TODO: constant
			var max_difference = 300
			$ContactAudio.volume_db = min(difference, max_difference) / max_difference * 20 - 19
			$ContactAudio.pitch_scale =  1 - (1 - min(difference, max_difference) / max_difference) * 0.2
		$ContactAudio.play()
		contact_audio_request_timestamp = Time.get_ticks_msec()
	return
