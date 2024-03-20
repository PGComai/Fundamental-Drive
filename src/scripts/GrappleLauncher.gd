extends Node3D


@export var hook: RigidBody3D


var global: Node


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


func _physics_process(delta):
	if Input.is_action_just_pressed("grapple") and global.player_state == 0:
		hook.launch = true
