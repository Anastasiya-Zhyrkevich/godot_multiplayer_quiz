extends Node2D

signal answer_is_given(task_ind, is_answer_correct, answer_given)

var Constants = preload("res://constants.gd")

var button_styles = []

func _ready():
	get_node("Background/Description").text = ""
	_set_font(get_node("Background/Description"), 18)
	_set_font(get_node("Background/CorrectAnswer"), 18)
	
	button_styles = []


func _set_font(node, font_size):
	var font = DynamicFont.new()
	font.set_size(font_size)
	font.set_font_data(preload("res://montserrat.otf"))	
	node.add_font_override("font", font)


func _disable_answers():
	var children_cnt = get_node("Background/GridContainer").get_child_count() 
	for i in range(children_cnt - 1):
		get_node("Background/GridContainer").get_child(i).disabled = true


func _make_choice_pressed(task_ind, answer_given, correct, correct_answer_text):
	print("_make_choice_pressed")
	
	_update_button_color(answer_given, correct)
	_disable_answers()
	get_node("Background/CorrectAnswer").text = "Correct answer: " + str(correct_answer_text)
	emit_signal("answer_is_given", task_ind, answer_given == correct, answer_given)

	
func _close_task():
	queue_free()


func _add_closing_button():
	var close_button = Button.new()
	close_button.text = "Close question"
		
	close_button.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	close_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)		

	close_button.connect("pressed", self, "_close_task")
	get_node("Background/GridContainer").add_child(close_button)


func _set_description(descr):
	get_node("Background/Description").text = descr


func _get_answer_color(current_ind, answer_given, correct):
	if answer_given < 0:
		return Constants.GREY 
		
	var color = Constants.GREY
	if answer_given == correct and current_ind == answer_given:
		color = Constants.GREEN  # green
	if answer_given != correct and current_ind == answer_given:
		color = Constants.RED  # red
	return color


func _update_button_color(answer_given, correct):
	var box = button_styles[answer_given]
	box.bg_color = _get_answer_color(answer_given, answer_given, correct)


func _set_answers(task_ind, answers, correct, answer_given):
	button_styles.clear()
	get_node("Background/GridContainer").set_columns(answers.size() + 1)
	
	for i in range(answers.size()):
		var ans_button = Button.new()
		ans_button.text = answers[i]
		_set_font(ans_button, 18)
		
		ans_button.connect("pressed", 
						   self, 
						   "_make_choice_pressed", 
						   [task_ind, i, correct, answers[correct]])	
		
		if answer_given != -1:
			ans_button.disabled	 = true
		
		var box = StyleBoxFlat.new()
		box.bg_color = _get_answer_color(i, answer_given, correct)
		ans_button.set('custom_styles/normal', box)	
		ans_button.set('custom_styles/disabled', box)	
		button_styles.append(box)	
		
		ans_button.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		ans_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
		get_node("Background/GridContainer").add_child(ans_button)
		
	_add_closing_button()	


func init_task_node(task_ind, task, answer_given):
	_set_description(task.description)
	_set_answers(task_ind, task.answers, task.correct, answer_given)
