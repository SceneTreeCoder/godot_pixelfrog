extends Node

class_name GameInput

var _input:InputProvider
@export var input:InputProvider:
	set(v):
		if _input != null:
			_input.queue_free()
			_input = null
		
		if _input == null:
			_input = v
			add_child(_input)
		
var messages:Array[Message]
var playback_queue:Array[Message]
var start_t := 0
var playback_start_t := 0
var last_t :int = 0
static var _instance:GameInput;
static var instance:GameInput:
	get:
		if _instance == null:
			_instance = new()
		return _instance
	set(v):
		return

signal on_message(message:Message)

func replay():
	playback_queue = messages.duplicate(true)
	playback_start_t = start_t;
	clear()
	_input.queue_free()
	_input = null
	_input = ReplayInputProvider.new()
	add_child(_input)

func record():
	playback_queue.clear()
	clear()
	start_t = Time.get_ticks_usec()
	_input.queue_free()
	_input = null
	_input = PlayerInputProvider.new()
	add_child(_input)
	
func clear():
	messages.clear()
	
static func on_message_received(message:Message):	
	
	if instance.playback_queue.size() > 0:
		print (message)
		instance.on_message.emit(message)
		return
	else:
		var messages = instance.messages
		if messages.size() == 0:
			message.timestamp = Time.get_ticks_usec() - instance.start_t 
		else:
			message.timestamp = Time.get_ticks_usec () - instance.last_t
		instance.last_t = Time.get_ticks_usec()
		print (message)
		instance.on_message.emit(message)
		instance.messages.append(message)
	

static func _connect (cb:Callable):
	if cb and cb.is_valid():
		instance.on_message.connect(cb)
