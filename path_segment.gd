extends Node2D

signal path_glowed
var cells = []
var is_glowing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	cells = [$PathCell1, $PathCell2, $PathCell3]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Commented out, because I was using it for testing and we don't need it in the game.
#func _on_area_2d_input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton && event.pressed:
		#glow_path()

func glow_path(grid_timer, reverse=false):
	is_glowing = true
	var path_range = range(cells.size() - 1 , -1, -1) if reverse else range(cells.size())
	for i in path_range:
		cells[i].flash()
		await grid_timer.timeout
	path_glowed.emit()
	is_glowing = false

func is_playing():
	return is_glowing
