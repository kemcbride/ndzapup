extends Node2D

signal pulsed(x, y)
signal flashed
signal clicked

@export var state = 0
@export var x = 0
@export var y = 0

var has_pulsed = false
var states = ["red", "yellow", "blue", "green"]
var boops = []


# Called when the node enters the scene tree for the first time.
func _ready():
	boops = [$RedBoop, $YellowBoop, $BlueBoop, $GreenBoop]
	state = randi() % 100
	if state > 80:
		state = 2
	elif state < 80 and state > 40:
		state = 1
	else:
		state = 0

	var state_anim = states[state % states.size()]
	$AnimatedSprite2D.play(state_anim)
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var state_anim = states[state % states.size()]
	if state_anim == "green" and not has_pulsed:
		pulsed.emit(x, y)
		has_pulsed = true
	
	# This makes sure they actually flash for the right amount of time.
	# How bright teh flash is, well we'd need to redo the assets for flashes.
	if state_anim+"_flash" == $AnimatedSprite2D.get_animation():
		if not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.play(state_anim)


func _on_area_2d_input_event(viewport, event, shape_idx):
	# When the cell is clicked, bump it to the next state. Unless it's already green.
	if event is InputEventMouseButton && event.pressed:
		bump()
		clicked.emit()


func bump():
	# I want to debounce bumps - only bump the state if it's not already being bumped, 
	# you know? If two bumps hit at the same time, it should only increment once.
	if state < (states.size() - 1) and not $AnimatedSprite2D.is_playing():
		state += 1
	boops[state].play()

	# Should be most easily discernable for Green, which doesn't include a state change.
	$AnimatedSprite2D.play(states[state] + "_flash")
	
	
func flash():
	$AnimatedSprite2D.play(states[state] + "_flash")
	boops[state].play()
	await $AnimatedSprite2D.animation_finished
	flashed.emit()


func is_playing():
	return $AnimatedSprite2D.is_playing()


func enable_input():
	$Area2D/CollisionShape2D.disabled = false


func disable_input():
	$Area2D/CollisionShape2D.disabled = true
