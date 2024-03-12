extends Control

signal build_time(toggle: bool)

const RES_OPTIONS = [Vector2i(1280, 720),
					Vector2i(1920, 1080),
					Vector2i(2560, 1440)]
const WIN_OPTIONS = [DisplayServer.WINDOW_MODE_WINDOWED,
					DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


var old_window_mode: DisplayServer.WindowMode
var old_res: Vector2i

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


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	margin_container.visible = false
	var resolution = get_viewport_rect()
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


func _unhandled_input(event):
	if not global.build_mode:
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
		global.build_mode = not global.build_mode
		build_ux.visible = global.build_mode
		margin_container.visible = global.build_mode
		if global.build_mode:
			panel.visible = false
			v_box_container_params.visible = panel.visible
			v_box_container_menu.visible = panel.visible
			v_box_container_options.visible = panel.visible
		emit_signal("build_time", global.build_mode)
		


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
	sub_viewport.size = selected_res
	DisplayServer.window_set_size(selected_res)
	button_confirm_settings.visible = true
	display_timer.start()
	counting_down = true
	display_settings_confirmed = false


func _on_display_timer_timeout():
	pass # Replace with function body.


func _on_button_confirm_settings_button_up():
	pass # Replace with function body.


func _on_margin_container_visibility_changed():
	if panel:
		pass # re-enable if controller controls dont work
		#if margin_container.visible:
			#margin_container.process_mode = Node.PROCESS_MODE_INHERIT
			#button_apply.focus_mode = FOCUS_ALL
			#button_confirm_settings.focus_mode = FOCUS_ALL
			#button_debug.focus_mode = FOCUS_ALL
			#button_options.focus_mode = FOCUS_ALL
			#option_button_res.focus_mode = FOCUS_ALL
			#option_button_win.focus_mode = FOCUS_ALL
		#else:
			#margin_container.process_mode = Node.PROCESS_MODE_DISABLED
			#button_apply.focus_mode = FOCUS_NONE
			#button_confirm_settings.focus_mode = FOCUS_NONE
			#button_debug.focus_mode = FOCUS_NONE
			#button_options.focus_mode = FOCUS_NONE
			#option_button_res.focus_mode = FOCUS_NONE
			#option_button_win.focus_mode = FOCUS_NONE


func _on_button_keyboard_button_up():
	texture_rect_keyboard_controls.visible = true
	texture_rect_controller_controls.visible = false


func _on_button_controller_button_up():
	texture_rect_keyboard_controls.visible = false
	texture_rect_controller_controls.visible = true


func _on_button_quit_button_up():
	get_tree().quit()
