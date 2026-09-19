extends InputProvider
class_name ReplayInputProvider

var timer = Timer.new()
func _init():
	pass

var t :int = 0
var idx = 0
var timestamp:int = 0
var last_timestamp = 0

func _ready() -> void:		
	if GameInput.instance.playback_queue.size()>0:		
		t = GameInput.instance.playback_queue[0].timestamp
		last_timestamp = Time.get_ticks_usec() 
	
func _process(delta: float) -> void:
	if GameInput.instance.playback_queue.size()<=0:
		return
	var gi = GameInput.instance
	var queue = gi.playback_queue
	if idx >= queue.size():
		return
	var message:Message = queue[idx]
	var timestamp = Time.get_ticks_usec()
	var offsetLive:int = timestamp - last_timestamp
		
	var offsetReplay:int = message.timestamp
	if offsetLive >= offsetReplay:
		if message:
			GameInput.on_message_received(message)
		idx += 1
		if idx >= queue.size():
			return		
		timestamp = Time.get_ticks_usec()
		message = queue[idx]
		offsetLive = timestamp - last_timestamp 
		last_timestamp = timestamp
		offsetReplay = message.timestamp
		
