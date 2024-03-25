extends HBoxContainer
class_name HBoxVector

@export var vec: Vector3 = Vector3.ZERO:
	set(value):
		vec = value
		_set_vec()

@onready var label_x_val = $LabelXVal
@onready var label_y_val = $LabelYVal
@onready var label_z_val = $LabelZVal

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _set_vec():
	if label_x_val and label_y_val and label_z_val:
		label_x_val.text = str(snappedf(vec.x, 0.1))
		if vec.x >= 0.0:
			label_x_val.text = " " + label_x_val.text
		if not label_x_val.text.contains("."):
			label_x_val.text += ".0"
		
		label_y_val.text = str(snappedf(vec.y, 0.1))
		if vec.y >= 0.0:
			label_y_val.text = " " + label_y_val.text
		if not label_y_val.text.contains("."):
			label_y_val.text += ".0"
		
		label_z_val.text = str(snappedf(vec.z, 0.1))
		if vec.z >= 0.0:
			label_z_val.text = " " + label_z_val.text
		if not label_z_val.text.contains("."):
			label_z_val.text += ".0"
