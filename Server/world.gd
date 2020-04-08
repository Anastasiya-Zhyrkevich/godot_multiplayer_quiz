extends Node2D

const TASK_NODE = preload("res://task.tscn")

var tasks_per_round = 3

func _ready():
	print("_ready")
	
func set_tasks(tasks):
	pass
	
	
func _task_open_button_pressed(task):
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task)

	
