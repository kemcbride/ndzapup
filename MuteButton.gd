extends Button


var music_bus = AudioServer.get_bus_index("Master")

func _toggled(toggled_on):
	AudioServer.set_bus_mute(music_bus, toggled_on)
