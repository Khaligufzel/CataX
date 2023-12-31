extends Control

signal zoom_level_changed(value: int)
var tileSize: int = 128
var mapHeight: int = 32
var mapWidth: int = 32

@export var panWindow: Control = null
@export var mapScrollWindow: ScrollContainer = null
@export var gridContainer: ColorRect = null

var zoom_level: int = 20:
	set(val):
		zoom_level = val
		adjust_scale(zoom_level)
		zoom_level_changed.emit(zoom_level)


func _ready():
	setPanWindowSize()
	
func setPanWindowSize():
	var panWindowWidth: float = 0.8*tileSize*mapWidth
	var panWindowHeight: float = 0.8*tileSize*mapHeight
	panWindow.custom_minimum_size = Vector2(panWindowWidth, panWindowHeight)


var mouse_button_pressed: bool = false

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE: 
				if event.pressed:
					mouse_button_pressed = true
				else:
					mouse_button_pressed = false
	
	#When the users presses and holds the mouse wheel, we scoll the grid
	if event is InputEventMouseMotion:
		if mouse_button_pressed:
			mapScrollWindow.scroll_horizontal = mapScrollWindow.scroll_horizontal - event.relative.x
			mapScrollWindow.scroll_vertical = mapScrollWindow.scroll_vertical - event.relative.y


#Scroll to the center when the scroll window is ready
func _on_map_scroll_window_ready():
	await get_tree().create_timer(0.5).timeout
	mapScrollWindow.scroll_horizontal = int(panWindow.custom_minimum_size.x/3.5)
	mapScrollWindow.scroll_vertical = int(panWindow.custom_minimum_size.y/3.5)
	adjust_scale(20)
	
func adjust_scale(zoom: int):
	gridContainer.custom_minimum_size = Vector2(mapWidth*1.28*zoom, mapHeight*1.28*zoom)

func _on_zoom_scroller_zoom_level_changed(value):
	zoom_level = value

func _on_tile_grid_zoom_level_changed(value):
	zoom_level = value

