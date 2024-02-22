extends AnimatedSprite2D

signal flashed

# Called when the node enters the scene tree for the first time.
func _ready():
	play("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func flash():
	play("lit")
	$AudioStreamPlayer.play()
	await animation_finished
	flashed.emit()
