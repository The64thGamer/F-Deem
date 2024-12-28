extends Node

func _input(event):
	if event.is_action_pressed("Console"):
		# Navigate to the Console Window node
		var console_window = get_tree().root.get_node("Console/ConsoleWindow")
		
		if console_window:
			# Toggle visibility
			console_window.visible = not console_window.visible
		else:
			print("Console Window node not found!")
