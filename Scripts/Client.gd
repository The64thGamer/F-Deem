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

func _ready():
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	
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
	var pieces = find_child("pieces")
	if pieces == null:
		pieces = Node3D.new()
		pieces.name = "pieces"  # Make sure the new node has the expected name
		add_child(pieces)
	for child in pieces.get_children():
		child.queue_free()
	if loadedMap.has("pieces"):
		for piece:Dictionary in loadedMap["pieces"]:
			if piece.has("id"):
				var prefab_path = "res://Prefabs/Pieces/" + piece["id"] + ".tscn"
				var prefab = load(prefab_path)
				if prefab and prefab is PackedScene:
					var instance = prefab.instance()  # Create an instance of the prefab
					pieces.add_child(instance)  # Add the instance as a child of 'pieces'
					# Optionally set its position or other properties based on 'piece'
					if piece.has("position"):
						instance.global_transform.origin = piece["position"]
					if piece.has("rotation"):
						instance.global_transform.basis = Basis(piece["rotation"])
			
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
