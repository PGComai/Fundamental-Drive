extends GridMap


var update := false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_car_position_signal(pos: Vector3):
	if update:
		var nearest_cell = Vector3i(pos.snapped(Vector3(200.0, 2.0, 200.0))) / 200
		nearest_cell.y = 0
		for x in range(-3, 4):
			for z in range(-3, 4):
				var cell_pos = Vector3i(nearest_cell.x + x, 0.0, nearest_cell.z + z)
				set_cell_item(cell_pos, 0)
		update = false


func _on_timer_timeout():
	update = true
