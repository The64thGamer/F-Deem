extends Node
class_name Server

#Server Settings
var address: String = "127.0.0.1"
var port: int = 7888
var localUptime: float = 0

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
	
func _process(delta: float) -> void:
	localUptime += delta
	if localUptime - serverVariables["serverUptime"] > 5:
		setServerVariable("serverUptime",localUptime)

#region Hosting

func setServerVariable(key, value) -> void:
	serverVariables[key] = value
	server_update_server_variable.rpc(key,value)
	
func setPlayerInfo(id,key,value) -> void:
	if not playerInfo.has(id):
		playerInfo[id] = {}
	playerInfo[id][key] = value
	server_update_player_info.rpc(id,key,value)

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

func peer_connected(id):
	setServerVariable("totalConnections", serverVariables["totalConnections"] + 1)
	setPlayerInfo(id,"id",id)
	setPlayerInfo(id,"name","Guest " + str(serverVariables["totalConnections"]))
	setPlayerInfo(id,"permissions","player")
	server_send_message.rpc("Player Joined '" + str(id) + "'")
	for key in serverVariables:
		server_update_server_variable.rpc_id(id,key,serverVariables[key])
	for playerID in playerInfo:
		for value in playerInfo[playerID]:
			server_update_player_info.rpc_id(id,playerID,value,playerInfo[playerID][value])

func peer_disconnected(id):
	playerInfo.erase(id)
	server_erase_player_info.rpc(id)
	server_send_message.rpc("Player Left '" + str(id) + "'")
	
func check_player_permissions(setID:int,permission:String) -> bool:
	if not playerInfo[setID].has("permissions"):
		return false
	if playerInfo[setID]["permissions"] == permission:
		return true
	return false

func checkOnline() -> bool:
	if is_instance_valid(peer):
		return true
	else:
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
func place_piece(piece:Dictionary,mapX:int,mapY:int,mapZ:int,mapW:int) -> void:
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

#region commands
func setPlayerPermissions(setID:int,permission:String) -> void:
	if checkOnline(): 
		server_send_message.rpc("The Server set permissions of '" + playerInfo[setID]["name"] + "' to '" + permission + "'")
		setPlayerInfo(setID,"permissions",permission)

func getaddress() -> void:
	Console.output_text(address)
		
func getServerVar(key:String) -> void:
	if checkOnline(): 
		Console.output_text(str(serverVariables[key]))

func getPlayerList() -> void:
	if checkOnline(): 
		Console.output_text(str(playerInfo))

func getLoadedMaps() -> void:
	if checkOnline(): 
		Console.output_text(str(loadedMaps))
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
#endregion
