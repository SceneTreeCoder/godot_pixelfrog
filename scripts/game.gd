extends Node2D

const planet = preload("res://scenes/planet.tscn")

var seconds_from_last_spawn := 0.0

const R = 420.0
const NPOINTS = 8
const POINTSROTATE = NPOINTS - 1

const SPAWN_DELAY:float = 3.5

var landers: Array[Lander] = []
var stationary_landers_container: Node2D
var stationary_landers :Array[Lander] = []

var _stacks_rotation :int = 0
var _stacks : Dictionary[int, Array] = {}
var timer:Timer = null
var move_direction: int
var running_out_tweens_count = 0
var was_combo = false

func clear_removed_landers():
	var removed := true
	
	while removed:
		removed = false
		var start_size :int = landers.size()
		for i in range(0,start_size):
			if landers[start_size - i - 1].was_removed:
				landers.remove_at(start_size - i - 1)
				removed = true
				break
				
	while removed:
		removed = true
		var start_size :int = stationary_landers.size()
		for i in range(0,start_size):
			if stationary_landers[start_size - i - 1].was_removed:
				stationary_landers.remove_at(start_size - i - 1)
				removed = true
				break

func _move_finished():
	GlobalState.is_tweening_planet = false
	if running_out_tweens_count > 0:
		return
	clear_removed_landers()
	
			
	for lander in landers:
		if not lander is Lander:
			continue
		if stationary_landers.find_custom(func(v): return v and v is Lander and lander.area.overlaps_area(v.area)) != -1:
			var tween = lander.create_tween()
			lander.setBounceBack(true)
			tween.tween_property(lander,"polygon:scale",Vector2(1.4,1.4), 0.2)
			tween.finished.connect(func():lander.setBounceBack(false))
			tween.play()
			return

func timeout():
	if GlobalState.is_tweening_planet:
		return
	
	var move = total_move
	move_direction = 0
	total_move = 0
	
	if move == 0:
		return
		
	GlobalState.is_tweening_planet = true
	 
	
	_stacks_rotation = (_stacks_rotation + move + NPOINTS)%NPOINTS
	var labels = get_children().filter(func(v): return v is Label)
	for i in range(NPOINTS):
		labels[i].text = str((_stacks_rotation + i)%NPOINTS)
	
	var tween = stationary_landers_container.create_tween()
	tween.tween_property(stationary_landers_container,"rotation",stationary_landers_container.rotation + move*PI*0.25,0.09)
	tween.finished.connect(_move_finished)
	tween.play()

func _ready() -> void:
	
	
	var planet_instance = planet.instantiate()
	add_child(planet_instance)
	var half = PI/float(NPOINTS)
	for i in range(NPOINTS):
		var lbl := Label.new()
		lbl.add_theme_color_override("font_color",Color.BLACK)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var a = PI*float(i)/float(NPOINTS)*2 + half
		lbl.position = Vector2(sin(a)*110-10,cos(a)*110-10)
		lbl.text = str(i)
		lbl.z_index = 2
		
		add_child(lbl)
	timer = Timer.new()
	add_child(timer)
	timer.autostart = true
	timer.timeout.connect(timeout)
	timer.start(0.125)
	stationary_landers_container = Node2D.new()
	add_child(stationary_landers_container)
	_spawn_lander()

var total_move := 0

func _process(dt: float) -> void:
	
	
	var move = 0
	if Input.is_action_just_pressed("ui_left"):
		move = -1
	if Input.is_action_just_pressed("ui_right"):
		move = 1
	
	if move == 0:
		if Input.is_action_just_pressed("ui_up"):
			move = -1
		if Input.is_action_just_pressed("ui_down"):
			move = 1
	move_direction = move
	total_move+= move
	
	seconds_from_last_spawn+=dt
	if seconds_from_last_spawn >= SPAWN_DELAY and landers.size() <3:
		_spawn_lander()

func _on_landers_collide_area(lander:Lander):
	if GlobalState.is_tweening_planet:
		return
	if lander and lander is Lander and lander.was_removed:
		return
	if _add_to_stack(lander) == false:
		return
	lander.state = lander.LanderState.STATIONARY
	stationary_landers.append(lander)
	landers.erase(lander)
	lander.call_deferred("reparent", stationary_landers_container)

func _add_to_stack(lander:Lander):
	
	var idx:int = (_stacks_rotation + lander._rotation_idx + NPOINTS)%NPOINTS
	

	if !_stacks.has(idx):
		_stacks[idx] = []
	
	if !_stacks[idx]:
		_stacks[idx] = []
	
	if (_stacks[idx].has(lander)):
		return false
	
	if lander is Lander and lander.landed:
		return false

	_stacks[idx].append(lander)
	
	lander.landed = true
	print ("landed")
	var s = "stacks = %d  | lander = %d |  target = %d | length = %d"
	s = s % [_stacks_rotation, lander._rotation_idx, idx, _stacks[idx].size()]
	print (s)
	print ("")
	
	
	clear_removed_landers()
	
	
	var foundmatch = false
	if _stacks[idx].size() >= 3:
		var color = lander.polygon.color
		var i = _stacks[idx].size() - 1
		var c := 0
		for j in range(0, 3):
			if i - j > _stacks[idx].size():
				break
			if not _stacks[idx][i-j]:
				break
			if  not _stacks[idx][i-j] is Lander:
				break
			if _stacks[idx][i-j].was_removed:
				break
			var colorInStack :Color = _stacks[idx][i - j].polygon.color
			if colorInStack.to_html(true) == color.to_html(true):
				c+=1
				print(c, colorInStack.to_html(true), color.to_html(true))
				foundmatch = true
			else:
				foundmatch = false
				break		
		if foundmatch and c>=3:
			call_deferred("_tween_out_matched",idx)

	return true

func _erease_lander(stack_idx:int, _idx:int):
	for i in range(3):
		var lander :Lander = _stacks[stack_idx].pop_back()
		stationary_landers.erase(lander)
		landers.erase(lander)
		lander.was_removed = true
		lander.call_deferred("queue_free")
		running_out_tweens_count -= 1


func _tween_out_matched(idx:int):
	var current_stack = _stacks[idx]
	if current_stack.size()<3:
		return
	for i in range(3):
		var sidx = _stacks[idx].size() - i - 1;
		
		var tween = _stacks[idx][sidx].create_tween()
		tween.tween_property(_stacks[idx][sidx],"scale",Vector2.ZERO,0.3 + sidx * 0.1)
		running_out_tweens_count +=1
		if i ==0:
			tween.finished.connect(func(): call_deferred("_erease_lander",idx,sidx))
		
		tween.play()

func _on_lander_hit_planet(lander:Lander):
	
	if _add_to_stack(lander) == false:
		return
	stationary_landers.append(lander)
	landers.erase(lander)
	lander.reparent(stationary_landers_container)

func _spawn_lander() -> void:
	seconds_from_last_spawn = 0
	var lander = Lander.new(_on_landers_collide_area)
	lander.hit_planet.connect(_on_lander_hit_planet)
	landers.append(lander)
	add_child(lander)
