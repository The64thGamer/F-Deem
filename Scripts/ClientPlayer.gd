class_name FreeLookCamera extends Camera3D

# Modifier keys' speed multiplier
const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

@export_range(0.0, 1.0) var sensitivity = 0.25

# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var client : Client

func _ready():
	client = get_node("/root/F'Deem") as Client

func _process(delta):
	_update_mouselook()
	_update_movement(delta)
	if Console.ConsoleRef.visible && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif (not Console.ConsoleRef.visible) && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative

func _update_movement(delta:float):
	if client.checkOnline(false):
		if playerInfo.has(multiplayer.get_unique_id()):
			position = client.playerInfo[multiplayer.get_unique_id()]["position"]

func _update_mouselook():
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
