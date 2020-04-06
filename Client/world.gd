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
		button.texture_normal = TASK_TEXTURE
		button.texture_disabled = TASK_DISABLED_TEXTURE
		
		if answers_given[i] == Constants.DISABLED_TASK:
			button.disabled = true
		
		button.connect("pressed", 
			self, 
			"_task_open_button_pressed", 
			[tasks[i], answers_given[i]]
		)
		get_node("MarginContainer/ScrollContainer/GridContainer").add_child(button)


func _task_open_button_pressed(task, answer_given):
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task, answer_given)

# TODO: add function for updating round
