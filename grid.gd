extends Node2D

signal pulse_done
signal all_green
signal game_done
signal pcell_clicked

@export var pcell_scene: PackedScene
@export var pseg_scene: PackedScene

var pcells = []
var segments = {}
var WIDTH = 6
var HEIGHT = 5
var PAD_X = 0  # 600
var PAD_Y = 0  # 100
var PSEG_LENGTH = 260
var is_pulsing = false
var inputs_disabled = false
var all_cells_green = false
var ongoing_pulses = []  # counts the number of ongoing pulses, when it's at 0
# we know that it's done pulsing (pulse_done)
var ticker_toggle = true


func create_pcell_in_grid(x, y):
	var pc = pcell_scene.instantiate()
	# TODO add comment explaining why 580, lmao.
	# Path segment length + 100 (for each edge) + 20 (10px buffer on each side?)
	
	pc.position = Vector2(PAD_X + PSEG_LENGTH * x, PAD_Y + PSEG_LENGTH * y)
	pc.x = x
	pc.y = y
	add_child(pc)
	return pc


func create_pseg_in_grid(x1, y1, x2, y2):
	var ps = pseg_scene.instantiate()
	var hbuf = 0
	var vbuf = 0
	if not x1 == x2:
		# Then it's a horizontal line. Else no need to set rotation
		ps.rotation = PI * 3.0 / 2.0
		hbuf = 50 + 20 # yes, 70, but phrased as its sum. 20 = 10px buf each
		# and 50 = half of the shape's size distance. (100) times 2 ofc.
	else:
		vbuf = 50 + 20
	var pseg_pos_x = PAD_X + hbuf + PSEG_LENGTH * x1
	var pseg_pos_y = PAD_Y + vbuf + PSEG_LENGTH * y1
	ps.position = Vector2(pseg_pos_x, pseg_pos_y)
	add_child(ps)
	return ps


# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize the grid of pcells & path segments
	for x in WIDTH:
		var row_array = []
		for y in HEIGHT:
			row_array.append(
				create_pcell_in_grid(x, y)
			)
		pcells.append(row_array)

	# Now how am I gonna initialize these dang path segments...
	# Generate horizontal ones first
	# well, we'll work it out. if this is vertical i'll figure it out.
	for x in WIDTH:
		# horizontal ones have rotation 270
		for y in (HEIGHT - 1):
			var segname = str(x) + str(y) + str(x) + str(y+1)
			print(segname)
			var pseg = create_pseg_in_grid(x, y, x, y+1)
			segments[segname] = pseg
	
	for x in (WIDTH - 1):
		for y in HEIGHT:
			var segname = str(x) + str(y) + str(x+1) + str(y)
			print(segname)
			if segname in segments.keys():
				print(segname, " found in ", segments)
				continue
			var pseg = create_pseg_in_grid(x, y, x+1, y)
			segments[segname] = pseg
	print(segments)
	
	# Set up signals for pulses.
	for x in range(pcells.size()):
		for y in range(pcells[0].size()):
			pcells[x][y].pulsed.connect(_on_pcell_pulsed)
			pcells[x][y].clicked.connect(_on_pcell_clicked)
			
	prepare_to_send_win_signal()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ongoing_pulses.size() == 0 and inputs_disabled:
		is_pulsing = false
		pulse_done.emit()
		enable_all_inputs()
	
	if all_pcells_green():
		all_green.emit()
		all_cells_green = true

func all_pcells_green():
	for row in pcells:
		for pcell in row:
			if pcell.state != 3:
				return false
	return true
	
func get_adjacent_pcells(x, y):
	var adj_pcells = []
	# So there could be up to 4 adjacent ones: up, down, left, right.
	# Unfortunately we just have to check for them all :(
	if y > 0:
		adj_pcells.append(pcells[x][y-1])
	if y < pcells[0].size() - 1:
		adj_pcells.append(pcells[x][y+1])
	if x > 0:
		adj_pcells.append(pcells[x-1][y])
	if x < pcells.size() - 1:
		adj_pcells.append(pcells[x+1][y])
	return adj_pcells
	
	
func get_pseg(x, y, x1, y1):
	# Determining the order for the keys, basically, to fetch the pseg.
	var pseg_name = str(x1) + str(y1) + str(x) + str(y)
	if ((x1 > x) or (y1 > y)):
		pseg_name = str(x) + str(y) + str(x1) + str(y1)
	return segments[pseg_name]
	
	
func get_adjacent_segments_w_orientation(x, y):
	var adj_segments_w_reverse = []
	var src_cell_str = str(x) + str(y)
	# We have to be really wary of the keys here - particularly that I ordered
	# the dict such that it's smaller magnitude cell first, then greater second.
	# So you can't just do src + dst when it comes to the string key.
	
	# Get vertical segment neighbors
	if y > 0:
		var dst_cell_str = str(x) + str(y-1)
		adj_segments_w_reverse.append([segments[dst_cell_str + src_cell_str], true])
	if y < pcells[0].size() - 1:
		var dst_cell_str = str(x) + str(y+1)
		adj_segments_w_reverse.append([segments[src_cell_str + dst_cell_str], false])
	
	# Now horizontal segment neighbors
	if x > 0:
		var dst_cell_str = str(x-1) + str(y)
		adj_segments_w_reverse.append([segments[dst_cell_str + src_cell_str], true])
	if x < pcells.size() -1:
		var dst_cell_str = str(x+1) + str(y)
		adj_segments_w_reverse.append([segments[src_cell_str + dst_cell_str], false])
		
	return adj_segments_w_reverse


func disable_all_inputs():
	inputs_disabled = true
	for row in pcells:
		for pcell in row:
			pcell.disable_input()


func enable_all_inputs():
	inputs_disabled = false
	for row in pcells:
		for pcell in row:
			pcell.enable_input()


func prepare_to_send_win_signal():
	await all_green
	# How can we handle a case where all are green and also pulse done finishes at same time? Does it ever happen?
	# when is a case when a blue turns green, and no pulses go out? TBH...
	await pulse_done
	game_done.emit()


func green_bump(x, y, x1, y1):
	ongoing_pulses.append(1)
	# x, y are the coordinates of the source bump for this greenbump (so we can tell dir)
	# x1, y1 are the destination of the green bump. The coords of the greenie getting green bumped
	#return
	var pc1 = pcells[x1][y1]
	pc1.flash()
	await pc1.flashed
	var vertical = x == x1
	var positive = (x1 > x) or (y1 > y)
	# For a green bump, we want to pass through to its path_segment, fire that off,
	# and then make either a bump or green_bump call to the next pcell on the path.
	var x2 = x1 if vertical else x1 + (x1 - x)
	var y2 = y1 if not vertical else y1 + (y1 - y)
	if x2 < 0 or x2 > pcells.size()-1 or y2 < 0 or y2 > pcells[0].size() -1:
		# IF WERE GONNA RETURN EARLY WE MUST MUST MUST clean up our ongoing pulse
		ongoing_pulses.remove_at(0)
		return
	
	var pseg = get_pseg(x1, y1, x2, y2)
	pseg.glow_path($GridTimer, not positive)
	await $GridTimer.timeout
	await $GridTimer.timeout
	await $GridTimer.timeout

	var next_cell = pcells[x2][y2]
	if next_cell.state == 3: # green again?? green bump it
		green_bump(x1, y1, x2, y2)
	else:
		ongoing_pulses.append(1)
		pcells[x2][y2].bump()
		ongoing_pulses.remove_at(0)
		
	ongoing_pulses.remove_at(0)


func _on_pcell_pulsed(x, y):
	is_pulsing = true
	disable_all_inputs()
	ongoing_pulses.append(1)
	# synchronize with the green bumps by waiting for this cell to flash.
	pcells[x][y].flash()
	# Note: Hopefully, by using a gridtimer with the same duration as the animations (2 frames of 5 fps = 0.4s)
	# we can have synchronized animations across the whole grid.
	#await pcells[x][y].flashed
	await $GridTimer.timeout
	
	var segments_w_orientation = get_adjacent_segments_w_orientation(x, y)
	for arr in segments_w_orientation:
		var seg = arr[0]
		var orientation = arr[1]
		seg.glow_path($GridTimer, orientation)
	
	# Note: Wait for 3 ticks of GridTimer, aka for each cell in a path segment
	await $GridTimer.timeout
	await $GridTimer.timeout
	await $GridTimer.timeout
	
	var adj_pcells = get_adjacent_pcells(x, y)

	for pcell in adj_pcells:
		# I could handle green bumps here, actually, and I have the context of the direction here, too.
		if pcell.state != 3: # aka not yet green, do a normal bump
			ongoing_pulses.append(1)
			pcell.bump()
			ongoing_pulses.remove_at(0)
		else:
			green_bump(x, y, pcell.x, pcell.y)
	
	ongoing_pulses.remove_at(0)


func _on_pcell_clicked():
	pcell_clicked.emit()


func _on_grid_timer_timeout():
	if ticker_toggle:
		$TimerTicker.play()
		ticker_toggle = false
	else:
		ticker_toggle = true
