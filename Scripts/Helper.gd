extends Node3D

# Tacticalmap data
var current_level_name : String
# Dictionary to hold data of chunks that are unloaded
var loaded_chunk_data = {"chunks": {}, "mapheight": 0, "mapwidth": 0} 

# Overmap data
var chunks: Dictionary = {} #Stores references to tilegrids representing the overmap
var current_level_pos: Vector2 = Vector2(0.1,0.1)
var current_map_seed: int = 0
var position_coord: Vector2 = Vector2(0, 0)

# Dictionary to store meshes for each block ID
var block_meshes: Dictionary = {}


# Helper scripts
const json_Helper_Class = preload("res://Scripts/Helper/json_helper.gd")
var json_helper: Node = null
const save_Helper_Class = preload("res://Scripts/Helper/save_helper.gd")
var save_helper: Node = null
const signal_broker_Class = preload("res://Scripts/Helper/signal_broker.gd")
var signal_broker: Node = null

# Called when the node enters the scene tree for the first time.
func _ready():
	json_helper = json_Helper_Class.new()
	save_helper = save_Helper_Class.new()
	signal_broker = signal_broker_Class.new()
	add_child(save_helper)

# Called when the game is over and everything will need to be reset to default
func reset():
	chunks = {} #Stores references to tilegrids representing the overmap
	loaded_chunk_data = {} # Data used to load blocks on the tacticalmap
	current_level_pos = Vector2(0.1,0.1)
	current_map_seed = 0
	position_coord = Vector2(0, 0)
	save_helper.current_save_folder = ""
	var mapMobs = get_tree().get_nodes_in_group("mobs")
	for mob in mapMobs:
		mob.remove_from_group("mobs")
		mob.queue_free()
	var mapitems = get_tree().get_nodes_in_group("mapitems")
	for item in mapitems:
		item.remove_from_group("mapitems")
		item.queue_free()

#Level_name is a filename in /mods/core/maps
#global_pos is the absolute position on the overmap
#see overmap.gd for how global_pos is used there
func switch_level(level_name: String, global_pos: Vector2) -> void:
	current_level_name = level_name
	# This is only true if the game has just initialized
	# In that case no level has once been loaded so there is no game to save
	if current_level_pos != Vector2(0.1,0.1):
		save_helper.save_current_level(current_level_pos)
		save_helper.save_overmap_state()
		save_helper.save_player_inventory()
		save_helper.save_player_equipment()
		save_helper.save_player_state(get_tree().get_first_node_in_group("Players"))
	current_level_pos = global_pos
	get_tree().change_scene_to_file("res://level_generation.tscn")


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
	
func raycast_from_mouse(m_pos, collision_mask):
	var ray_start = get_tree().get_first_node_in_group("Camera").project_ray_origin(m_pos)
	var ray_end = ray_start + get_tree().get_first_node_in_group("Camera").project_ray_normal(m_pos) * 1000
	var world3d : World3D = get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	query.collide_with_areas = true
	
	return space_state.intersect_ray(query)
	
func raycast(start_position : Vector3, end_position : Vector3, layer : int, object_to_ignore):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_position, end_position, layer, object_to_ignore)

	return space_state.intersect_ray(query)


# Function to create or retrieve a mesh for a given block ID
func get_or_create_block_mesh(block_id: String, shape: String) -> Mesh:
	if block_meshes.has(block_id):
		return block_meshes[block_id]

	var mesh
	if shape == "block":
		# Create a new BoxMesh for the block
		mesh = BoxMesh.new()
		mesh.size = Vector3(1, 1, 1)  # Set the size of the box mesh
	else:  # It's a slope
		mesh = PrismMesh.new()
		# Modify PrismMesh here as needed
		mesh.left_to_right = 1

	# Set material for the mesh
	mesh.surface_set_material(0, Gamedata.get_sprite_by_id(Gamedata.data.tiles, block_id))

	block_meshes[block_id] = mesh
	return mesh

