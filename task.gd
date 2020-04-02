extends Node2D

signal answer_is_given(what)

var button_styles = []

func _ready():
	get_node("Background/Description").text = ""
	button_styles = []

func _disable_answers():
	var children = get_children()
	for i in range(children.size() - 1):
		children[i].disable = true

func _make_choice_pressed(answer_given, correct):
	print("_make_choice_pressed")
	
	_update_button_color(answer_given, correct)
	_disable_answers()
	
	emit_signal("answer_is_given", answer_given == correct, answer_given)
	
func _close_task():
	queue_free()

func _add_closing_button():
	var close_button = Button.new()
	close_button.text = "Close question"
		
	close_button.connect("pressed", self, "_close_task")
	get_node("Background/GridContainer").add_child(close_button)

func _set_description(descr):
	get_node("Background/Description").text = descr

func _get_answer_color(answer_given, correct):
	var color = Color(109.0 / 255,123.0 / 255, 141.0 / 255)	# ordinary 
	if answer_given == correct:
		color = Color(65,191,137)  # green
	if answer_given != correct and answer_given != -1:
		color = Color(255,115,90)  # red
	return Color(255 / 255, 115 / 255, 90 /255)
	# return color


func _update_button_color(answer_given, correct):
	var box = button_styles[answer_given]
	box.bg_color = _get_answer_color(answer_given, correct)

func _set_answers(answers, correct, answer_given):
	button_styles.clear()
	get_node("Background/GridContainer").set_columns(answers.size() + 1)
	
	var answer_ind = 0
	for answer in answers:
		print("meow")
		
		var ans_button = Button.new()
		ans_button.text = answer
		ans_button.set_size(Vector2(100, 100))
		
		ans_button.connect("pressed", 
						   self, 
						   "_make_choice_pressed", 
						   [answer_ind, correct])	
		
		if answer_given != -1:
			ans_button.disabled		
		
		var box = StyleBoxFlat.new()
		box.bg_color = _get_answer_color(answer_given, correct)
		ans_button.set('custom_styles/normal', box)		
		button_styles.append(box)	
	
		get_node("Background/GridContainer").add_child(ans_button)
	
		answer_ind += 1
	_add_closing_button()	

func init_task_node(task):
	_set_description(task.description)
	_set_answers(task.answers, task.correct, task.answer_given)
