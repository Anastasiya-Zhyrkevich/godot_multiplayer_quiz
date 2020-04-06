extends Node2D

const TASK_NODE = preload("res://task.tscn")

var tasks_per_round = 3

var TASK_TEXTURE = load("res://s_task.png")
var TASK_DISABLED_TEXTURE = load("res://s_task_disabled.png")
var TASK_CORRECT_TEXTURE = load("res://s_task_correct.png")
var TASK_WRONG_TEXTURE = load("res://s_task_wrong.png")

var Constants = preload("res://constants.gd")
var answers_given = []


func _ready():
	print("_ready")
	
func set_tasks(tasks, server_answers_given):
	answers_given = server_answers_given
	get_node("MarginContainer/ScrollContainer/GridContainer").set_columns(tasks_per_round)
	
	for i in range(tasks.size()):
		var button = TextureButton.new()
		
		_update_task_style(
			button, 
			_get_style(answers_given[i], tasks[i].correct)
		)
		
		if answers_given[i] == Constants.DISABLED_TASK:
			button.disabled = true
		
		button.connect("pressed", 
			self, 
			"_task_open_button_pressed", 
			[i, tasks[i], answers_given[i]]
		)
		
		get_node("MarginContainer/ScrollContainer/GridContainer").add_child(button)


func _task_open_button_pressed(task_ind, task, answer_given):
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task_ind, task, answer_given)
	task_node.connect("answer_is_given", self, "_task_answer_is_given")


func _task_answer_is_given(task_ind, is_answer_correct, answer_given):
	
	answers_given[task_ind] = answer_given
	if is_answer_correct:
		_update_task_style(
			get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind), 
			"correct"
		)
	else:
		_update_task_style(
			get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind), 
			"wrong"
		)


func _update_task_style(node, style_param):
	node.texture_disabled = TASK_DISABLED_TEXTURE
	
	if style_param == "no_answer":
		node.texture_normal = TASK_TEXTURE
	elif style_param == "correct":
		node.texture_normal = TASK_CORRECT_TEXTURE
	elif style_param == "wrong":
		node.texture_normal = TASK_WRONG_TEXTURE
	else:
		print ("Error! Unknown style param")


func _get_style(answer_given, correct):
	if answer_given < 0:
		return "no_answer"
	
	if answer_given == correct:
		return "correct"
	
	return "wrong"

# TODO: add function for updating round
