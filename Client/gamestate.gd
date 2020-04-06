extends Node

# Default game port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

# Name for my player.
var player_name = "The Warrior"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

var server_id = 0

var servers = {}
var clients = {}

# From server comes
var tasks = []


# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	print("_player_connected " + str(id) + " " + player_name)
	
	rpc_id(id, "register_player", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print("register_player " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")


remote func register_server_id(server_player_name):
	var id = get_tree().get_rpc_sender_id()
	print("server is: " + str(id))
	server_id = id



func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game(tasks):
	# Change scene.
	var world = load("res://world.tscn").instance()
	world.set_tasks(tasks)
	print ("set_tasks is done")
	get_tree().get_root().add_child(world)
	
	get_tree().get_root().get_node("Lobby").hide()

	var player_scene = load("res://player.tscn")

	var spawn_points = {}
	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position=spawn_pos
		player.set_network_master(p_id) #set unique id as master.

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id])

		world.get_node("Players").add_child(player)
	
	return 
	
	# Set up score.
	world.get_node("Score").add_player(get_tree().get_network_unique_id(), player_name)
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn])

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()


remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name):
	player_name = new_player_name
	var server = WebSocketServer.new();
	server.listen(DEFAULT_PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	
	servers[0] = server


func join_game(ip, new_player_name):
	player_name = new_player_name
	var client = WebSocketClient.new();
	# var url = "ws://" + ip + ":" + str(DEFAULT_PORT) # You use "ws://" at the beginning of the address for WebSocket connections
	var url = "ws://" + ip
	print("meow join_game " + str(url))
	var error = client.connect_to_url(url, PoolStringArray(), true);
	get_tree().set_network_peer(client);

	clients[player_name] = client
	print(str(error))

func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	assert(get_tree().is_network_server())
	print ("begin_game")
	
	rpc_id(server_id, "request_start_game")


remote func request_start_game():
	print("request_start_game")
	var requested_id = get_tree().get_rpc_sender_id()
	rpc_id(requested_id, "pre_start_game", tasks)


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _process(delta):
	for s in servers:
		if servers[s].is_listening(): 
			# is_listening is true when the server is active and listening
			servers[s].poll();	
	
	for c in clients:
		if (clients[c].get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || clients[c].get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
			clients[c].poll();
