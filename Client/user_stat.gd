extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var tasks_cnt = 0
var info_rows_cnt = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _set_font(node, font_size):
	var font = DynamicFont.new()
	font.set_size(font_size)
	font.set_font_data(preload("res://montserrat.otf"))	
	node.add_font_override("font", font)


func set_player_name(player_name):
	print ("set_player_name")
	get_node("Area/Label").text = player_name
	
	
func _get_label(text):
	var l = Label.new()
	l.text = str(text)
	_set_font(l, 20)
	l.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	l.set_h_size_flags(Control.SIZE_EXPAND_FILL)	
	return 	l
	
	
func set_answers_given(correct, answers_given):
	tasks_cnt = answers_given.size()
	
	get_node("Area/GridContainer").set_columns(answers_given.size())
	for i in range(answers_given.size()):		
		get_node("Area/GridContainer").add_child(_get_label(str(i)))
	for i in range(answers_given.size()):	
		get_node("Area/GridContainer").add_child(_get_label(str(correct[i])))
	for i in range(answers_given.size()):	
		get_node("Area/GridContainer").add_child(_get_label(str(answers_given[i])))
		

func update_answer_given(task_ind, answer_given):
	var child_ind = info_rows_cnt * tasks_cnt + task_ind
	get_node("Area/GridContainer").get_child(child_ind).set_text(answer_given)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
