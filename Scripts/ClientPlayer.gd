extends CharacterBody3D
class_name ClientPlayer
# Modifier keys' speed multiplier
const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

@export_range(0.0, 1.0) var sensitivity = 0.25

# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0
var client : TheClient
var id : int
var cam : Camera3D

func _ready():
	client = get_node("/root/Control/F'Deem") as TheClient
	cam = get_node("Camera") as Camera3D
	if id == multiplayer.get_unique_id():
		cam.current = true
	else:
		cam.queue_free()

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
		position = client.playerInfo[id]["position"]
		velocity = client.playerInfo[id]["velocity"]
		#move_and_slide()

func _update_mouselook():
	if cam == null:
		return
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		cam.rotate_y(deg_to_rad(-yaw))
		cam.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
