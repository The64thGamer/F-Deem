extends Node
class_name Client

#Server Settings
var address: String = "127.0.0.1"
var port: int = 7888

#Sync Settings
var playerInfo: Dictionary = {}
var loadedMap: Dictionary = {}
var serverVariables: Dictionary = {
	"totalConnections": 0,
	"serverUptime": 0,
	"serverName": "Unnamed Server",
}

#Objects
var peer = null
var disconnectTimer = 5
var justPinging: bool = true

#Const
const colorVars : Dictionary = {
	"Red": "#EF3114",
	"Green": "#71B047",
	"Brown": "#60432E",
}

func _ready():
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	var cam = Camera3D.new()
	var env = WorldEnvironment.new()
	var light = DirectionalLight3D.new()
	cam.set_script(preload("res://Scripts/FreeCam.gd"))
	cam.current = true
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = "#9bedd4"
	light.rotation = Vector3(30,45,0)
	light.shadow_enabled = true
	get_tree().root.call_deferred("add_child",cam)
	get_tree().root.call_deferred("add_child",env)
	get_tree().root.call_deferred("add_child",light)
	
func _process(delta: float) -> void:
	if checkOnline(false):
		serverVariables["serverUptime"] += delta
		if playerInfo.has(multiplayer.get_unique_id()) && playerInfo[multiplayer.get_unique_id()]["permissions"] == "pingas":
			disconnectTimer -= delta
			if disconnectTimer <= 0:
				disconnect_from_server()
		

#region Connecting

func server_disconnected():
	if not peer == null:
		disconnect_from_server()

func disconnect_from_server():
	multiplayer.multiplayer_peer.close()
	peer = null
	disconnectTimer = 5
	if justPinging:
		Console.output_text(str(serverVariables))
	else:
		Console.output_text("Disconnected from server")

func setMode(modeSet: String = "server") -> void:
	if modeSet.to_lower() == "client":
		Console.output_text("Mode set to 'Client'")
		set_script(load("res://Scripts/Client.gd"))
		_ready()
	elif modeSet.to_lower() == "server":
		Console.output_text("Mode set to 'Server'")
		set_script(load("res://Scripts/Server.gd"))
		_ready()
	else:
		Console.output_error("'" + modeSet + "' not a valid Mode")

func join(setaddress: String = address) -> void:
	address = setaddress;
	if peer != null:
		disconnect_from_server()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address,port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	justPinging = false
	
func ping(setaddress: String = address) -> void:
	join()
	justPinging = true
	
func host(setaddress: String) -> void:
	Console.output_error("Currently in Client Mode, use 'setMode server' and then host.")

func connected_to_server():
	if justPinging:
		Console.output_text("Pinging '" + address + "'")
	else:
		Console.output_text("Joined '" + address + "' as '" + str(multiplayer.get_unique_id()) + "'")
		request_membership.rpc()
	
func connection_failed():
	Console.output_text("Failed to connect to server")
	pass
	
func client_reload_map():
	var piece_holder = find_child("Piece Holder")
	if piece_holder == null:
		piece_holder = Node3D.new()
		piece_holder.name = "Piece Holder"  # Make sure the new node has the expected name
		add_child(piece_holder)
	for child in piece_holder.get_children():
		child.queue_free()
	if loadedMap.has("pieces"):
		for piece in loadedMap["pieces"]:
			piece = loadedMap["pieces"][piece]
			if piece.has("id"):
				var prefab_path:String = "res://Prefabs/Pieces/" + piece["id"] + ".tscn"
				var prefab = load(prefab_path)
				if prefab and prefab is PackedScene:
					prefab = prefab.instantiate() as Node3D
					piece_holder.add_child(prefab)  # Add the instance as a child of 'pieces'
					# Optionally set its position or other properties based on 'piece'
					if piece.has("position"):
						var position_parts = piece["position"]
						if position_parts is String:
							position_parts = position_parts.replace('(',"").replace(')',"").split(",")
							if position_parts.size() == 3:
								prefab.global_position = Vector3(
									float(position_parts[0]), 
									float(position_parts[1]), 
									float(position_parts[2])
								)
							else:
								Console.output_text("Invalid position format: " + piece["position"])
						elif position_parts is Vector3:
							prefab.global_transform.origin = position_parts
					if piece.has("rotation"):
						var rotation_parts = piece["rotation"]
						if rotation_parts is String:
							rotation_parts = rotation_parts.replace('(',"").replace(')',"").split(",")
							if rotation_parts.size() == 4:
								prefab.global_transform.basis = Basis(Quaternion(
									float(rotation_parts[0]), 
									float(rotation_parts[1]), 
									float(rotation_parts[2]),
									float(rotation_parts[3])
								))
							else:
								Console.output_text("Invalid rotation format: " + piece["rotation"])
						elif rotation_parts is Quaternion:
							prefab.global_transform.basis = Basis(rotation_parts)
						elif rotation_parts is Vector4:
							prefab.global_transform.basis = Basis(Quaternion(rotation_parts.X,rotation_parts.Y,rotation_parts.Z,rotation_parts.W))
					# Set color
					if piece.has("color"):
						var color_value = piece["color"]
						var final_color:Color = Color.WHITE
						# Check in colorVars dictionary
						if colorVars.has(color_value):
							final_color = Color.html(colorVars[color_value])
							Console.output_text(str(final_color))
						elif color_value.begins_with("#") and color_value.length() == 7:
							final_color = Color(color_value)
						if final_color != null:
							# Apply color to the material of the first MeshInstance3D
							var mesh_instance = prefab.get_child(0)
							if mesh_instance and mesh_instance is MeshInstance3D:
								# Get the existing material or create a new one if it doesn't exist
								var material = mesh_instance.get_surface_override_material(0)
								if not material:
									# If no material exists, create a new one
									material = StandardMaterial3D.new()
								else:
									# If a material exists, create a unique copy for this mesh
									material = material.duplicate()
								
								# Assign the unique material to this mesh
								mesh_instance.set_surface_override_material(0, material)
								
								# Set the desired color
								material.albedo_color = final_color
						else:
							Console.output_text("Invalid color format: " + color_value)
				else:
					Console.output_text(prefab_path + " doesn't exist.")
			
#endregion

#region General Commands
func checkOnline(announce:bool) -> bool:
	if is_instance_valid(peer):
		return true
	elif announce:
		Console.output_error("Not Connected to Server")
	return false

func getaddress() -> void:
	Console.output_text(address)
	
func chat(chatText: String) -> void:
	if checkOnline(true): 
		chat_send.rpc(chatText)
		
func getPlayerName() -> void:
	if checkOnline(true):
		var id = multiplayer.get_unique_id()
		var player_name = "No Player Name Set (" + str(id) + ")"
		if playerInfo.find_key(id) && "name" in playerInfo[id]:
			player_name = playerInfo[id]["name"]
		Console.output_text(player_name)
			
func setPlayerName(newName: String) -> void:
	if checkOnline(true): 
		playername_send.rpc(newName)
		
func place(piece:String,color:String,mapX:int,mapY:int,mapZ:int,mapW:int,posX:float,posY:float,posZ:float,rotX:float,rotY:float,rotZ:float,rotW:float) -> void:
	if checkOnline(true): 
		var pieceDictionary = {
			"id": piece,
			"color": color,
			"position": Vector3(posX,posY,posZ),
			"rotation": Quaternion(rotX,rotY,rotZ,rotW)
			}
		place_piece.rpc(pieceDictionary,mapX,mapY,mapZ,mapW)
		
func setPlayerPermissions(setID:int,permission:String) -> void:
	if checkOnline(true): 
		set_player_permissions.rpc(setID,permission)
		
func getServerVar(key:String) -> void:
	if checkOnline(true): 
		Console.output_text(str(serverVariables[key]))

func getPlayerList() -> void:
	if checkOnline(true): 
		Console.output_text(str(playerInfo))

func getLoadedMaps() -> void:
	if checkOnline(true): 
		Console.output_text(str(loadedMap))
#endregion

#region Server Called RPCS
@rpc("authority","call_local","reliable")
func display_chat(chatText: String, id: int) -> void:
	if playerInfo.has(id):
		var player_name = "Unknown Player Name (" + str(id) + ")"
		if "name" in playerInfo[id]:
			player_name = playerInfo[id]["name"]
		Console.output_text(player_name + ": " + chatText)
	else:
		Console.output_text("Unknown Player (" + str(id) + "): " + chatText)
		
@rpc("authority","call_local","reliable")
func server_send_message(message: String) -> void:
	Console.output_text(message)
	
@rpc("authority","call_local","reliable")
func server_update_server_variable(key, value) -> void:
	serverVariables[key] = value
	pass
	
@rpc("authority","call_local","reliable")
func server_update_player_info(id,key, value) -> void:
	if not playerInfo.has(id):
		playerInfo[id] = {}
	playerInfo[id][key] = value
	pass	
	
@rpc("authority","call_local","reliable")
func server_erase_player_info(id) -> void:
	playerInfo.erase(id)
	pass	
	
@rpc("authority","call_local","reliable")
func server_dismiss_pingas() -> void:
	if justPinging:
		disconnect_from_server()

@rpc("authority","call_local","reliable")
func server_transport_player(value:Dictionary) -> void:
	loadedMap = value
	client_reload_map()
	
@rpc("authority","call_local","reliable")
func update_piece(id:int,piece:Dictionary) -> void:
	if loadedMap.has("pieces"):
		loadedMap["pieces"][id] = piece
		client_reload_map()
		Console.output_text("Piece has been placed: " + str(piece))
#endregion

#region DUMMY SERVER RPCS, REQUIRED SAME BOILERPLATE
#https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls

@rpc("any_peer","reliable","call_local")
func set_player_permissions(setID:int,permission:String) -> void:
	pass

@rpc("any_peer","reliable","call_local")
func chat_send(chatText:String) -> void:
	pass

@rpc("any_peer","reliable","call_local")
func playername_send(playerName:String) -> void:
	pass
			
@rpc("any_peer","reliable","call_local")
func place_piece(piece:Dictionary,mapX:int,mapY:int,mapZ:int,mapW:int) -> void:
	pass
	
@rpc("any_peer","reliable","call_local")
func request_membership() -> void:
	pass

#endregion
