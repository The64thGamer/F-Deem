extends Node
class_name Server

#Server Settings
var address: String = "127.0.0.1"
var port: int = 7888
var localUptime: float = 0
var secretPlayerInfo: Dictionary = {}

#Sync Settings
var playerInfo: Dictionary = {}
var loadedMaps: Dictionary = {}
var serverVariables: Dictionary = {
	"totalConnections": 0,
	"serverUptime": 0,
	"serverName": "F'Deem Server",
}

#Objects
var peer = null

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_server_shutdown()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_server_shutdown()

func _process(delta: float) -> void:
	if checkOnline(false):
		localUptime += delta
		if localUptime - serverVariables["serverUptime"] > 5:
			set_server_variable("serverUptime",localUptime,false)
		for key in playerInfo:
			if playerInfo[key].has("permissions") && playerInfo[key]["permissions"] == "pingas":
				setSecretPlayerInfo(key,"disconnectTimer",secretPlayerInfo[key]["disconnectTimer"] - delta)
				if secretPlayerInfo[key]["disconnectTimer"] <= 0:
					multiplayer.multiplayer_peer.disconnect_peer(key)

#region Hosting

func transport_player(id:int,x:int,y:int,z:int,w:int):
	setSecretPlayerInfo(id,"mapPositionX",x)
	setSecretPlayerInfo(id,"mapPositionY",y)
	setSecretPlayerInfo(id,"mapPositionZ",z)
	setSecretPlayerInfo(id,"mapPositionW",w)
	var mapName = str(x) + "," + str(y) + "," + str(z) + "," + str(w)
	if not mapName in loadedMaps:
		load_map(x,y,z,w)
	server_transport_player.rpc_id(id,loadedMaps[mapName])
			
func load_map(mapX:int,mapY:int,mapZ:int,mapW:int):
	var mapName = str(mapX) + "," + str(mapY) + "," + str(mapZ) + "," + str(mapW)
	# Path to the map file in the corresponding world folder
	var world_folder = "user://My Precious Save Files/" + str(mapW) + "/"
	var map_file_path = world_folder + str(mapX) + "," + str(mapY) + "," + str(mapZ) + ".map"

	if not FileAccess.file_exists(map_file_path):
		Console.output_text("Map file not found: " + map_file_path + ". Creating a new map.")
		create_map(mapX,mapY,mapZ,mapW)
		return

	# Load the map file
	var file = FileAccess.open(map_file_path, FileAccess.READ)
	if file:
		var map_data:Dictionary = JSON.parse_string(file.get_line())
		file.close()
		loadedMaps[mapName] = map_data
		Console.output_text("Map loaded: " + mapName + file.get_path_absolute())
	else:
		Console.output_error("Failed to open map file: " + map_file_path)

func create_map(mapX:int,mapY:int,mapZ:int,mapW:int):
	var mapName = str(mapX) + "," + str(mapY) + "," + str(mapZ) + "," + str(mapW)
	
	# Path to the new map file in the corresponding world folder
	var save_folder = "/My Precious Save Files/"
	var world_folder = "/"+str(mapW) + "/"

	# Access the DirAccess API
	var dir = DirAccess.open("user://")
	if dir == null:
		Console.output_error("Failed to access base user directory.")
		return
	
	# Check and create the save folder if it doesn't exist
	if not dir.dir_exists(save_folder):
		if dir.make_dir_recursive(save_folder) != OK:
			Console.output_error("Failed to create save folder: " + save_folder)
			return
		dir.open(save_folder)
	
	# Check and create the world folder if it doesn't exist
	if not dir.dir_exists(world_folder):
		if dir.make_dir_recursive(world_folder) != OK:
			Console.output_error("Failed to create world folder: " + world_folder)
			return

	var map_file_path = world_folder + str(mapX) + "," + str(mapY) + "," + str(mapZ) + ".map"

	# Initialize the default map structure
	var default_map_data = {
		"pieces": {}
	}

	# Save the new map file
	var file = FileAccess.open(map_file_path, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(default_map_data))
		file.close()
		loadedMaps[mapName] = default_map_data
		Console.output_text("New map created: " + mapName)
	else:
		Console.output_error("Failed to create map file: " + map_file_path)

func save_all_maps() -> void:
	Console.output_text("Saving all maps...")
	for map_name in loadedMaps.keys():
		save_map(map_name)
	Console.output_text("All maps saved.")

func save_map(map_name: String) -> void:
	# Check if the map exists in loadedMaps
	if not loadedMaps.has(map_name):
		Console.output_error("Cannot save. Map '" + map_name + "' is not loaded.")
		return
	
	# Parse the map name to get X, Y, Z, and W values
	var parts = map_name.split(",")
	if parts.size() != 4:
		Console.output_error("Invalid map name format: " + map_name)
		return

	var mapX = int(parts[0])
	var mapY = int(parts[1])
	var mapZ = int(parts[2])
	var mapW = int(parts[3])

	# Construct the file path
	var save_folder = "/My Precious Save Files/"
	var world_folder = "/"+str(mapW) + "/"
	var map_file_path = world_folder + str(mapX) + "," + str(mapY) + "," + str(mapZ) + ".map"
	
	# Access the DirAccess API
	var dir = DirAccess.open("user://")
	if dir == null:
		Console.output_error("Failed to access base user directory.")
		return
	
	# Check and create the save folder if it doesn't exist
	if not dir.dir_exists(save_folder):
		if dir.make_dir_recursive(save_folder) != OK:
			Console.output_error("Failed to create save folder: " + save_folder)
			return
		dir.open(save_folder)
	
	# Check and create the world folder if it doesn't exist
	if not dir.dir_exists(world_folder):
		if dir.make_dir_recursive(world_folder) != OK:
			Console.output_error("Failed to create world folder: " + world_folder)
			return

	# Save the map data to the file
	var file = FileAccess.open(map_file_path, FileAccess.WRITE)
	if file:
		var map_data = loadedMaps[map_name]
		file.store_string(JSON.stringify(map_data))
		file.close()
		Console.output_text("Map saved: " + map_name)
	else:
		Console.output_error("Failed to save map file: " + map_file_path)


func commandSetVar(key:String, value:String) -> void:
	set_server_variable(key,value,true)

func set_server_variable(key, value, broadcast:bool) -> void:
	serverVariables[key] = value
	if broadcast:
		Console.output_text("'"+ str(key) + "' set to '" + str(value) +"'")
	if multiplayer.get_peers().size() > 0:
		server_update_server_variable.rpc(key,value)
	
func setPlayerInfo(id,key,value) -> void:
	if not playerInfo.has(id):
		playerInfo[id] = {}
	playerInfo[id][key] = value
	server_update_player_info.rpc(id,key,value)

func setSecretPlayerInfo(id,key,value) -> void:
	if not secretPlayerInfo.has(id):
		secretPlayerInfo[id] = {}
	secretPlayerInfo[id][key] = value

func setMode(modeSet: String = "client") -> void:
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

func host(setaddress: String = address) -> void:
	address = setaddress;
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port,32)
	if error != OK:
		Console.output_text("Cannot Host '" + error + "'")
	else:
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
		if multiplayer.is_server():
			Console.output_text("Hosting '" + address + "'")
		else:
			Console.output_text("Cannot Host 'set_multiplayer_peer failed'")

func join(setaddress: String) -> void:
	Console.output_error("Currently in Server Mode, use 'setMode client' and then join.")

func ping(setaddress: String) -> void:
	Console.output_error("Currently in Server Mode, use 'setMode client' and then ping.")

func peer_connected(id):
	set_server_variable("totalConnections", serverVariables["totalConnections"] + 1,true)
	if not playerInfo.has(id):
		setPlayerInfo(id,"id",id)
		setPlayerInfo(id,"name","Guest " + str(serverVariables["totalConnections"]))
		setPlayerInfo(id,"permissions","pingas")
		transport_player(id,0,0,0,0)
	setSecretPlayerInfo(id,"disconnectTimer",5)
	Console.output_text("Server is being pinged by '" + str(id) + "'")
	for key in serverVariables:
		server_update_server_variable.rpc_id(id,key,serverVariables[key])
	for playerID in playerInfo:
		for value in playerInfo[playerID]:
			server_update_player_info.rpc_id(id,playerID,value,playerInfo[playerID][value])
			server_dismiss_pingas.rpc_id(id)

func peer_disconnected(id):
	playerInfo.erase(id)
	server_erase_player_info.rpc(id)
	if multiplayer.get_peers().size() > 0:
		server_send_message.rpc("Player Left '" + str(id) + "'")

func _on_server_shutdown() -> void:
	Console.output_text("Server is shutting down...")

	# Save all loaded maps
	save_all_maps()

	# Disconnect peers if the server is active
	if multiplayer.is_server():
		Console.output_text("Disconnecting all peers...")
		if is_instance_valid(peer):
			peer.close()
		else:
			Console.output_text("No active peer to close.")
	
	Console.output_text("Shutdown complete.")


func check_player_permissions(setID:int,permission:String) -> bool:
	if not playerInfo[setID].has("permissions"):
		return false
	if playerInfo[setID]["permissions"] == permission:
		return true
	return false

func checkOnline(announce:bool) -> bool:
	if is_instance_valid(peer):
		return true
	elif announce:
		Console.output_error("Not Connected to Server")
	return false

@rpc("any_peer","reliable","call_local")
func set_player_permissions(setID:int,permission:String) -> void:
	var id = multiplayer.get_remote_sender_id()
	if check_player_permissions(id,"admin"):
		server_send_message.rpc("'" + playerInfo[id]["name"] + "' set permissions of '" + playerInfo[setID]["name"] + "' to '" + permission + "'")
		setPlayerInfo(setID,"permissions",permission)
	else:
		server_send_message.rpc_id(id,"You do not have permissions to change this.")

@rpc("any_peer","reliable","call_local")
func chat_send(chatText:String) -> void:
	display_chat.rpc(chatText,multiplayer.get_remote_sender_id())

@rpc("any_peer","reliable","call_local")
func playername_send(playerName:String) -> void:
	var id = multiplayer.get_remote_sender_id()
	if playerInfo[id].has("name"):
		server_send_message.rpc("'" + playerInfo[id]["name"] + "' changed name to '" + playerName + "'")
		setPlayerInfo(id,"name",playerName)
		
@rpc("any_peer","reliable","call_local")
func request_membership() -> void:
	var id = multiplayer.get_remote_sender_id()
	if check_player_permissions(id,"pingas"):
		setPlayerInfo(id,"permissions","member")
		if playerInfo[id].has("name"):
			server_send_message.rpc("'" + playerInfo[id]["name"] + "' joined the game.")	
			
@rpc("any_peer","reliable","call_local")
func place_piece(piece:Dictionary,mapX:int,mapY:int,mapZ:int,mapW:int) -> void:
	var id = multiplayer.get_remote_sender_id()
	if check_player_permissions(id,"cheater") || check_player_permissions(id,"admin"):		
		#Strip bad dictionary stuff from piece
		var parsed_piece:Dictionary = {
			"color": piece.get("color", "green"),
			"id": piece.get("id", 0),
			"position": piece.get("position", Vector3.ZERO),
			"rotation": piece.get("rotation", Quaternion.IDENTITY)
		}
		
		#Add
		var mapName = str(mapX) + "," + str(mapY) + "," + str(mapZ) + "," + str(mapW)
		if not mapName in loadedMaps:
			return
			
		var rng = RandomNumberGenerator.new()
		rng.seed = Time.get_ticks_msec()
		var random_int = rng.randi_range(-9223372036854775808, 9223372036854775807)
		
		loadedMaps[mapName]["pieces"][str(random_int)] = parsed_piece
		
		#Send Updates to players
		for player in secretPlayerInfo:
			if secretPlayerInfo[player].has("mapPositionX") && secretPlayerInfo[player].has("mapPositionY") && secretPlayerInfo[player].has("mapPositionZ") && secretPlayerInfo[player].has("mapPositionW"):
				if secretPlayerInfo[player]["mapPositionX"] == mapX && secretPlayerInfo[player]["mapPositionY"] == mapY && secretPlayerInfo[player]["mapPositionZ"] == mapZ && secretPlayerInfo[player]["mapPositionW"] == mapW:
					update_piece.rpc_id(random_int, parsed_piece)

		server_send_message.rpc("'" + playerInfo[id]["name"] + "' placed piece '" + str(parsed_piece["color"]) + str(parsed_piece["id"]) + "' at " + str(parsed_piece["position"]))
#endregion

#region commands
func setPlayerPermissions(setID:int,permission:String) -> void:
	if checkOnline(true): 
		server_send_message.rpc("The Server set permissions of '" + playerInfo[setID]["name"] + "' to '" + permission + "'")
		setPlayerInfo(setID,"permissions",permission)

func getaddress() -> void:
	Console.output_text(address)
		
func getServerVar(key:String) -> void:
	if checkOnline(true): 
		Console.output_text(str(serverVariables[key]))

func getPlayerList() -> void:
	if checkOnline(true): 
		Console.output_text(str(playerInfo))
		
func getSecretPlayerInfo() -> void:
	if checkOnline(true): 
		Console.output_text(str(secretPlayerInfo))

func getLoadedMaps() -> void:
	if checkOnline(true): 
		Console.output_text(str(loadedMaps))
		
func stopHost() -> void:
	_on_server_shutdown()
#endregion


#region DUMMY CLIENT RPCS, REQUIRED SAME BOILERPLATE
#https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls

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
	Console.output_text(message) #Display this
	
@rpc("authority","call_local","reliable")
func server_update_server_variable(key, value) -> void:
	pass
	
@rpc("authority","call_local","reliable")
func server_update_player_info(id,key, value) -> void:
	pass	
	
@rpc("authority","call_local","reliable")
func server_erase_player_info(id) -> void:
	pass	

@rpc("authority","call_local","reliable")
func server_dismiss_pingas() -> void:
	pass	
	
@rpc("authority","call_local","reliable")
func server_transport_player(value:Dictionary) -> void:
	pass	
	
@rpc("authority","call_local","reliable")
func update_piece(id:int,piece:Dictionary) -> void:
	pass	
#endregion
