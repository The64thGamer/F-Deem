extends Node
class_name Server

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
var synchronizer : MultiplayerSynchronizer
var slowSynchronizer : MultiplayerSynchronizer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	
func _process(delta: float) -> void:
	if multiplayer.is_server():
		serverUptime += delta
	pass

#region Hosting
func setMode(modeSet: String = "client") -> void:
	if modeSet.to_lower() == "client":
		Console.output_text("Mode set to 'Client'")
		set_script(load("res://Scripts/Client.gd"))
	elif modeSet.to_lower() == "server":
		Console.output_text("Mode set to 'Server'")
		set_script(load("res://Scripts/Server.gd"))
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

func join(setaddress: String) -> void:
	Console.output_error("Currently in Server Mode, use 'setMode client' and then join.")

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

#region DUMMY CLIENT RPCS, REQUIRED SAME BOILERPLATE
#https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#remote-procedure-calls

@rpc("authority","call_local","reliable")
func display_chat(chatText: String, id: int) -> void:
	pass
		
@rpc("authority","call_local","reliable")
func server_send_message(message: String) -> void:
	pass
	
#endregion
