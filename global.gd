extends Node

# Declare a custom signal that passes the counter value
signal counter_changed(value)

# A global variable to hold the counter
var button_press_count = 0

func increment_counter():
	button_press_count += 1
	# Print the value to the console to verify it works
	print("Button pressed! Current count: ", button_press_count)
	# Emit the custom signal, sending the new value
	counter_changed.emit(button_press_count)
