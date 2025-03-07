extends CharacterBody3D
class_name ServerPlayer
var server : TheServer
var id : int
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4

func _ready():
	server = get_node("/root/Control/F'Deem") as TheServer
	position = server.playerInfo[id]["position"]
	velocity = server.playerInfo[id]["velocity"]

func _process(delta):
	_update_movement(delta)
	
func _update_movement(delta):
	var keystrokes = server.secretPlayerInfo[id]["keystrokes"]
	var _direction = Vector3(
		int(keystrokes.get("right",0)) - int(keystrokes.get("left",0)),
		int(keystrokes.get("down",0)) - int(keystrokes.get("up",0)),
		int(keystrokes.get("backward",0)) - int(keystrokes.get("forward",0))
	)

	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Clamps speed to stay within maximum value (_vel_multiplier)
	_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
	#_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
	_velocity.y -= 5 * delta
	_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	velocity = _velocity
	move_and_slide()
	server.setPlayerInfo(id,"velocity",velocity)
	server.setPlayerInfo(id,"position",position)
