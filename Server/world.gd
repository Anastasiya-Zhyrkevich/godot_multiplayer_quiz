extends Node2D

const TASK_NODE = preload("res://task.tscn")

var tasks = []

var tasks_per_round = 3

func _ready():
	print("_ready")
	
	var window_size = get_viewport().size
	
	var spot_size = (window_size.x / tasks_per_round)
	var button_size_span_percent = 0.8
	var button_size = button_size_span_percent * spot_size
	var button_span = 0.5 * (1 - button_size_span_percent) * spot_size
	
	var task_ind = 0
	for task in tasks:
		task.answer_given = -1
		
		var X = (task_ind % tasks_per_round) * spot_size
		var Y = (task_ind / tasks_per_round) * spot_size
		
		var button = Button.new()
		button.set_position(Vector2(X + button_span, Y + button_size))
		button.set_size(Vector2(button_size, button_size))
		button.text = "Button"
		button.show()
		
		button.connect("pressed", self, "_task_open_button_pressed", [task])
		add_child(button)
		
		task_ind += 1
	
func _task_open_button_pressed(task):
	var task_node = TASK_NODE.instance()
	add_child(task_node)
	
	task_node.init_task_node(task)

	
