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
var players_to_answer_given = {}

var Constants = preload("res://constants.gd")

var timer


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


remote func _update_world_scores(scores):
	if not has_node("/root/World"):
		return 
	var world = get_tree().get_root().get_node("World") 
	world.get_node("Score").clear_children_nodes()
	
	print("_update_world_scores " + str(players))
	for pn in scores:
		world.get_node("Score").add_player(pn, scores[pn])


remote func _update_user_scores(for_who, delta):
	if not has_node("/root/World"):
		return 
	var world = get_tree().get_root().get_node("World") 
	world.get_node("Score").increase_score(for_who, delta)


func _set_ping_timer():
	timer = Timer.new()
	timer.set_wait_time(10)
	timer.autostart = true	
	get_tree().get_root().add_child(timer)
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.start()


remote func pre_start_game(tasks, answers_given, scores):
	# Change scene.
	var world = load("res://world.tscn").instance()
	world.set_tasks(tasks, answers_given)

	print ("set_tasks is done")
	get_tree().get_root().add_child(world)
	
	get_tree().get_root().get_node("Lobby").hide()
	
	# Set up score.
	_update_world_scores(scores)
	
	# Ping server
	_set_ping_timer()


remote func admin_pre_start_game(correct, player_to_answers_given, scores):
	print("admin_pre_start_game")
	var world = load("res://admin_world.tscn").instance()
	world.set_players(correct, player_to_answers_given)
	world.connect("next_round", self, "_send_request_next_round")
	
	print("set_players added")
	
	get_tree().get_root().add_child(world)
	print("World added")	
	get_tree().get_root().get_node("Lobby").hide()
	print("admin_pre_start_game finish")
	
	_update_world_scores(scores)

	# Ping server
	_set_ping_timer()
	

func _send_request_next_round():
	rpc_id(server_id, "request_next_round")


remote func admin_add_player(player_name, answers_given):
	if not has_node("/root/World"):
		return 
		
	var world = get_tree().get_root().get_node("World") 
	world.add_player(player_name, answers_given)


func update_user_answer_given(task_ind, answer_given):
	rpc_id(server_id, "_update_server_user_answer_given", task_ind, answer_given)


func help_requested(task_ind):
	rpc_id(server_id, "_help_requested_from_user", task_ind)


remote func admin_help_requested(player_name, task_ind):
	if not has_node("/root/World"):
		return 
		
	var world = get_tree().get_root().get_node("World") 
	world._update_player_help(player_name, task_ind)
	

remote func _update_server_user_answer_given(task_ind, answer_given):
	var requested_id = get_tree().get_rpc_sender_id()
	var player_name = players[requested_id]
	
	players_to_answer_given[player_name][task_ind] = answer_given


remote func _help_requested_from_user(task_ind):
	var requested_id = get_tree().get_rpc_sender_id()
	var player_name = players[requested_id]
	# TODO (send to admin)


# For admin player_name makes sense, for player - for info 
remote func update_task_status(player_name, task_ind, answer_given):
	if not has_node("/root/World"):
		return 
		
	var world = get_tree().get_root().get_node("World") 
	world._update_task_status(player_name, task_ind, answer_given)


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
	client.connect("connection_closed", self, "_handle_closed_connection")
	
	get_tree().set_network_peer(client);

	get_tree().connect("connection_closed", self, "_handle_closed_connection")
	
	clients[player_name] = client
	print(str(error))


func _handle_closed_connection(is_clean_close):
	print("_handle_closed_connection " + str(is_clean_close))


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	# assert(get_tree().is_network_server())
	print ("begin_game")
	rpc_id(server_id, "request_start_game")

	
remote func request_start_game():
	print("request_start_game")
	var requested_id = get_tree().get_rpc_sender_id()
	rpc_id(requested_id, "pre_start_game", tasks, players_to_answer_given[requested_id])


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
		else:
			print("Connection status: " + c + " " + str(clients[c].get_connection_status()))


# Need to do for Heroku not closing websocket connection
func _on_timer_timeout():
	print("_on_timer_timeout")
	if server_id != 0:
		rpc_id(server_id, "ping_server")


remote func ping_server():
	print("Recieved ping")	
