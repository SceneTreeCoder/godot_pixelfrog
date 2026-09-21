extends Node
class_name GlobalState
const MAX_SHAPES:int = 25
const NPOINTS = Game.NPOINTS

const COLORS:Array[Color] = [\
	Color.GREEN, Color.BLUE, Color.RED, Color.GOLD, Color.AQUA, Color.CHOCOLATE, Color.DARK_SLATE_GRAY
]
const COLORS_QUEUE_SIZE = 1
static var colors_queue:Array[Color] = []
static var rotate_idx_queue:Array[int] = []

static var is_tweening_planet := false

signal next_color_changed(c:Array[Color])
static var in_on_color_chabge :bool = false
static var _instance:GlobalState
static var _last_color:Color;

static var instance:
	get:
		if _instance == null:
			_instance = GlobalState.new()
		return _instance
	set(v):
		pass

static func reset():
	
	_instance.queue_free()
	_instance = GlobalState.new()
	colors_queue = []
	rotate_idx_queue = []
	paused = false
	is_game_over = false
	is_tweening_planet = false
	Lander._seq_no = 1

static func fill_color_que():
	while colors_queue.size()<COLORS_QUEUE_SIZE:
		colors_queue.append(COLORS.pick_random())
		rotate_idx_queue.append(randi_range(0, NPOINTS-1))

static func pick_color_and_r_idx():
	if in_on_color_chabge:
		return _last_color
	fill_color_que()
	var r_color = colors_queue.pop_front()
	var r_idx = rotate_idx_queue.pop_front()
	_last_color = r_color
	fill_color_que()
	instance.next_color_changed.emit(colors_queue, rotate_idx_queue)
	return [r_color, r_idx]

static var paused := false
static var is_game_over := false
