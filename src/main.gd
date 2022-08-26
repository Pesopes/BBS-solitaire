extends Node2D

var card_prefab = preload("res://src/card/card.tscn")

var unlocked_slots = [false,false,false,false]

onready var top_spaces := $TopSpaces
onready var bottom_spaces := $Spaces

onready var sound_card_play := $SFX/cardPlay
onready var sound_card_pick := $SFX/cardPick
onready var sound_card_flip := $SFX/cardFlip
onready var sound_win := $SFX/win
onready var sound_shuffle := $SFX/shuffle


var picked_up_card:Area2D = null
const Z_INDEX_BOOST = 10

export var card_offset := Vector2(0,40.0)
export var closed_stack_offset := Vector2(-2,5)
export var win_limit := 10
export var deck_limit := 4

var dist := Vector2.ZERO
var orig_pos := Vector2.ZERO

var clicked_array = []

var stats := {}

var game_history = []

func create_stack(parent:Area2D,size:int,type_deck:Array):
	for _n in range(size):
		var new_card = card_prefab.instance()
		if len(type_deck)==0:
			return
		var next_type = type_deck.pop_front()
		new_card.card_type = next_type
		new_card.position = card_offset
		new_card.connect("mouse_down",self,"card_click_down")
		new_card.connect("mouse_up",self,"card_click_up")
		parent.add_child(new_card)
		parent = new_card

func set_up_spaces(parent:Node2D):
	for space in parent.get_children():
		space.connect("mouse_down",self,"card_click_down")
		space.connect("mouse_up",self,"card_click_up")
		space.get_node("Sprite").position += card_offset
		space.get_node("Icon").position += card_offset
		space.get_node("Collider").position += card_offset

func create_deck()->Array:
	var deck = []
	for type in range(10):
#		print_debug(type)
		for _j in range(4):
			deck.push_front(Global.CARD_TYPES.values()[type])
	return deck
func shuffle_deck(deck):
	for i in range(len(deck)):
		var j = randi()%(i+1)
		var temp = deck[j]
		deck[j] = deck[i]
		deck[i] = temp

func clean_up_spaces():
	for space in top_spaces.get_children():
		space.get_node("Collider").disabled = false
		space.closed = false
		var card = get_child_by_groups(space,["card"])
		if card:
			card.remove_from_group("card")
			card.queue_free()
	for space in bottom_spaces.get_children():
		space.get_node("Collider").disabled = false
		space.closed = false
		var card = get_child_by_groups(space,["card"])
		if card:
			card.remove_from_group("card")
			card.queue_free()
	highlight_empty_space(false)
	picked_up_card = null
	
func update_difficulty():
	# I could probably use the integer of the enum to change the array
	# but I think I don't care
#	print_debug(Save.game_data)
	
	match Save.game_data.mode:
		Global.GAME_TYPES.EASY:
			unlocked_slots = [true,true,true,true]
		Global.GAME_TYPES.MEDIUM:
			unlocked_slots = [true,true,true,false]
		Global.GAME_TYPES.HARD:
			unlocked_slots = [true,true,false,false]
		Global.GAME_TYPES.EXPERT:
			unlocked_slots = [true,false,false,false]

const ANIM_TIME = 0.2
const CARD_ANIM_TIME = 0.15
const ANIM_DELAY = 0.0
func animate_card_start(anim_time_speed:float = 1.0):
	var anim_time = ANIM_TIME / anim_time_speed
	var card_anim_time = CARD_ANIM_TIME / anim_time_speed
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	for top_space in top_spaces.get_children():
		var child = get_child_by_groups(top_space,["card"])
		if child:
			var defualt_pos = child.global_position
			child.global_position = Vector2(-200,-200)
			tween.tween_property(child,"global_position",defualt_pos,anim_time*2).set_delay(ANIM_DELAY)
#			tween.tween_callback(sound_card_flip, "play")
#		while true:
#			if not child:
#				break
#			child = get_child_by_groups(child,["card"])

	for bottom_space in bottom_spaces.get_children():
		var first_child = get_child_by_groups(bottom_space,["card"])
		if not first_child:
			continue
		var defualt_pos = first_child.global_position
		first_child.global_position = Vector2(-200,-200)
#			cool animation thats too distracting :/
#			var mid_point = get_viewport_rect().size/2+Vector2(0,-100)
#			tween.tween_property(first_child,"global_position",mid_point,anim_time).set_delay(ANIM_DELAY)
		tween.tween_property(first_child,"global_position",defualt_pos,anim_time).set_delay(ANIM_DELAY)
		var child = get_child_by_groups(first_child,["card"])
		var card_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		card_tween.tween_property(self,"position",self.position,0.0).set_delay((anim_time+ANIM_DELAY)*bottom_spaces.get_child_count()+0.4/anim_time_speed)
		while true:
			if not child:
				break
			var defualt_child_pos = child.position
			child.position = Vector2(0,4)
			card_tween.tween_property(child,"position",defualt_child_pos, card_anim_time )
			child = get_child_by_groups(child,["card"])

# Run at start and on every reset
func set_up_game(first:=false):
	stats ={
		"clicked":0,
		"mode":Save.game_data.mode,
		"time_start":OS.get_unix_time()
	}
	add_to_history(create_board_obj(),unlocked_slots)
	clean_up_spaces()
	randomize()
	var deck = create_deck()
	shuffle_deck(deck)
	sound_shuffle.play()
#	becuase i remove the cards from the array 
#	I have to store the length at the start so it doesnt change
	var deck_len = len(deck)

	for empty_space in bottom_spaces.get_children():
		create_stack(empty_space,int(floor(deck_len/bottom_spaces.get_child_count())),deck)
	if first:
		animate_card_start()
	else:
		animate_card_start(2.0)
		
	update_difficulty()
	save_board()
func _ready():
	top_spaces.position -= card_offset
	bottom_spaces.position -= card_offset

	set_up_spaces(bottom_spaces)
	set_up_spaces(top_spaces)
	
	# load from save if exists
	if Save.game_data.board != null:
		load_board(Save.game_data.board,true)
	else:
		set_up_game(true)
	add_to_history(create_board_obj(),unlocked_slots)
	if Save.game_data.stats != null:
		stats = Save.game_data.stats
	if Save.game_data.unlocked_slots != null:
		unlocked_slots = Save.game_data.unlocked_slots
	save_board()

func _process(_delta):
	for i in range(top_spaces.get_child_count()):
		var top_space = top_spaces.get_child(i)
		var colour_tween := create_tween().set_ease(Tween.EASE_OUT)
		if unlocked_slots[i]:
			colour_tween.tween_property(top_space,"modulate",Color.white,0.2) 
		else:
			colour_tween.tween_property(top_space,"modulate",Color.white.darkened(0.8),0.2)
	if Input.is_action_just_pressed("RMC"):
		let_go_of_card()

func create_board_obj():
	var saved_board = {}
	saved_board.top_spaces = []
	saved_board.bottom_spaces = []
	for top_space in top_spaces.get_children():
		var space = {"cards":[]}
		var child = get_child_by_groups(top_space,["card"])
		while true:
			if not child:
				break
			space.cards.push_back({"type":child.card_type}) 
			child = get_child_by_groups(child,["card"])
		space.closed = top_space.closed
		saved_board.top_spaces.push_back(space)
	for bottom_space in bottom_spaces.get_children():
		var space = {"cards":[]}
		var child = get_child_by_groups(bottom_space,["card"])
		while true:
			if not child:
				break
			space.cards.push_back({"type":child.card_type}) 
			child = get_child_by_groups(child,["card"])
		space.closed = bottom_space.closed		
		saved_board.bottom_spaces.push_back(space)
	return saved_board

func add_to_history(board,slots):
	var new_point = {
		"board":board,
		"unlocked_slots":slots
		}
	if len(game_history)>0 and new_point.hash() == game_history[len(game_history)-1].hash():
		print_debug("Its the same save lol")
		return
	game_history.push_back(new_point)
	print_debug("saving to history")

func save_board():
	var saved_board = create_board_obj()
	Save.game_data.board = saved_board
	Save.game_data.unlocked_slots = unlocked_slots
	Save.game_data.stats = stats
	Save.save_data()
#	print_debug(saved_board)
func load_board(board,first:=false):
	clean_up_spaces()
	for top_space_index in range(len(board.top_spaces)):
		var space = board.top_spaces[top_space_index]
		var space_obj = top_spaces.get_child(top_space_index)
		space_obj.modulate = Color.blue
		var stack_deck = []
		for card in space.cards:
			stack_deck.push_back(card.type)
		create_stack(space_obj,len(stack_deck),stack_deck)
		if space.closed:
			space_obj.closed = true
			close_stack(space_obj,true)
	for bottom_space_index in range(len(board.bottom_spaces)):
		var space = board.bottom_spaces[bottom_space_index]
		var space_obj = bottom_spaces.get_child(bottom_space_index)
		var stack_deck = []
		for card in space.cards:
			stack_deck.push_back(card.type)
		create_stack(space_obj,len(stack_deck),stack_deck)
		if space.closed:
			space_obj.closed = true
			close_stack(space_obj,true)
	if first:
		animate_card_start()
func win():
	get_node("%WinDialog").win_popup(stats.time_start,OS.get_unix_time(),stats.clicked,stats.mode)

func check_win():
	var count = 0
	for top_space in top_spaces.get_children():
		if top_space.closed:
			count += 1
	for bottom_space in bottom_spaces.get_children():
		if bottom_space.closed:
			count += 1
	if count >= win_limit:
		win()
func card_click_down(target:Node2D):
#	print_debug(picked_up_card)
#	if not picked_up_card:
	clicked_array.push_front(target)
#	print_debug("Adding card num: ",len(clicked_array))



func card_click_up(target:Node2D):
	if len(clicked_array) == 0:
		return
		
	var top_card = get_top_card(clicked_array)
	if picked_up_card:
		use_card(top_card)
		clicked_array = []		
	else:
		if top_card == target:
			print_debug("best is: ",top_card, " ", "picking up the card")
			pick_up_card(top_card)
			clicked_array = []

func pick_up_card(card:Area2D):
#	has to be a card
	if not card.is_in_group("card"):
		return
	if not all_children_match(card):
		return
	
		
	dist = card.global_position-get_global_mouse_position()
	orig_pos = card.global_position
	card_selector(card,true)
	var full_deck_arr = get_full_deck(card)
	if len(full_deck_arr)>=deck_limit:
		highlight_empty_space(true)
	else:
		highlight_empty_space(false)		
	sound_card_pick.play()

	card.z_index += Z_INDEX_BOOST
	card.get_node("Shape").disabled = true
	picked_up_card = card

# Loops trough parents of node true if one of the parents == node_parent
func recursive_parent_check(node:Node,node_parent:Node)->bool:
	var curr_parent = node
	while true:
		if not curr_parent:	
			return false
		if curr_parent == node_parent:
			return true
		curr_parent = curr_parent.get_parent()
	return false

func animate_card_use(card:Area2D,target_pos:Vector2,defualt_scale:Vector2):
	var defualt_z_index = card.z_index
	var target_scale = card.scale
	card.global_scale = defualt_scale
	var mid_point := card.position.linear_interpolate(target_pos,0.5)
	var max_scale = Vector2(3.6,3.6)
	# First part
	var anim_time = 0.3584
	var pos_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
#	pos_tween.tween_property(card,"position",mid_point,first_part_anim_time)
#	pos_tween.parallel().tween_property(card,"global_scale",max_scale,first_part_anim_time)
	# Second part
#	pos_tween.set_trans(Tween.TRANS_CUBIC)
	pos_tween.tween_property(card,"position",target_pos,anim_time)
	pos_tween.parallel().tween_property(card,"z_index",1000,0.1)
	pos_tween.parallel().tween_property(card,"scale",target_scale,anim_time)
	pos_tween.parallel().tween_property(card,"z_index",defualt_z_index,anim_time)


func use_card(target:Node2D):
	if not target or not picked_up_card:
		printerr("Something not defined in use_card function")
		return
	print_debug("Using current card on card in pos", target.position)
	add_to_history(create_board_obj(),unlocked_slots)

	var parent := picked_up_card.get_parent()

	if target == parent or recursive_parent_check(target,parent):
		let_go_of_card()
		print_debug("DA same")
		return
#	last in stack or empty space + matching types (empty is all types) -> valid spot
	if get_child_by_groups(target,["card","empty_space"]) == null and matching_types(target,picked_up_card):

		var should_close = false

		var target_space = get_empty_space(target)

		var space_child := get_child_by_groups(target_space,["card"])

#		print_debug(space_child and is_full_deck(space_child))
		# Reparent and set tween new position
		var defualt_scale = picked_up_card.global_scale
		var only_one = check_if_only_one(target,picked_up_card)
		parent.remove_child(picked_up_card)
		target.add_child(picked_up_card)
		if (space_child and is_full_deck(space_child)) or is_full_deck(picked_up_card):
			should_close = true
		elif only_one:
			target.remove_child(picked_up_card)
			parent.add_child(picked_up_card)
			return
#		print_debug("POS IS: ", orig_pos)
		if should_close:
			close_stack(target_space)
		
		picked_up_card.global_position = orig_pos
		var target_pos := Vector2.ZERO
		if should_close and picked_up_card != get_child_by_groups(target_space,["card"]):
			target_pos = closed_stack_offset
		else:
			target_pos = card_offset
		animate_card_use(picked_up_card,target_pos,defualt_scale)

		
		sound_card_play.play()
			
#		picked_up_card.position = Vector2.ZERO
		let_go_of_card()
		stats.clicked += 1
	check_win()
	save_board()

func highlight_empty_space(on:bool):
	for top_space in top_spaces.get_children():
		if (get_child_by_groups(top_space,["card"]) == null 
				and not top_space.closed 
				and unlocked_slots[top_space.index]):
			top_space.get_node("Icon").visible = on
	for bottom_space in bottom_spaces.get_children():
		if (get_child_by_groups(bottom_space,["card"]) == null
				and not bottom_space.closed 
				and unlocked_slots[bottom_space.index]):
			bottom_space.get_node("Icon").visible = on

func unlock_next_space():
	for n in len(unlocked_slots):
		if not unlocked_slots[n]:
			unlocked_slots[n] = true
			return
	
func close_stack(stack:Area2D,is_loading=false):
	print_debug("CLOSING")
	if not is_loading and not stack.is_in_group("only_one"):
		unlock_next_space()
	stack.closed = true
	stack.get_node("Collider").disabled = true
	var first_card := get_child_by_groups(stack,["card"])
	#disable all cards and "flip" them
	if first_card:
		var child = first_card
		while true:
			if not child:
				break
			child.card_type = Global.CARD_TYPES.CLOSED
			child.get_node("Shape").disabled = true
			child.position = closed_stack_offset
			child = get_child_by_groups(child,["card"])
	first_card.position = card_offset
	if not is_loading:
		sound_card_flip.play()

func contains_type(card,stack_array:Array)->bool:
	for check_stack in stack_array:
		var card_2 = get_child_by_groups(check_stack,["card"])
		if not card_2:
			continue
		if matching_types(card,card_2):
			return true
	return false

# the top spaces rules 
func check_if_only_one(target:Area2D,card:Area2D)->bool:
	if target.is_in_group("only_one") or target.get_parent().is_in_group("only_one"):
		if (get_child_by_groups(target,["card"]) 
			or target.is_in_group("card") 
			or get_child_by_groups(card,["card"])
#			or contains_type(card,top_spaces.get_children())
			or not unlocked_slots[target.index]):
			return true
	return false

func all_children_match(parent:Area2D)->bool:
	var all_match = true
	var child_card := get_child_by_groups(parent,["card"])
	while true:
#		print_debug(last_child)
		if not child_card:
			break
		if not matching_types(parent,child_card):
			all_match = false
			break
		child_card = get_child_by_groups(child_card,["card"])
	return all_match

func matching_types(card_1:Area2D,card_2:Area2D) -> bool:
	if card_1.is_in_group("empty_space") or card_2.is_in_group("empty_space"):
#		print_debug("cheating mathcing types")
		return true
	return card_1.card_type == card_2.card_type

func is_full_deck(first_card:Area2D)->bool:
	var child_card = get_child_by_groups(first_card,["card"])
#	var is_full = true
	for _n in range(deck_limit-1):
		if not child_card:
			return false
#		print_debug("IS it the full deck that i am dreaming of",not matching_types(first_card,child_card))
		if not matching_types(first_card,child_card):
			return false
		child_card = get_child_by_groups(child_card,["card"])
	return true

func get_full_deck(card_in_deck:Area2D)->Array:
	var deck_array = [card_in_deck]
	var parent = card_in_deck.get_parent()
	while true:
		if not parent or parent.is_in_group("empty_space"):
			break
		print_debug(parent.get_groups())
		if matching_types(parent,card_in_deck):
			deck_array.push_back(parent)
		else:
			break
		parent = parent.get_parent()
	var child = get_child_by_groups(card_in_deck,["card"])
	while true:
		if not child or child.is_in_group("empty_space"):
			break
		if matching_types(child,card_in_deck):
			deck_array.push_back(child)
		else:
			break
		child = get_child_by_groups(child,["card"])
	return deck_array
func let_go_of_card():
	if not picked_up_card:
		return
#	print_debug("Removing picked up card")
	picked_up_card.z_index -= Z_INDEX_BOOST
	#unselect card
	card_selector(picked_up_card,false)
	highlight_empty_space(false)
#	picked_up_card.position = orig_pos
	if picked_up_card.card_type != Global.CARD_TYPES.CLOSED:
		picked_up_card.get_node("Shape").disabled = false
#	picked_up_card.input_pickable = true
	picked_up_card = null

func card_selector(card:Node2D,on:bool):
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if on:
		tween.tween_property(card.get_node("Sprites").material,"shader_param/line_color",Color.goldenrod,0.15)
		tween.parallel().tween_property(card,"modulate",card.modulate.darkened(0.15),0.15)
	else:
		tween.tween_property(card.get_node("Sprites").material,"shader_param/line_color",Color.black,0.15)
		tween.parallel().tween_property(card,"modulate",Color.white,0.15)
# uses absolute z-index to find the top most node
func get_top_card(cards) -> Node2D:
	#some defualt value
	var best = cards[0]
	for card in clicked_array:
#		print_debug(get_absolute_z_index(card)," > ",get_absolute_z_index(best))
		if get_absolute_z_index(card)>get_absolute_z_index(best):
			best = card
	return best

func get_empty_space(card:Area2D)->Area2D:
	var parent = card
	while true:
		if parent.is_in_group("empty_space"):
			return parent
		parent = parent.get_parent()
	return null
#	Compares children by array of groups (only one has to match)
static func get_child_by_groups(parent: Node, groups: PoolStringArray)->Node:
	var children := parent.get_children()
	for child in children:
		for group in groups:
			if child.is_in_group(group):
				return child
			
	return null
static func get_absolute_z_index(target: Node2D) -> int:
	var node = target;
	var z_index = 0;
	while node and node.is_class('Node2D'):
		z_index += node.z_index;
		if !node.z_as_relative:
			break;
		node = node.get_parent();
	return z_index;

#least efficient solution
func go_back_in_history():
	if len(game_history) <=1:
		return
	print_debug("Going back")
	var one_back = game_history.pop_back()
	load_board(one_back.board)
	unlocked_slots = one_back.unlocked_slots

func _on_Reset_pressed():
	set_up_game()

func _on_SettingsButton_pressed():
	save_board()
	$UI/Settings.enable_popup(0.1)

func _on_Back_pressed():
	go_back_in_history()

