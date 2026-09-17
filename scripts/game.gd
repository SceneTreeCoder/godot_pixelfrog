extends Node2D

const planet = preload("res://scenes/planet.tscn")

var seconds_from_last_spawn := 0.0

const R = 420.0
const NPOINTS = 8
const POINTSROTATE = NPOINTS - 1

const SPAWN_DELAY:float = 3.5

var stationary_landers_container: Node2D
var moving_landers_container: Node2D
var total_move := 0
var canvas:CanvasLayer;
var paused:bool = false:
	set(v):
		GlobalState.paused = v
	get:
		return GlobalState.paused
 
var landers: Array[Lander]:
	get:
		return moving_landers_container.get_children().filter(func(v): return v is Lander)
	set(v):
		pass


var stationary_landers :Array[Lander]:
	get:
		return stationary_landers_container.get_children().filter(func(v): return v is Lander)
	set(v):
		pass

var _stacks_rotation :int = 0
var timer:Timer = null
var move_direction: int
var running_out_tweens_count = 0
var was_combo = false

func clear_removed_landers():
	pass

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
	#var labels = get_children().filter(func(v): return v is Label)
	#for i in range(NPOINTS):
	#	labels[i].text = str((_stacks_rotation + i)%NPOINTS)
	
	var tween = stationary_landers_container.create_tween()
	tween.tween_property(stationary_landers_container,"rotation",stationary_landers_container.rotation + move*PI*0.25,0.09)
	tween.finished.connect(_move_finished)
	tween.play()

func _ready() -> void:
	var planet_instance = planet.instantiate()
	add_child(planet_instance)	
	timer = Timer.new()
	add_child(timer)
	timer.autostart = true
	timer.timeout.connect(timeout)
	timer.start(0.125)
	stationary_landers_container = Node2D.new()
	add_child(stationary_landers_container)
	
	moving_landers_container = Node2D.new()
	add_child(moving_landers_container)
	
	canvas = CanvasLayer.new()
	var next_color_lander:Array[Lander] = []
	next_color_lander.resize(GlobalState.COLORS_QUEUE_SIZE)
	
	for i in range(next_color_lander.size()):
		var lander = Lander.new(func(_lander): pass, 0.01 + float(i)/GlobalState.COLORS_QUEUE_SIZE*PI*2.0)
		lander.state = Lander.LanderState.PREVIEW
		lander.position = Vector2(180, 180)
		next_color_lander[i] = lander
		canvas.add_child(lander)
	
	GlobalState.instance.next_color_changed.connect(func(colors): for j in range(GlobalState.COLORS_QUEUE_SIZE): next_color_lander[GlobalState.COLORS_QUEUE_SIZE-j-1].tween_color_to = colors[j])
	
	
	add_child(canvas)
	
	
	_spawn_lander()

func _process(dt: float) -> void:
	
	if Input.is_action_just_pressed("action"):
		paused = !paused;
	
	if GlobalState.is_game_over:
		if Input.is_action_just_pressed("action"):
			var res = load("res://scenes/game.tscn")
			var parent = get_parent()
			var gs:GlobalState = GlobalState.instance;
			for c in gs.next_color_changed.get_connections():
				gs.next_color_changed.disconnect(c["callable"])
			
			
			queue_free()
			var timergs := Timer.new()
			timergs.one_shot = true
			var resetf = func():
				GlobalState.reset()
				parent.add_child(res.instantiate())
			
			timergs.timeout.connect(resetf.bind())
			parent.add_child(timergs)
			timergs.start(0.1)
			
		return
		
	if paused:
		return
	
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
	if lander.state != Lander.LanderState.FALLING:
		return
	
	lander.state = lander.LanderState.STATIONARY
	
	if _add_to_stack(lander) == false:
		return
	lander.call_deferred("reparent", stationary_landers_container)
	_spawn_lander()
	

func _add_to_stack(lander:Lander):
	
	var idx:int = (_stacks_rotation + lander._rotation_idx + NPOINTS)%NPOINTS
	
	lander._stack_idx = idx
	
	var on_this_stack = stationary_landers.filter(func(a):\
		return a._stack_idx == idx\
	).size()
	
	if on_this_stack and on_this_stack > 7:
		show_game_over()
	
	lander.landed = true
	lander.state = Lander.LanderState.STATIONARY
	
	var stack = stationary_landers.filter(func(v:Lander): return v._stack_idx == idx and v.state == Lander.LanderState.STATIONARY)
	var seq_no :int = lander.seq_no
	if stack.find_custom(func(v:Lander): return v.seq_no == seq_no) < 0:
		stack.append(lander)
	if not lander in stack:
		stack.append(lander)
	
	var foundmatch = false
	if stack.size() >= 3:
		var color = lander.polygon.color
		var html_color = color.to_html(true)
		var i = stack.size() - 1
		var c := 0
		for j in range(0, 3):
			if i - j < 0 or i - j >= stack.size():
				break
			var colorInStack:Color = stack[i-j].polygon.color
			if colorInStack.to_html(true) == html_color:
				c+=1
				foundmatch = true
			else:
				foundmatch = false
				break
		if foundmatch and c>=3:
			call_deferred("_tween_out_matched",lander._stack_idx, lander.seq_no)
	return true

func _tween_out_matched(idx:int, seq_no:int):
	var delay_timer = Timer.new()
	add_child(delay_timer)
	delay_timer.one_shot = true
	delay_timer.timeout.connect(func():_tween_out_matched_delayed(idx, delay_timer, seq_no))
	delay_timer.start(0.1)

func _get_lander_by_seq_no(seq_no:int) -> Lander:

	var idx:int = stationary_landers.find_custom(func(v:Lander):return v.seq_no == seq_no)
	if (idx>=0):
		return stationary_landers[idx]
	idx = landers.find_custom(func(v:Lander):return v.seq_no == seq_no)
	if (idx>=0):
		return landers[idx]
	return null
	

func _tween_out_matched_delayed(idx:int, ptimer:Timer, seq_no:int):
	ptimer.queue_free()
	
	var originlander = _get_lander_by_seq_no(seq_no)
	
	var stack = stationary_landers.filter(func(v:Lander): return v._stack_idx == idx)
	if stack.find_custom(func(v:Lander): return v.seq_no == seq_no) < 0:
		stack.append(originlander)
	if stack.size()<3:
		return
	var sidx = stack.size()-1
	for i in range(3):		
		var lander:Lander = stack[sidx]
		var tween:Tween = lander.create_tween()
		tween.tween_property(lander,"scale",Vector2.ZERO,0.3 + (sidx) * 0.1)		
		tween.play()
		tween.finished.connect(func():lander.queue_free())
		sidx -= 1

func _on_lander_hit_planet(lander:Lander):
	lander.call_deferred("reparent",stationary_landers_container)
	if _add_to_stack(lander) == false:
		return
	_spawn_lander()

func show_game_over() -> void:
	
	GlobalState.is_game_over = true
	var panel = Panel.new()
	
	panel.grow_horizontal = Control.GrowDirection.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GrowDirection.GROW_DIRECTION_BOTH
	panel.size = Vector2(320,200)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE, 20)
	var game_over_label := Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.size = panel.size * 1
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE, 20)
	
	panel.add_child(game_over_label)	
	canvas.add_child(panel)

func _spawn_lander() -> void:
	if GlobalState.is_game_over:
		return
	var n_falling_landers = landers.size()
	if n_falling_landers > 1:
		return
	if n_falling_landers + stationary_landers.size() > GlobalState.MAX_SHAPES:
		show_game_over()
		return
	seconds_from_last_spawn = 0
	var lander = Lander.new(_on_landers_collide_area)
	lander.hit_planet.connect(_on_lander_hit_planet)
	moving_landers_container.call_deferred("add_child", lander)
	
	
	
