extends Node2D
class_name Lander

const R = 540.0
const NPOINTS = 8
const PLANET_HIT_RADIUS = 148

enum LanderState {\
	FALLING,\
	STATIONARY,\
	PREVIEW,\
	MORPHING,\
}

signal hit_planet(v:Lander)
var _state:LanderState = LanderState.FALLING
var state:LanderState:
	get:
		return _state
	set(v):
		if v!=_state:
			var old = _state
			_state = v
			_on_state_changed(v, old)

	
var collision_polygon:CollisionPolygon2D
var area:Area2D
var polygon:Polygon2D
var lander:Polygon2D

var _points:PackedVector2Array = []
var is_bouncing_back = false
var _rotation_idx:int
var _stack_idx: int = -1

var was_removed := false
var landed = false
var seq_no = 0
var _a: float = 0
static var _seq_no = 1


var paused:bool = false:
	set(v):
		GlobalState.paused = v
	get:
		return GlobalState.paused

var _tween_color_to:Color
var tween_color_to:Color:
	get:
		return _tween_color_to
	set(c):
		var t:Tween = lander.create_tween()
		t.tween_property(lander,"modulate",c,0.3 + 0.04*seq_no)
		t.play()
		_tween_color_to = c

func _init(cb:Callable = func(_lander): pass, p_start:float = 0.0):
	_seq_no += 1
	seq_no = _seq_no
	lander = Polygon2D.new()
	var sizes:Array[float] = [PI*0.25, PI*0.5, PI*0.75]
	var size = randi_range(0, 0);
	var arc = sizes[size]
	var start = randi_range(0, NPOINTS);
	_rotation_idx = start
	var a = float(start) * PI * 2.0 / float(NPOINTS)
	if p_start != 0:
		a = p_start
	_a = a
	_stack_idx = -1
	
	
	var N = NPOINTS
	var step = float(arc/N)
	
		
	var calc = func calculate_points(r1,r2):
		var points_inner :PackedVector2Array = []
		points_inner.resize(2*N)
		for i in range(0,N):
			points_inner[i] = (Vector2(sin(a+step*float(i))*r1,cos(a+step*i)*r1))
		for i in range(0,N):
			points_inner[N+i]=(Vector2(sin(a+step*(N-float(i)-1))*r2,cos(a+step*(N-float(i)-1))*r2))	
		return points_inner
	
	lander.polygon = calc.call(R, R*1.1+2)
	lander.color = GlobalState.pick_color()
	area = Area2D.new()
	area.monitoring = true
	
	var cp :CollisionPolygon2D = CollisionPolygon2D.new()
	collision_polygon = cp
	cp.polygon = calc.call(R - 5, R*1.15+12)
	
	area.add_child(lander)
	area.add_child(cp)
	area.area_entered.connect(func(arr:Area2D): _hit_other(arr,cb))	
	_points = cp.polygon.duplicate()
	polygon = lander
	add_child(area)

func _on_state_changed(to:LanderState, _from:LanderState):
	match(to):
		LanderState.PREVIEW:
			collision_polygon.call_deferred("queue_free")
			collision_polygon = null
			lander.color = Color.WHITE
		LanderState.MORPHING:
			collision_polygon.call_deferred("queue_free")
			collision_polygon = null
		
func map(arr, cb:Callable):
	var ret = arr.duplicate()
	for i in range(ret.size()):
		ret[i] = cb.call(ret[i])
	return ret

func _hit_other(_arr:Area2D, cb:Callable):
	if is_bouncing_back:
		return
	cb.call(self)

func _physics_process(dt:float) -> void:
	if paused:
		return
	if GlobalState.is_game_over:
		return
	match (state):
		LanderState.FALLING:
			_process_falling(dt)
		LanderState.STATIONARY:
			_process_stationary(dt)
		LanderState.PREVIEW:
			_process_preview(dt)

func _process_stationary(_dt:float):
	pass

func _process_preview(_dt:float):
	var current_scale = 0.15 + (float(0.25))
	lander.set_deferred("scale", Vector2(current_scale, current_scale))
	lander.set_deferred("rotation", seq_no*PI*0.29+0.08+sin(_a)*0.25)
	_a += 0.01


func setBounceBack(v:bool):
	area.monitoring = !v
	area.monitorable = !v
	is_bouncing_back = v

func _process_falling(dt:float):
	if is_bouncing_back or GlobalState.is_game_over:
		return
	var current_scale = polygon.scale.x - 0.32*dt
	
	if GlobalState.is_tweening_planet:
		current_scale = polygon.scale.x + 0.75*dt
	var currentR = R * current_scale
	polygon.set_deferred("scale", Vector2(current_scale, current_scale))
	var f = func(v):
		v*=current_scale
		return v
	var new_points = map(_points, f)
	collision_polygon.polygon = new_points
	if currentR <= PLANET_HIT_RADIUS:
		state = LanderState.STATIONARY
		hit_planet.emit(self)
