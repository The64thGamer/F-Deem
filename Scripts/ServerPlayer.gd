extends CharacterBody3D
class_name ServerPlayer
var server : TheServer
var id : int
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4
var lastMousePos : Vector2
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var _total_yaw = 0.0
var in_air : bool
var holding_action : bool

const gravity = 15
const jump_power = 10
const eye_level = 6
const reach = 15

func _ready():
	server = get_node("/root/Control/F'Deem") as TheServer
	position = server.playerInfo[id]["position"]
	velocity = server.playerInfo[id]["velocity"]

func _process(delta):
	_update_movement(delta)
	_update_mouselook()
	_check_action()

func _check_action():
	var check = server.secretPlayerInfo[id]["keystrokes"].get("action", false)
	
	if check && !holding_action:
		var space_state = get_world_3d().direct_space_state
		var from = position + Vector3.UP * eye_level
		var direction = Vector3(
			-sin(deg_to_rad(_total_yaw)) * cos(deg_to_rad(_total_pitch)),
			-sin(deg_to_rad(_total_pitch)),
			-cos(deg_to_rad(_total_yaw)) * cos(deg_to_rad(_total_pitch))
		).normalized()
		
		var max_iterations = 5  # Prevent infinite loops
		var iteration = 0
		var result

		while iteration < max_iterations:
			var to = from + (direction * reach)
			var query = PhysicsRayQueryParameters3D.create(from, to)
			result = space_state.intersect_ray(query)
			if result != null:

				if result.has("collider"):
					if result.collider.is_in_group("Brick"):
						Console.output_text("Hit a Brick at: " + str(result.position))
						break
					elif result.collider.is_in_group("Player"):
						Console.output_text("Hit a Player, continuing raycast...")
						from = result.position + (direction.normalized() * 0.1)  # Move forward slightly to avoid re-hitting the same player
					else:
						Console.output_text("Hit something else, stopping." + str(result))
						break
				else:
					break 
			else:
				break

			iteration += 1

	# Do this last
	if check != holding_action:
		holding_action = check

	
func _update_movement(delta):
	var keystrokes = server.secretPlayerInfo[id]["keystrokes"]
	var input_dir = Vector3(
		int(keystrokes.get("right",0)) - int(keystrokes.get("left",0)),
		int(keystrokes.get("down",0)) - int(keystrokes.get("up",0)),
		int(keystrokes.get("backward",0)) - int(keystrokes.get("forward",0))
	)
	var yaw_rad = deg_to_rad(_total_yaw)

	var direction = Vector3(
		cos(yaw_rad) * input_dir.x - sin(yaw_rad) * input_dir.z,
		0,
		sin(yaw_rad) * input_dir.x + cos(yaw_rad) * input_dir.z
	).normalized()

	_velocity += direction * _acceleration * delta
	
	if (is_on_floor() || is_on_ceiling()) && in_air:
		in_air = false
		_velocity.y = 0
	
	if not is_on_floor():
		in_air = true
		_velocity.y -= gravity * delta
		
	if is_on_floor() && keystrokes.get("jump",false):
		_velocity.y = jump_power
		

	_velocity.x = clamp(_velocity.x, -_vel_multiplier, _vel_multiplier) * 0.9
	_velocity.z = clamp(_velocity.z, -_vel_multiplier, _vel_multiplier) * 0.9
	velocity = _velocity
	
	move_and_slide()

	server.setPlayerInfo(id, "velocity", velocity)
	server.setPlayerInfo(id, "position", position)

	

func _update_mouselook():
	var check = server.secretPlayerInfo[id]["mouse_position"]
	if lastMousePos != check:
		_mouse_position = check
		lastMousePos = check

	# Accumulate rotation in absolute terms
	_mouse_position.y = clamp(_mouse_position.y, -90 - _total_pitch, 90 - _total_pitch)
	_total_pitch += _mouse_position.y
	_total_yaw += _mouse_position.x  # Accumulate yaw movement

	# Store as absolute rotation values
	server.setPlayerInfo(id, "look_rot", Vector2(_total_yaw, _total_pitch))

	# Reset the mouse position vector
	_mouse_position = Vector2(0, 0)
