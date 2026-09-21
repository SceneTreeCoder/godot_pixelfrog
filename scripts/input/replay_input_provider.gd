extends InputProvider
class_name ReplayInputProvider


var idx = 0
var last_timestamp = 0
var queue
var finished = false
var n:int

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		
		var json = {"params":{"name":"escape"},"seqno":78,"t":3277904,"type":0}
		var message = GameInput.instance.get_from_json(json)
		GameInput.on_message_received(message)
		json = {"params":{"name":"action"},"seqno":79,"t":3277905,"type":0}		
		message = GameInput.instance.get_from_json(json)
		GameInput.on_message_received(message)

func _ready() -> void:		
	if GameInput.instance.playback_queue.size()>0:
		last_timestamp = Time.get_ticks_usec() 
		var gi = GameInput.instance
		queue = gi.playback_queue
		finished = false
		n = queue.size()
	
func _physics_process(delta: float) -> void:
	if finished:
		return
	var message:Message = queue[idx]	
	var offsetLive:int = Time.get_ticks_usec() - last_timestamp
		
	var offsetReplay:int = message.timestamp
	if offsetLive >= offsetReplay:
		last_timestamp = Time.get_ticks_usec() - offsetLive + offsetReplay
		#last_timestamp = Time.get_ticks_usec()
		GameInput.on_message_received(message)
		idx += 1
		if idx >= n:
			finished = true
