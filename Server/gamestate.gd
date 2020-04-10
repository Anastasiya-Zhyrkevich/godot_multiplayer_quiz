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

var scores = {}  # player: score, all possible players

var server_id = 0

var servers = {}
var clients = {}

var TASKS_PATH = 'res://tasks.json'
var tasks = []
# player_name: [answers] for reconnection possible
var players_to_answer_given = {}

var current_round = 1

var Constants = preload("res://constants.gd")

var ADMIN_ID = -1

const PING_TIMEOUT = 10
var current_ping_time = 0


# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal tasks_missing()


# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	print("_player_connected " + str(id) + " " + player_name)
	
	rpc_id(id, "register_player", player_name)
	rpc_id(id, "register_server_id", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	unregister_player(id)
	
	if ADMIN_ID == id:
		ADMIN_ID = -1


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
	
	if not scores.has(new_player_name):
		scores[new_player_name] = 0
		
	_send_all_scores()
			
	emit_signal("player_list_changed")


func _send_all_scores():
	for player_id in players:
		print ("request update " + str(player_id) + str(scores))
		rpc_id(player_id, "_update_world_scores", scores)


func _send_partial_scores(for_who, delta):
	for player_id in players:
		print ("request update " + str(player_id) + str(scores))
		rpc_id(player_id, "_update_user_scores", for_who, delta)


remote func register_server_id(server_player_name):
	var id = get_tree().get_rpc_sender_id()
	print("server is: " + str(id))
	server_id = id


func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")


func read_tasks():
	print("read_tasks")
	var file = File.new()
	
	if not file.file_exists(TASKS_PATH):
		emit_signal("tasks_missing")
		print("tasks_missing")
		return
	
	file.open(TASKS_PATH, File.READ)
	var text = file.get_as_text()
	tasks = parse_json(text)
	file.close()


remote func pre_start_game(tasks, answers_given, scores):
	# Change scene.
	var world = load("res://world.tscn").instance()
	world.set_tasks(tasks, answers_given)
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
	print("host_game")
	var server = WebSocketServer.new();
	# var OS_PORT = OS.get_environment("PORT");
	# print(OS_PORT)
	var error = server.listen(DEFAULT_PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	
	servers[0] = server
	print(DEFAULT_PORT)
	print (str(error))


func join_game(ip, new_player_name):
	player_name = new_player_name
	print("join_game")
	var client = WebSocketClient.new();
	var url = "ws://" + ip  # You use "ws://" at the beginning of the address for WebSocket connections
	var error = client.connect_to_url(url, PoolStringArray(), true);
	get_tree().set_network_peer(client);

	clients[player_name] = client


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
	var player_name = players[requested_id]
	
	if players_to_answer_given.has(player_name) == false:
		var answers_given = []
		for i in range(tasks.size()):
			answers_given.append(Constants.DISABLED_TASK)

		# Join late round
		for i in range(min(current_round * Constants.TASKS_PER_ROUND, tasks.size())):
			answers_given[i] = Constants.NO_ANSWER_TASK
			
		players_to_answer_given[player_name] = answers_given
	
	print("answers_given " + str(players_to_answer_given[player_name]))
	if player_name == Constants.ADMIN_PLAYER_NAME:
		var correct = []
		for task in tasks:
			correct.append(task.correct)		
		print("admin_pre_start_game")
		rpc_id(requested_id, "admin_pre_start_game", correct, players_to_answer_given, scores)
		ADMIN_ID = requested_id
	else:
		rpc_id(requested_id, "pre_start_game", tasks, players_to_answer_given[player_name], scores)
		
		if ADMIN_ID != -1:
			rpc_id(ADMIN_ID, "admin_add_player", player_name, players_to_answer_given[player_name])


func admin_update_task_status(player_name, task_ind, answer_given):
	if ADMIN_ID != -1:
		rpc_id(ADMIN_ID, "update_task_status", player_name, task_ind, answer_given)


func update_user_answer_given(task_ind, answer_given):
	rpc_id(server_id, "_update_server_user_answer_given", task_ind, answer_given)


remote func _update_server_user_answer_given(task_ind, answer_given):
	var requested_id = get_tree().get_rpc_sender_id()
	var player_name = players[requested_id]
	
	players_to_answer_given[player_name][task_ind] = answer_given
	
	admin_update_task_status(player_name, task_ind, answer_given)
	
	if tasks[task_ind].correct == answer_given:
		scores[player_name] += tasks[task_ind].score
		
		_send_partial_scores(player_name, tasks[task_ind].score)
	
	
remote func request_next_round():
	var start_ind = current_round * Constants.TASKS_PER_ROUND
	current_round += 1
	if start_ind >= tasks.size():
		return
		
	var answer_given = Constants.NO_ANSWER_TASK  # new status
	
	for player_id in players:
		for i in range(start_ind, min(start_ind + Constants.TASKS_PER_ROUND, tasks.size())):
			if player_id == ADMIN_ID:
				continue
			
			var player_name = players[player_id]
			players_to_answer_given[player_name][i] = answer_given
			
			# Send to admin
			admin_update_task_status(player_name, i, answer_given)
			# Send to player
			rpc_id(player_id, "update_task_status", player_name, i, answer_given)
	
	# Update unconnected
	for player_name in players_to_answer_given:
		if players_to_answer_given[player_name][start_ind] == Constants.NO_ANSWER_TASK:
			continue
		
		if player_name == Constants.ADMIN_PLAYER_NAME:
			continue
		
		for i in range(start_ind, min(start_ind + Constants.TASKS_PER_ROUND, tasks.size())):
			players_to_answer_given[player_name][i] = answer_given
			
			# Send to admin
			admin_update_task_status(player_name, i, answer_given)
			
		
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
	
	read_tasks()

func _process(delta):
	for s in servers:
		if servers[s].is_listening(): 
			# is_listening is true when the server is active and listening
			servers[s].poll();	
	
	for c in clients:
		if (clients[c].get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || clients[c].get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
			clients[c].poll();
			
	current_ping_time += delta
	if current_ping_time > PING_TIMEOUT:
		current_ping_time = 0
		for player_id in players:
			rpc_id(player_id, "ping_server")


remote func ping_server():
	print("Recieved ping")

