extends HBoxContainer

var player_labels = {}
const Constants = preload("res://constants.gd")

func _process(_delta):
	pass

# for_who -- by player_name
func increase_score(for_who, delta):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += delta
	pl.label.set_text(pl.name + "\n" + str(pl.score))


func add_player(new_player_name, score):
	if new_player_name == Constants.ADMIN_PLAYER_NAME:
		return
	
	var l = Label.new()
	l.set_align(Label.ALIGN_CENTER)
	l.set_text(new_player_name + "\n" + str(score))
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = DynamicFont.new()
	font.set_size(18)
	font.set_font_data(preload("res://mintSpirit.otf"))
	l.add_font_override("font", font)
	add_child(l)

	player_labels[new_player_name] = { name = new_player_name, label = l, score = score }


func _ready():
	$"../Winner".hide()
	set_process(true)


func clear_children_nodes():
	for i in range(0, get_child_count()):
		get_child(i).queue_free()


func _on_exit_game_pressed():
	gamestate.end_game()
