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

func _ready():
	server = get_node("/root/Control/F'Deem") as TheServer
	position = server.playerInfo[id]["position"]
	velocity = server.playerInfo[id]["velocity"]

func _process(delta):
	_update_movement(delta)
	_update_mouselook()
	
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
	_velocity.y -= 5 * delta  # Gravity

	_velocity.x = clamp(_velocity.x, -_vel_multiplier, _vel_multiplier)
	_velocity.z = clamp(_velocity.z, -_vel_multiplier, _vel_multiplier)

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
