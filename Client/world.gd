extends Node2D

const TASK_NODE = preload("res://task.tscn")

var tasks_per_round = 3

var Constants = preload("res://constants.gd")
var answers_given = []

const TASK_PREVIEW = preload("res://TaskPreview.tscn")

signal user_answer_is_given(task_ind, answer_given)


func _ready():
	print("_ready")
	
func set_tasks(tasks, server_answers_given):
	answers_given = server_answers_given
	get_node("MarginContainer/ScrollContainer/GridContainer").set_columns(tasks_per_round)
	
	for i in range(tasks.size()):
		var task_preview = TASK_PREVIEW.instance()
		
		task_preview.set_task_ind(i)
		task_preview.update_task_style(
			_get_style(answers_given[i], tasks[i].correct)
		)
		
		if answers_given[i] == Constants.DISABLED_TASK:
			task_preview.set_disabled(true)
		
		task_preview.connect("pressed", 
			self, 
			"_task_open_button_pressed", 
			[i, tasks[i]]
		)
		
		get_node("MarginContainer/ScrollContainer/GridContainer").add_child(task_preview)


func _task_open_button_pressed(task_ind, task):
	# Every time different value
	var answer_given = answers_given[task_ind]
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task_ind, task, answer_given)
	task_node.connect("answer_is_given", self, "_task_answer_is_given")
	task_node.connect("need_help", self, "_help_requested")


func _task_answer_is_given(task_ind, is_answer_correct, answer_given):
	print("_task_answer_is_given " + str(answers_given))
	answers_given[task_ind] = answer_given
	print("_task_answer_is_given " + str(answers_given))
	if is_answer_correct:
		var preview = get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind)
		preview.update_task_style("correct")
	else:
		var preview = get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind)
		preview.update_task_style("wrong")
	gamestate.update_user_answer_given(task_ind, answer_given)


func _help_requested(task_ind):
	print("_help_requested")
	gamestate.help_requested(task_ind)


func _get_style(answer_given, correct):
	if answer_given < 0:
		return "no_answer"
	
	if answer_given == correct:
		return "correct"
	
	return "wrong"

func _update_task_status(player_name, task_ind, answer_given):
	if answers_given[task_ind] == Constants.DISABLED_TASK and answer_given != Constants.DISABLED_TASK:
			var preview = get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind)
			preview.set_disabled(false)
	
	answers_given[task_ind] = answer_given
	
	var preview = get_node("MarginContainer/ScrollContainer/GridContainer").get_child(task_ind)
	preview.update_task_style(
		_get_style(answer_given, 100)  # Random correct number
	)
