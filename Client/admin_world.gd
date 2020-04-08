extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const USER_STAT = preload("res://user_stat.tscn")

var player_to_ind = {}
var current_ind = 0
var correct = []

# Called when the node enters the scene tree for the first time.
func _ready():
	current_ind = 0


func set_players(tasks_correct, player_to_answer_given):
	correct = tasks_correct
	print("set_players " + str(player_to_answer_given))
	for player_name in player_to_answer_given:
		_add_player(player_name, player_to_answer_given[player_name])
	

func add_player(player_name, answers_given):
	_add_player(player_name, answers_given)


func _add_player(player_name, answers_given):
	print("_add_player " + player_name)
	
	var user_stat = USER_STAT.instance()
	user_stat.set_player_name(player_name)
	user_stat.set_answers_given(correct, answers_given)
	
	print("after set_answers_given")
	
	player_to_ind[player_name] = current_ind
	current_ind += 1
	
	get_node("MarginContainer/ScrollContainer/GridContainer").add_child(user_stat)
	print("_add_player finish")
	
	
func update_player(player_name, task_ind, answer_given):
	var ind = player_to_ind[player_name]
	get_node("MarginContainer/ScrollContainer/GridContainer").get_child(ind).update_answer_given(task_ind, answer_given)
	
