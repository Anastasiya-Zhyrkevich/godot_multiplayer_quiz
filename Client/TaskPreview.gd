extends Control


signal pressed()


var TASK_TEXTURE = load("res://s_task.png")
var TASK_DISABLED_TEXTURE = load("res://s_task_disabled.png")
var TASK_CORRECT_TEXTURE = load("res://s_task_correct.png")
var TASK_WRONG_TEXTURE = load("res://s_task_wrong.png")


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Button").connect("pressed", self, "_button_pressed")


func set_task_ind(i):
	get_node("Label").text = str(i)
	

func _button_pressed():
	emit_signal("pressed")


func update_task_style(style_param):
	var node = get_node("Button")
	node.texture_disabled = TASK_DISABLED_TEXTURE
	
	if style_param == "no_answer":
		node.texture_normal = TASK_TEXTURE
	elif style_param == "correct":
		node.texture_normal = TASK_CORRECT_TEXTURE
	elif style_param == "wrong":
		node.texture_normal = TASK_WRONG_TEXTURE
	else:
		print ("Error! Unknown style param")

func set_disabled(mode):
	get_node("Button").disabled = mode

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
