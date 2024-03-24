extends Node


const PLAYER_STATES = ["Driving", "Building", "Selecting", "Editing", "Browsing"]


signal player_state_changed(state: String)
signal show_reticle(status: bool)


var player_state: int = 0:
	set(value):
		player_state = value
		emit_signal("player_state_changed", PLAYER_STATES[player_state])
		print("player state changed: %s" % PLAYER_STATES[player_state])
var player_has_object_selected := false
var player_is_editing_object := false
var player_needs_reticle := false:
	set(value):
		player_needs_reticle = value
		emit_signal("show_reticle", player_needs_reticle)

var sub_v: SubViewport


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
