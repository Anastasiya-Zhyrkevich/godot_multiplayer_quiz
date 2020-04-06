extends Node2D

const TASK_NODE = preload("res://task.tscn")

var tasks_per_round = 3

var TASK_TEXTURE = load("res://s_task.png")
var TASK_DISABLED_TEXTURE = load("res://s_task_disabled.png")
var TASK_CORRECT_TEXTURE = load("res://s_task_correct.png")
var TASK_WRONG_TEXTURE = load("res://s_task_wrong.png")

func _ready():
	print("_ready")
	
func set_tasks(tasks):
	print ("set_tasks1")
	
	get_node("MarginContainer/ScrollContainer/GridContainer").set_columns(tasks_per_round)
		
	print("set_tasks2")
	var task_ind = 0
	for task in tasks:
		task.answer_given = -1
		
		var button = TextureButton.new()
		button.texture_normal = TASK_TEXTURE
		button.texture_disabled = TASK_DISABLED_TEXTURE
		
		button.connect("pressed", self, "_task_open_button_pressed", [task])
		get_node("MarginContainer/ScrollContainer/GridContainer").add_child(button)
		
		task_ind += 1
		
		print("set_tasks3")
	
func _task_open_button_pressed(task):
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task)
