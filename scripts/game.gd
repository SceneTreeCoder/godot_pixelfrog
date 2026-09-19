extends Node2D

const planet = preload("res://scenes/planet.tscn")

var seconds_from_last_spawn := 0.0
const SPAWN_AFTER_SECONDS = 2.5
var next_color_lander:Array[Lander] = []

const R = 420.0
const NPOINTS = 8
const POINTSROTATE = NPOINTS - 1

const MAX_SHAPES_PER_STACK := 6
const SPAWN_DELAY:float = 3.5

var stationary_landers_container: Node2D
var moving_landers_container: Node2D
var total_move := 0
var canvas:CanvasLayer;

var _seed := 0

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
	
	var tween = stationary_landers_container.create_tween()
	tween.tween_property(stationary_landers_container,"rotation",stationary_landers_container.rotation + move*PI*0.25,0.09)
	tween.finished.connect(_move_finished)
	tween.play()

func _ready() -> void:
	
	var gi = GameInput.instance;
	if not gi.is_inside_tree():		
		get_parent().add_child.call_deferred(gi)
		gi.input = PlayerInputProvider.new()
	
	if _seed == 0:
		_seed = 1906948001 #randi()
	
	seed(_seed)
	
	if gi.start_t == 0:
		gi.start_t = Time.get_ticks_usec()
	
	gi.on_message.connect(_process_input)
	var planet_instance = planet.instantiate()
	add_child(planet_instance)
	
	#var planet_container: Node2D = Node2D.new()
	#var poly = Polygon2D.new()
	#var harmonics = Harmonics.generate_harmonic_properties(20)
	#poly.polygon = Harmonics.generate_organic_shape_points(harmonics, 110)
	#planet_container.add_child(poly)
	#poly = Polygon2D.new()
	#poly.polygon = Harmonics.generate_organic_shape_points(harmonics, 90)
	#poly.color = Color.LIGHT_GRAY
	#planet_container.add_child(poly)
	#add_child(planet_container)
	##var tween:Tween = planet_container.create_tween()
	##var fCbFinished = func():		
		##var new_scale = Vector2.ONE
		##if planet_container.scale.x<=0.99:
			##new_scale = new_scale * 1.05		
		##tween.stop()		
		##tween.tween_property(planet_container,"scale", new_scale, 1)
		##tween.play()
	##
		#
	#var newScale = planet_container.scale.x * 1.05
	#tween.tween_property(planet_container,"scale", planet_container.scale*newScale,1)	
	#tween.play()
	#tween.finished.connect(fCbFinished)
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
	var n_segments = NPOINTS
	next_color_lander.resize(GlobalState.COLORS_QUEUE_SIZE*n_segments)
	
	for i in range(next_color_lander.size()):
		var lander = Lander.new(func(_lander): pass, 0.01 + float(i)/GlobalState.COLORS_QUEUE_SIZE*PI*2.0)
		lander.state = Lander.LanderState.PREVIEW
		lander.position = Vector2(320,320)
		next_color_lander[i] = lander
		canvas.add_child(lander)
	
	var on_color_change = func (colors):
		if GlobalState.in_on_color_chabge:
			return
		GlobalState.in_on_color_chabge = true
		
		for j in range(GlobalState.COLORS_QUEUE_SIZE):
			for p in range(n_segments):
				next_color_lander[j*n_segments+p-1].tween_color_to = colors[j]
		
		GlobalState.in_on_color_chabge = false
		
	
	GlobalState.instance.next_color_changed.connect(on_color_change.bind())
	
	
	add_child(canvas)
	
	var ww:= 800.0
	var hh:= 200.0
	var inner = HudPanel.new(ww,hh, Color.BLACK)
	var outer = HudPanel.new(ww*1.1,hh*1.2,Color.BROWN)
	
	#add_child(outer)
	#add_child(inner)
	
	
	inner.position += Vector2(ww*0.1 + hh*0.05,hh*0.1)
	
	inner.position += Vector2(-250,-250)
	outer.position += Vector2(-250,-250)
	_spawn_lander()

func _process(dt: float) -> void:
	if paused:
		return	
	seconds_from_last_spawn+=dt
	
	var part_time = SPAWN_AFTER_SECONDS / NPOINTS
	
	for i in range(0, NPOINTS):
		next_color_lander[i].visible = seconds_from_last_spawn >= part_time*float(i)
	
	if seconds_from_last_spawn >= SPAWN_AFTER_SECONDS and landers.size() <3:
		_spawn_lander()

func _process_input(...messages:Array):
	
	var move := 0
	for message in messages:
		var m:Message=message
		
		match(m.type):
			Message.MessageType.ACTION_KEY_PRESS:				
				match(m.params['name']):
					"ui_right":
						move += 1
					"ui_down":
						move += 1
					"ui_left":
						move -= 1
					"ui_up":
						move -= 1
					"escape":
						show_game_over()
					"action":
						if GlobalState.is_game_over:
							paused = false
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
								if (GameInput.instance.messages.size()>0):
									GameInput.instance.replay ()
								else:
									GameInput.instance.record ()
							
							timergs.timeout.connect(resetf.bind())
							parent.add_child(timergs)
							timergs.start(0.1)
						else:
							paused = !paused;
	
							
					_:
						print (m)
			_:
				print (m)
	if GlobalState.is_game_over or paused:
		return
	total_move += move

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
	
	if on_this_stack and on_this_stack > MAX_SHAPES_PER_STACK:
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
	if GlobalState.is_game_over:
		return
			
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
	
	
	
