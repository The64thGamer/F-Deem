extends Node
class_name Client

#Server Settings
var address: String = "127.0.0.1"
var port: int = 7888

#Player Settings
var playerInfo: Dictionary = {}

#World Settings
var loadedMaps: Dictionary = {}

#Slow Sync
var totalConnections: int = 0
var serverUptime: float = 0

#Objects
var peer = null

func _ready():
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

#region Connecting

func setMode(modeSet: String = "server") -> void:
	if modeSet.to_lower() == "client":
		Console.output_text("Mode set to 'Client'")
		set_script(load("res://Scripts/Client.gd"))
	elif modeSet.to_lower() == "server":
		Console.output_text("Mode set to 'Server'")
		set_script(load("res://Scripts/Server.gd"))
	else:
		Console.output_error("'" + modeSet + "' not a valid Mode")

func join(setaddress: String = address) -> void:
	address = setaddress;
	Console.output_text("Joining '" + address + "'")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address,port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
func host(setaddress: String) -> void:
	Console.output_error("Currently in Client Mode, use 'setMode server' and then host.")

func connected_to_server():
	var id = multiplayer.get_unique_id()
	if not multiplayer.is_server():
		Console.output_text("You joined the server '" + str(id) + "'")
	pass
	
func connection_failed():
	Console.output_text("Failed to connect to server")
	pass
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

#endregion
