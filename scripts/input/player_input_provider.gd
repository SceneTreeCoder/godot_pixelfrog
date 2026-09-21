extends InputProvider
class_name PlayerInputProvider

func _init():
	pass


const inputMap: Dictionary[String, String] = {
	ui_left = "ui_left",
	ui_right = "ui_right",
	ui_up = "ui_left",
	ui_down = "ui_right",
	action = "action",
	escape = "escape",
	left = "ui_left",
	right = "ui_right",
	up = "ui_up",
	down = "ui_down",
}

func _input(event: InputEvent) -> void:
	var move = 0
	var message: Message;
	for k in inputMap.keys():
		if not event.is_action_pressed(k):
			continue
		message = Message.new()
		message.type = Message.MessageType.ACTION_KEY_PRESS
		message.params = {
			name = inputMap[k],
		}
		GameInput.on_message_received(message)
	
