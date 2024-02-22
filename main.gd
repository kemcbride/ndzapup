extends Node2D

@export var grid_scene: PackedScene
var grid

enum GameState {STARTUP, PLAYING, WON, LOST}
var current_state = GameState.STARTUP

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_new_game_button_pressed():
	grid = grid_scene.instantiate()
	grid.position = Vector2(600, 100)
	add_child(grid)
	grid.game_done.connect(_on_grid_game_done)
	grid.pcell_clicked.connect(_on_pcell_clicked)
	$NewGameButton.hide()
	$YouWinButton.hide()
	$YouLoseButton.hide()
	$AudioStreamPlayer.stop()
	$LifeCounter.reset()
	current_state = GameState.PLAYING


func win_game():
	current_state = GameState.WON
	$AudioStreamPlayer.play()
	$YouWinButton.show()
	$NewGameButton.show()
	grid.queue_free()


func _on_grid_game_done():
	win_game()


func _on_life_counter_no_more_lives():
	await get_tree().create_timer(0.2).timeout
	if grid.is_pulsing:
		await grid.pulse_done
	await get_tree().create_timer(0.2).timeout
	
	if current_state == GameState.PLAYING:
		$YouLoseButton.show()
		$NewGameButton.show()
		grid.queue_free()
		current_state = GameState.LOST


func _on_pcell_clicked():
	$LifeCounter.decrement()
