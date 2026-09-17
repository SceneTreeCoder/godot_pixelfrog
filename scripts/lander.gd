extends Node2D
class_name Lander

const R = 540.0
const NPOINTS = 8

enum LanderState { FALLING, STATIONARY}

signal hit_planet(v:Lander)

var state:LanderState = LanderState.FALLING
var collision_polygon:CollisionPolygon2D
var area:Area2D
var polygon:Polygon2D
var lander:Polygon2D

var _points:PackedVector2Array = []
var is_bouncing_back = false
var _rotation_idx:int
var was_removed := false

var landed = false

func _exit_tree() -> void:
	was_removed = true
func _enter_tree() -> void:
	was_removed = false


func _init(cb:Callable):
	lander = Polygon2D.new()
	var sizes:Array[float] = [PI*0.25, PI*0.5, PI*0.75]
	var size = randi_range(0, 0);
	var arc = sizes[size]
	var start = randi_range(0, NPOINTS);
	_rotation_idx = start
	var a = float(start) * PI * 2.0 / float(NPOINTS)

	
	
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
	
	lander.polygon = calc.call(R,R*1.1+2)
	lander.color = [Color.GREEN, Color.BLUE, Color.RED].pick_random()
	area = Area2D.new()
	area.monitoring = true
	
	var cp :CollisionPolygon2D = CollisionPolygon2D.new()
	collision_polygon = cp
	cp.polygon = calc.call(R - 5,R*1.15+12)
	
	area.add_child(lander)
	area.add_child(cp)
	area.area_entered.connect(func(arr:Area2D): _hit_other(arr,cb))
	#area.area_shape_entered.connect(_on_landers_collide)	
	_points = cp.polygon.duplicate()
	
	polygon = lander
	
	add_child(area)

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
	
	match (state):
		LanderState.FALLING:
			_process_falling(dt)
		LanderState.STATIONARY:
			_process_stationary(dt)

func _process_stationary(_dt:float):
	pass

func setBounceBack(v:bool):
	is_bouncing_back = v

func _process_falling(dt:float):
	if is_bouncing_back:
		return
	var current_scale = polygon.scale.x - 0.5*dt
	
	if GlobalState.is_tweening_planet:
		current_scale = polygon.scale.x + 0.75*dt
	
	var currentR = R * current_scale
	
	polygon.set_deferred("scale", Vector2(current_scale, current_scale))
	var f = func(v):
		v*=current_scale
		return v
	var new_points = map(_points, f)
	collision_polygon.polygon = new_points
	if currentR <= 140:
		state = LanderState.STATIONARY
		hit_planet.emit(self)
