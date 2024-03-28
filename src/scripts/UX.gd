extends Control

signal build_time(toggle: bool)

const RES_OPTIONS = [Vector2i(1280, 720),
					Vector2i(1920, 1080),
					Vector2i(2560, 1440)]
const WIN_OPTIONS = [DisplayServer.WINDOW_MODE_WINDOWED,
					DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
const FISHEYE_MATERIAL = preload("res://textures/fisheye_material.tres")


var old_window_mode: DisplayServer.WindowMode
var old_res: Vector2i
var current_res: Vector2i

var display_settings_confirmed := false
var counting_down := false

var global: Node


@onready var v_box_container_params = $MarginContainer/VBoxContainerParams
@onready var v_box_container_menu = $MarginContainer/VBoxContainerMenu
@onready var v_box_container_options = $MarginContainer/CenterContainer/VBoxContainerOptions
@onready var option_button_res = $MarginContainer/CenterContainer/VBoxContainerOptions/HBoxContainerResolution/OptionButtonRes
@onready var option_button_win = $MarginContainer/CenterContainer/VBoxContainerOptions/HBoxContainerWindowMode/OptionButtonWin
@onready var display_timer = $MarginContainer/CenterContainer/VBoxContainerOptions/DisplayTimer
@onready var button_confirm_settings = $MarginContainer/CenterContainer/VBoxContainerOptions/ButtonConfirmSettings
@onready var margin_container = $MarginContainer
@onready var sub_viewport = $TextureRect/SubViewport
@onready var panel = $Panel
@onready var button_options = $MarginContainer/VBoxContainerMenu/ButtonOptions
@onready var button_debug = $MarginContainer/VBoxContainerMenu/ButtonDebug
@onready var button_apply = $MarginContainer/CenterContainer/VBoxContainerOptions/ButtonApply
@onready var build_ux = $MarginContainer/BuildUX
@onready var v_box_container_controls = $MarginContainer/CenterContainer/VBoxContainerControls
@onready var texture_rect_keyboard_controls = $MarginContainer/CenterContainer/VBoxContainerControls/TextureRectKeyboardControls
@onready var texture_rect_controller_controls = $MarginContainer/CenterContainer/VBoxContainerControls/TextureRectControllerControls
@onready var texture_rect = $TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	global.camera_type_changed.connect(_on_global_camera_type_changed)
	texture_rect.use_parent_material = true
	margin_container.visible = false
	var resolution = get_viewport_rect()
	current_res = resolution.size
	print("Resolution: %s" % resolution.size)
	if resolution.size.x == 2560.0:
		option_button_res.selected = 2
	elif resolution.size.x == 1920.0:
		option_button_res.selected = 1
	elif resolution.size.x == 1280.0:
		option_button_res.selected = 0
	else:
		option_button_res.selected = -1
	sub_viewport.size = resolution.size
	v_box_container_options.visible = false
	v_box_container_controls.visible = false
	v_box_container_params.visible = false
	build_ux.visible = false


func _unhandled_input(event):
	if not global.player_state == 1:
		if event.is_action_pressed("esc"):
			margin_container.visible = not margin_container.visible
			if margin_container.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				panel.visible = true
				v_box_container_menu.visible = panel.visible
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				panel.visible = false
				v_box_container_menu.visible = panel.visible
	if event.is_action_pressed("build"):
		var player_is_driving: bool = global.player_state == 0
		if player_is_driving:
			global.player_state = 1
		else:
			global.player_state = 0
		build_ux.visible = global.player_state == 1
		margin_container.visible = global.player_state == 1
		if global.player_state == 1:
			panel.visible = false
			v_box_container_params.visible = panel.visible
			v_box_container_menu.visible = panel.visible
			v_box_container_options.visible = panel.visible
		emit_signal("build_time", global.player_state == 1)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_options_button_up():
	v_box_container_options.visible = not v_box_container_options.visible
	v_box_container_params.visible = false
	v_box_container_controls.visible = false


func _on_button_debug_button_up():
	v_box_container_params.visible = not v_box_container_params.visible
	v_box_container_options.visible = false
	v_box_container_controls.visible = false


func _on_button_controls_button_up():
	v_box_container_controls.visible = not v_box_container_controls.visible
	v_box_container_options.visible = false
	v_box_container_params.visible = false


func _on_option_button_res_item_selected(index):
	if index == 0:
		pass
	elif index == 1:
		pass
	elif index == 2:
		pass


func _on_button_apply_button_up():
	old_window_mode = DisplayServer.window_get_mode()
	old_res = DisplayServer.window_get_size()
	var selected_win : DisplayServer.WindowMode = WIN_OPTIONS[option_button_win.selected]
	var selected_res : Vector2i = RES_OPTIONS[option_button_res.selected]
	print(selected_res)
	print(selected_win)
	DisplayServer.window_set_mode(selected_win)
	DisplayServer.window_set_size(selected_res)
	sub_viewport.size = selected_res
	current_res = selected_res
	button_confirm_settings.visible = true
	display_timer.start()
	counting_down = true
	display_settings_confirmed = false


func _on_display_timer_timeout():
	pass # Replace with function body.


func _on_button_confirm_settings_button_up():
	pass # Replace with function body.


func _on_button_keyboard_button_up():
	texture_rect_keyboard_controls.visible = true
	texture_rect_controller_controls.visible = false


func _on_button_controller_button_up():
	texture_rect_keyboard_controls.visible = false
	texture_rect_controller_controls.visible = true


func _on_global_camera_type_changed():
	if global.camera_type == 0:
		texture_rect.use_parent_material = true
		#sub_viewport.size = current_res
		#texture_rect.material = null
	elif global.camera_type == 1:
		texture_rect.use_parent_material = true
		#sub_viewport.size = current_res
		#texture_rect.material = null
	elif global.camera_type == 2:
		texture_rect.use_parent_material = false
		#sub_viewport.size = Vector2i(1920, 1080)
		#texture_rect.material = FISHEYE_MATERIAL


func _on_button_quit_button_up():
	get_tree().quit()
