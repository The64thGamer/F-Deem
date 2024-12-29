extends Node

#Server Settings
@export var address: String = "127.0.0.1"
@export var port: int = 7888

#Player Settings
var playerInfo: Dictionary = {}
var loadedMaps: Dictionary = {}

#World Settings

#Slow Sync
@export var totalConnections: int = 0
@export var serverUptime: float = 0

#Objects
var peer = null
var synchronizer : MultiplayerSynchronizer
var slowSynchronizer : MultiplayerSynchronizer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
func _process(delta: float) -> void:
	if multiplayer.is_server():
		serverUptime += delta
	pass

#region Hosting
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
			#Synchronizer
			create_syncrhonizer()
			
			#Done hosts
			Console.output_text("Hosting '" + address + "'")
			
			#Add host as client
			totalConnections += 1
			var id = multiplayer.get_unique_id()
			playerInfo[id] ={
				"id" : id,
				"name" : "Guest " + str(totalConnections),
				"permissions" : "admin"
			}
			Console.output_text("Player Joined '" + str(id) + "'")
		else:
			Console.output_text("Cannot Host 'set_multiplayer_peer failed'")

func peer_connected(id):
	if multiplayer.is_server():
		totalConnections += 1
		playerInfo[id] ={
			"id" : id,
			"name" : "Guest " + str(totalConnections),
			"permissions" : "player"
		}
	Console.output_text("Player Joined '" + str(id) + "'")
	pass
	
func peer_disconnected(id):
	if multiplayer.is_server():
		playerInfo.erase(id)
	Console.output_text("Player Left '" + str(id) + "'")
	pass
	
func check_player_permissions(setID:int,permission:String) -> bool:
	if not "permissions" in playerInfo[setID]:
		return false
	if playerInfo[setID]["permissions"] == permission:
		return true
	return false

@rpc("any_peer","reliable","call_local")
func set_player_permissions(setID:int,permission:String) -> void:
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if check_player_permissions(id,"admin"):
			server_send_message.rpc("'" + playerInfo[id]["name"] + "' set permissions of '" + playerInfo[setID]["name"] + "' to '" + permission + "'")
			playerInfo[setID]["permissions"] = permission

@rpc("any_peer","reliable","call_local")
func chat_send(chatText:String) -> void:
	if multiplayer.is_server():
		display_chat.rpc(chatText,multiplayer.get_remote_sender_id())

@rpc("any_peer","reliable","call_local")
func playername_send(playerName:String) -> void:
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if "name" in playerInfo[id]:
			server_send_message.rpc("'" + playerInfo[id]["name"] + "' changed name to '" + playerName + "'")
			playerInfo[id]["name"] = playerName
			
@rpc("any_peer","reliable","call_local")
func place_piece(piece:Dictionary,mapX:int,mapY:int,mapZ:int,mapW:int) -> void:
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if check_player_permissions(id,"cheater") || check_player_permissions(id,"admin"):		
			#Strip bad dictionary stuff from piece
			var parsed_piece = {
				"color": piece.get("color", "green"),
				"id": piece.get("id", 0),
				"position": piece.get("position", Vector3.ZERO),
				"rotation": piece.get("rotation", Quaternion.IDENTITY)
			}
			
			#Add
			var mapName = str(mapX) + "," + str(mapY) + "," + str(mapZ) + "," + str(mapW)
			if not mapName in loadedMaps:
				#DO THIS LATER
				#loadmap from savefile
				#if (map) is null
					#create map
				loadedMaps[mapName] ={
					"pieces" : []
				}
			loadedMaps[mapName]["pieces"].append(parsed_piece)
			server_send_message.rpc("'" + playerInfo[id]["name"] + "' placed piece '" + str(parsed_piece["color"]) + str(parsed_piece["id"]) + "' at " + str(parsed_piece["position"]))
#endregion

#region Connecting
func join(setaddress: String = address) -> void:
	address = setaddress;
	Console.output_text("Joining '" + address + "'")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address,port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func connected_to_server():
	var id = multiplayer.get_unique_id()
	if not multiplayer.is_server():
		Console.output_text("You joined the server '" + str(id) + "'")
	create_syncrhonizer()
	pass
	
func connection_failed():
	pass
	
func create_syncrhonizer() -> void:
	synchronizer = MultiplayerSynchronizer.new()
	synchronizer.delta_interval = 0
	synchronizer.replication_interval = 0
	add_child(synchronizer)
	var config = SceneReplicationConfig.new()
	config.add_property(".:loadedMaps")
	config.property_set_replication_mode(".:loadedMaps", SceneReplicationConfig.ReplicationMode.REPLICATION_MODE_ON_CHANGE);
	synchronizer.replication_config = config
	
	slowSynchronizer = MultiplayerSynchronizer.new()
	slowSynchronizer.delta_interval = 1.0
	slowSynchronizer.replication_interval = 1.0
	add_child(slowSynchronizer)
	config = SceneReplicationConfig.new()
	config.add_property(".:serverUptime")
	config.property_set_replication_mode(".:serverUptime", SceneReplicationConfig.ReplicationMode.REPLICATION_MODE_ALWAYS);
	config.add_property(".:totalConnections")
	config.property_set_replication_mode(".:totalConnections", SceneReplicationConfig.ReplicationMode.REPLICATION_MODE_ALWAYS);
	config.add_property(".:playerInfo")
	config.property_set_replication_mode(".:playerInfo", SceneReplicationConfig.ReplicationMode.REPLICATION_MODE_ALWAYS);
	slowSynchronizer.replication_config = config
	
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
#endregion

#region General Commands
func checkOnline() -> bool:
	if is_instance_valid(peer):
		return true
	else:
		Console.output_error("Not Connected to Server")
		return false

func getaddress() -> void:
	Console.output_text(address)
	
func chat(chatText: String) -> void:
	if checkOnline(): 
		chat_send.rpc(chatText)
		
func getPlayerName() -> void:
	if checkOnline():
		var id = multiplayer.get_unique_id()
		var player_name = "No Player Name Set (" + str(id) + ")"
		if "name" in playerInfo[id]:
			player_name = playerInfo[id]["name"]
		Console.output_text(player_name)
			
func setPlayerName(newName: String) -> void:
	if checkOnline(): 
		playername_send.rpc(newName)
		
func place(piece:int,color:String,mapX:int,mapY:int,mapZ:int,mapW:int,posX:float,posY:float,posZ:float,rotX:float,rotY:float,rotZ:float,rotW:float) -> void:
	if checkOnline(): 
		var pieceDictionary = {
			"id": piece,
			"color": color,
			"position": Vector3(posX,posY,posZ),
			"rotation": Quaternion(rotX,rotY,rotZ,rotW)
			}
		place_piece.rpc(pieceDictionary,mapX,mapY,mapZ,mapW)
		
func setPlayerPermissions(setID:int,permission:String) -> void:
	if checkOnline(): 
		set_player_permissions.rpc(setID,permission)
		
func getServerUptime() -> void:
	if checkOnline(): 
		Console.output_text(str(serverUptime))

func getPlayerList() -> void:
	if checkOnline(): 
		Console.output_text(str(playerInfo))

func getLoadedMaps() -> void:
	if checkOnline(): 
		Console.output_text(str(loadedMaps))
#endregion
