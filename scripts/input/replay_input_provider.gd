extends InputProvider
class_name ReplayInputProvider

var timer = Timer.new()
func _init():
	pass

var t :int = 0
var idx = 0
var timestamp:int = 0
var last_timestamp = 0
var last_message_timestamp = 0

func _ready() -> void:		
	if GameInput.instance.playback_queue.size()>0:		
		t = GameInput.instance.playback_queue[0].timestamp
		last_timestamp = Time.get_unix_time_from_system()
		last_message_timestamp = GameInput.instance.playback_start_t
	
func _process(delta: float) -> void:
	if GameInput.instance.playback_queue.size()<=0:
		return
	var gi = GameInput.instance
	var queue = gi.playback_queue
	if idx >= queue.size():
		return
	var message :Message = queue[idx]
	var timestamp = Time.get_unix_time_from_system()
	var offsetLive:int = timestamp - last_timestamp
	
	var offsetReplay:int = message.timestamp - last_message_timestamp
	if offsetLive >= offsetReplay:
		if message:
			GameInput.on_message_received(message)
		idx += 1
		
		if idx >= queue.size():
			return		
		timestamp = Time.get_unix_time_from_system()
		message = queue[idx]
		offsetLive = timestamp - last_timestamp
		offsetReplay = message.timestamp - last_message_timestamp
		
