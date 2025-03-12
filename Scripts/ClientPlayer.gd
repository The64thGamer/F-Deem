extends CharacterBody3D
class_name ClientPlayer

# Mouse state
var client : TheClient
var id : int
var cam : Camera3D
var lastMousePos : Vector2

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
		
func _update_movement(delta:float):
	if client.checkOnline(false):
		position = client.playerInfo[id]["position"]
		velocity = client.playerInfo[id]["velocity"]
		#move_and_slide()

func _update_mouselook():
	if cam == null:
		return
	var rot = client.playerInfo[id]["look_rot"]
	cam.rotation.y = deg_to_rad(-rot.x)  # Yaw
	cam.rotation.x = deg_to_rad(-rot.y)  # Pitch
