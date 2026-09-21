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
const SAVE_PATH = "user://saved_replay.json"

func message_to_json(message:Message):
	var r:Dictionary = {}
	r["t"] = message.timestamp
	r["seqno"] = message.seq_no
	r["type"] = message.type
	r["params"] = message.params
	return r
	

func save_to_json(messages):
	var path = SAVE_PATH
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(messages.map(func(v):return message_to_json(v)))
		#print(json_string)
		file.store_string(json_string)

func get_from_json(data) -> Message:
	var m = Message.new()
	m.type = int(data["type"])
	m.timestamp = int(data["t"])
	m.seq_no = int(data["seqno"])
	m.params = data["params"]
	return m
func load_from_json_text(json_string:String):
	var json = JSON.new()
	var parse_result = json.parse(json_string)		
	if parse_result == OK:			
		var data = json.get_data()
		return data
	return {}
	
func load_from_json_object(data):
	data = data.map(func(v): return get_from_json(v))
	messages = []
	messages.resize(data.size())
	var i = 0
	for m in data:
		messages[i] = m
		i+=1	
	replay()
	
func load_from_json():
	var path = SAVE_PATH;
	if not FileAccess.file_exists(path):
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		return load_from_json_text(json_string)
	return {}

func load_json() -> void:
	var data = load_from_json()
	load_from_json_object(data)

func replay():
	save_to_json(messages)
	playback_queue = messages.duplicate(true)
	playback_start_t = start_t;
	clear()
	if _input:
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
		#print (message)
		instance.on_message.emit(message)
		return
	else:
		var messages = instance.messages
		if messages.size() == 0:
			message.timestamp = Time.get_ticks_usec() - instance.start_t 
		else:
			message.timestamp = Time.get_ticks_usec () - instance.last_t
		instance.last_t = Time.get_ticks_usec()
		#print (message)
		instance.on_message.emit(message)
		instance.messages.append(message)
	

static func _connect (cb:Callable):
	if cb and cb.is_valid():
		instance.on_message.connect(cb)
