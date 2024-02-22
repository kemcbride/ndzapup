extends Node2D

signal no_more_lives

var lights = []
var life_count = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	lights = [$Life1, $Life2, $Life3, $Life4, $Life5]
	for light in lights:
		light.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func decrement():
	if life_count > 0:
		life_count -= 1
		lights[life_count].play("dim")
		if life_count == 0:
			no_more_lives.emit()

func reset():
	life_count = 5
	for light in lights:
		light.play("default")
