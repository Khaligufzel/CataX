extends Node3D

# Tacticalmap data
var current_level_name: String
var ready_to_switch_level: Dictionary = {"save_ready": false, "chunks_unloaded": false}
# Contains the navigationmap for each chunk, used to give mobs the proper navigationmap
# When crossing chunk boundary
var chunk_navigation_maps: Dictionary = {}

# Overmap data
var current_level_pos: Vector2 = Vector2(0.1, 0.1) #Stores references to tilegrids representing the overmap
var current_map_seed: int = 0
var position_coord: Vector2 = Vector2(0, 0)

# Dictionary to store meshes for each block ID
var navigationmap: RID

# Helper scripts
const json_Helper_Class = preload("res://Scripts/Helper/json_helper.gd")
const save_Helper_Class = preload("res://Scripts/Helper/save_helper.gd")
const signal_broker_Class = preload("res://Scripts/Helper/signal_broker.gd")
const task_manager_Class = preload("res://Scripts/Helper/task_manager.gd")
const map_manager_Class = preload("res://Scripts/Helper/map_manager.gd")
const overmap_manager_Class = preload("res://Scripts/Helper/overmap_manager.gd")
const quest_helper_Class = preload("res://Scripts/Helper/quest_helper.gd")

var json_helper: Node = null
var save_helper: Node = null
var signal_broker: Node = null
var task_manager: Node = null
var map_manager: Node = null
var overmap_manager: Node = null
var quest_helper: Node = null

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize_helpers()
	add_child(save_helper)
	add_child(quest_helper)
	add_child(overmap_manager)
	signal_broker.game_ended.connect(_on_game_ended)

func initialize_helpers():
	json_helper = json_Helper_Class.new()
	save_helper = save_Helper_Class.new()
	signal_broker = signal_broker_Class.new()
	task_manager = task_manager_Class.new()
	map_manager = map_manager_Class.new()
	overmap_manager = overmap_manager_Class.new()
	quest_helper = quest_helper_Class.new()

func _process(_delta: float) -> void:
	# task_manager can't _process on it's own so we call it from here
	task_manager._process(_delta)

# Called when the game is over and everything will need to be reset to default
func reset():
	overmap_manager.loaded_chunk_data = {"chunks": {}}
	current_level_pos = Vector2(0.1, 0.1)
	current_map_seed = 0
	position_coord = Vector2(0, 0)
	save_helper.current_save_folder = ""
	chunk_navigation_maps.clear()

	free_group_nodes("mobs")
	free_group_nodes("mapitems")

func free_group_nodes(group_name: String):
	var nodes = get_tree().get_nodes_in_group(group_name)
	for node in nodes:
		node.remove_from_group(group_name)
		node.queue_free()

# Save game state
func save_game():
	save_helper.save_current_level(current_level_pos)
	#save_helper.save_overmap_state()
	save_helper.save_player_inventory()
	save_helper.save_player_equipment()
	save_helper.save_player_state(get_tree().get_first_node_in_group("Players"))


#Level_name is a filename in /mods/core/maps
#global_pos is the absolute position on the overmap
#see overmap.gd for how global_pos is used there
func switch_level(level_name: String, global_pos: Vector2) -> void:
	ready_to_switch_level = {"save_ready": false, "chunks_unloaded": false}
	current_level_name = level_name
	
	# This is only true if the game has just initialized
	# In that case no level has once been loaded so there is no game to save
	if current_level_pos != Vector2(0.1, 0.1):
		save_game()
		chunk_navigation_maps.clear()
	else:
		ready_to_switch_level.chunks_unloaded = true

	current_level_pos = global_pos
	ready_to_switch_level.save_ready = true
	start_timer()

# Function to create and start a timer that will wait to switch the level
func start_timer():
	var my_timer = Timer.new() # Create a new Timer instance
	my_timer.wait_time = 1 # Timer will tick every 1 second
	my_timer.one_shot = false # False means the timer will repeat
	add_child(my_timer) # Add the Timer to the scene as a child of this node
	my_timer.timeout.connect(_on_timer_timeout.bind(my_timer)) # Connect the timeout signal
	my_timer.start() # Start the timer


# This function will be called every time the Timer ticks
func _on_timer_timeout(my_timer: Timer):
	if ready_to_switch_level.save_ready and ready_to_switch_level.chunks_unloaded:
		print_debug("Switching level")
		my_timer.stop()
		get_tree().change_scene_to_file.bind("res://level_generation.tscn").call_deferred()

# Function to draw a line in the 3D space
func line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = mesh_instance.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().add_child(mesh_instance)

	return mesh_instance

# Function to perform a raycast from the mouse position
func raycast_from_mouse(m_pos, collision_mask) -> Dictionary:
	var camera = get_tree().get_first_node_in_group("Camera")
	var ray_start = camera.project_ray_origin(m_pos)
	var ray_end = ray_start + camera.project_ray_normal(m_pos) * 1000
	var space_state = get_world_3d().direct_space_state

	if space_state:
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
		query.collide_with_areas = true
		return space_state.intersect_ray(query)
	return {}

# Function to perform a raycast between two points
func raycast(start_position: Vector3, end_position: Vector3, layer: int, object_to_ignore):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_position, end_position, layer, object_to_ignore)
	return space_state.intersect_ray(query)


# Called when a chunk emits its loaded signal. We save the navigationmap RID to a dictionary
# This can then be used by navigationagents that are present on the chunk
func on_chunk_loaded(data: Dictionary):
	# `mypos` is a Vector3, we only use the x and z since y is constant 0
	var chunk_position = Vector2(data["mypos"].x, data["mypos"].z)
	chunk_navigation_maps[chunk_position] = data["map"]


# Called when a chunk emits its unloaded signal. We remove the chunk from the navigationmaps
# Dictionary. The chunk is responsible for unloading the navigationmap itself
func on_chunk_unloaded(data: Dictionary):
	var chunk_position = Vector2(data["mypos"].x, data["mypos"].z)
	chunk_navigation_maps.erase(chunk_position)

# When the user exits the game and returns to the main menu
func _on_game_ended():
	reset() # Resets the game, as though you re-started it
