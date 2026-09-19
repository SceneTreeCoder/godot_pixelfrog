extends RefCounted

class_name Message

enum MessageType {ACTION_KEY_PRESS, ACTION_KEY_DOWN, ACTION_KEY_UP}

static var _s_seq_no := 1
var type:MessageType;
var timestamp:int;
var params:Dictionary;
var _seq_no: int
var seq_no:int:
	get:
		if _seq_no <= 0:
			_seq_no = _s_seq_no
			_s_seq_no = _s_seq_no + 1
		return _seq_no
	set(v):
		pass

func _to_string() -> String:
	var s := "%d:[%d] Type: %s, %s"
	
	return s % [timestamp, seq_no, str(MessageType.keys()[type]), str(params)]
