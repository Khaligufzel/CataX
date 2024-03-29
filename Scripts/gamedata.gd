extends Node

#This autoload singleton loads all game data required to run the game
#It can be accessed by using Gamedata.property
var data: Dictionary = {}

# We write down the associated paths for the files to load
# Next, sprites are loaded from spritesPath into the .sprites property
# Finally, the data is loaded from dataPath into the .data property
# Maps tile sprites and map data are different so they 
# are loaded in using their respective functions
func _ready():
	data.tiles = {}
	data.mobs = {}
	data.overmaptiles = {}
	data.maps = {}
	data.tacticalmaps = {}
	data.furniture = {}
	data.items = {}
	data.tiles.dataPath = "./Mods/Core/Tiles/Tiles.json"
	data.tiles.spritePath = "./Mods/Core/Tiles/"
	data.mobs.dataPath = "./Mods/Core/Mobs/Mobs.json"
	data.mobs.spritePath = "./Mods/Core/Mobs/"
	data.items.dataPath = "./Mods/Core/Items/Items.json"
	data.items.spritePath = "./Mods/Core/Items/"
	data.furniture.spritePath = "./Mods/Core/Furniture/"
	data.furniture.dataPath = "./Mods/Core/Furniture/Furniture.json"
	data.overmaptiles.spritePath = "./Mods/Core/OvermapTiles/"
	data.tacticalmaps.dataPath = "./Mods/Core/TacticalMaps/"
	data.maps.dataPath = "./Mods/Core/Maps/"
	# Map preview images are stored in the same folder
	data.maps.spritePath = "./Mods/Core/Maps/"
	load_sprites()
	load_tile_sprites()
	load_data()
	update_item_protoset_json_data("res://ItemProtosets.tres",JSON.stringify(data.items.data,"\t"))
	data.maps.data = Helper.json_helper.file_names_in_dir(data.maps.dataPath, ["json"])
	data.tacticalmaps.data = Helper.json_helper.file_names_in_dir(\
	data.tacticalmaps.dataPath, ["json"])

#Loads json data. If no json file exists, it will create an empty array in a new file
func load_data() -> void:
	for dict in data.keys():
		if data[dict].has("dataPath"):
			var dataPath: String = data[dict].dataPath
			if FileAccess.file_exists(dataPath):
				Helper.json_helper.create_new_json_file(dataPath)
				data[dict].data = Helper.json_helper.load_json_array_file(dataPath)
			else:
				data[dict].data = []

#This loads all the sprites and assigns them to the proper dictionary
func load_sprites() -> void:
	for dict in data.keys():
		if data[dict].has("spritePath"):
			var loaded_sprites: Dictionary = {} # Materials used to represent mobs
			var spritesDir: String = data[dict].spritePath
			var png_files: Array = Helper.json_helper.file_names_in_dir(spritesDir, ["png"])
			for png_file in png_files:
				# Load the .png file as a texture
				var texture := load(spritesDir + png_file) 
				# Add the material to the dictionary
				loaded_sprites[png_file] = texture
			data[dict].sprites = loaded_sprites

# This function reads all the files in "res://Mods/Core/Tiles/". It will check if the file is a .png file. If the file is a .png file, it will create a new material with that .png image as the texture. It will put all of the created materials in a dictionary with the name of the file as the key and the material as the value.
func load_tile_sprites() -> void:
	var tile_materials: Dictionary = {} # Materials used to represent tiles
	var tilesDir = data.tiles.spritePath
	var png_files: Array = Helper.json_helper.file_names_in_dir(tilesDir, ["png"])
	for png_file in png_files:
		var texture := load(tilesDir + png_file) # Load the .png file as a texture
		var material := StandardMaterial3D.new() 
		material.albedo_texture = texture # Set the texture of the material
		material.uv1_scale = Vector3(3,2,1)
		tile_materials[png_file] = material # Add the material to the dictionary
	data.tiles.sprites = tile_materials

#This function will take two strings called ID and newID
#It will find an item with this ID in a json file specified by the source variable
#It will then duplicate that item into the json file and change the ID to newID
func duplicate_item_in_data(contentData: Dictionary, id: String, newID: String):
	if contentData.data.is_empty():
		return

	if contentData.dataPath.ends_with((".json")):
		# Check if an item with the given ID exists in the file.
		var item_index: int = get_array_index_by_id(contentData,id)
		if item_index == -1:
			return
		
		# Duplicate the found item recursively
		var item_to_duplicate = contentData.data[item_index].duplicate(true)
		
		# If there is no item to duplicate, return without doing anything.
		if item_to_duplicate == null:
			return
		# Change the ID of the duplicated item.
		item_to_duplicate["id"] = newID
		# Add the duplicated item to the JSON data.
		contentData.data.append(item_to_duplicate)
		Helper.json_helper.write_json_file(contentData.dataPath,JSON.stringify(contentData.data))
	else:
		print_debug("There should be code here for when a file in the gets duplicated")


# This function will duplicate a file with the provided original ID
# and save it under a new ID within the same directory.
func duplicate_file_in_data(contentData: Dictionary, original_id: String, new_id: String) -> void:
	var data_path: String = contentData.dataPath
	var original_file_path: String = data_path + original_id + ".json"
	var new_file_path: String = data_path + new_id + ".json"

	if not FileAccess.file_exists(original_file_path):
		print_debug("Original file not found: " + original_file_path)
		return

	# Load the original file content.
	var original_content = Helper.json_helper.load_json_dictionary_file(original_file_path)

	# Write the original content to a new file with the new ID.
	var save_result = Helper.json_helper.write_json_file(new_file_path, JSON.stringify(original_content))
	if save_result == OK:
		print_debug("File duplicated successfully: " + new_file_path)
		# Add the new ID to the data array if it's managed as an array of IDs.
		if contentData.data is Array and typeof(contentData.data[0]) == TYPE_STRING:
			contentData.data.append(new_id)
			save_data_to_file(contentData)  # Save the updated data array to file.
	else:
		print_debug("Failed to duplicate file to: " + new_file_path)



# This function appends a new object to an existing array
# Pass the contentData dictionary to this function and the value of the ID
# If the data directory ends in .json, it will append an object
# The object that will be appended will be nothing more then {"id": id}
# if the data directory does not end in .json, a new file will be added
# This file will get the name as specified by id, so for example "myhouse"
# After the ID is added, the data array will be saved to disk
func add_id_to_data(contentData: Dictionary, id: String):
	if !contentData.has("data"):
		return
	if contentData.dataPath.ends_with((".json")):
		if get_array_index_by_id(contentData,id) != -1:
			print_debug("Tried to add an existing id to an array")
			return
		contentData.data.append({"id": id})
		save_data_to_file(contentData)
	else:
		if id in contentData.data:
			print_debug("Tried to add an existing file to a file array")
			return
		contentData.data.append(id)
		#Create a new json file in the directory with only {} in the file
		Helper.json_helper.create_new_json_file(contentData.dataPath + id + ".json", false)

# Will remove an item from the data
# If the first item in data is a dictionary, we remove an item that has the provided id
# If the first item in data is a string, we remove the string and the associated json file
func remove_item_from_data(contentData: Dictionary, id: String):
	if contentData.data.is_empty():
		return
	if contentData.data[0] is Dictionary:
		contentData.data.remove_at(get_array_index_by_id(contentData, id))
		save_data_to_file(contentData)
	elif contentData.data[0] is String:
		contentData.data.erase(id)
		Helper.json_helper.delete_json_file(contentData.dataPath, id)
	else:
		print_debug("Tried to remove item from data, but the data contains \
		neither Dictionary nor String")

func get_array_index_by_id(contentData: Dictionary, id: String) -> int:
	# Iterate through the array
	for i in range(len(contentData.data)):
		# Check if the current item is a dictionary
		if typeof(contentData.data[i]) == TYPE_DICTIONARY:
			# Check if it has the 'id' key and matches the given ID
			if contentData.data[i].has("id") and contentData.data[i]["id"] == id:
				return i
		# Check if the current item is a string and matches the given ID
		elif typeof(contentData.data[i]) == TYPE_STRING and contentData.data[i] == id:
			return i
	# Return -1 if the ID is not found
	return -1

func save_data_to_file(contentData: Dictionary):
	var datapath: String = contentData.dataPath
	if datapath.ends_with(".json"):
		Helper.json_helper.write_json_file(datapath,JSON.stringify(contentData.data,"\t"))

# Takes contentdata and an id and returns the json that belongs to an id
# For example, contentData can be Gamedata.data.tiles
# and id can be "plain_grass" and it will return the json data for plain_grass
func get_data_by_id(contentData: Dictionary, id: String) -> Dictionary:
	return contentData.data[get_array_index_by_id(contentData,id)]

#Takes contentData and an id and returns the sprite associated with the id
# For example, contentData can be Gamedata.data.tiles
# and id can be "plain_grass" and it will return the sprite for plain_grass
func get_sprite_by_id(contentData: Dictionary, id: String) -> Resource:
	var item_json = get_data_by_id(contentData, id)
	return contentData.sprites[item_json.sprite]

# This functino is called when an editor has changed data
# The contenteditor (that initializes the individual editors)
# connects the changed_data signal to this function
# and binds the appropriate data array so it can be saved in this function
func on_data_changed(contentData: Dictionary):
	save_data_to_file(contentData)

# This will update the given resource file with the provided json data
# It is intended to save item data from json to the res://ItemProtosets.tres file
# So we can use the item json data in-game
func update_item_protoset_json_data(tres_path: String, new_json_data: String) -> void:
	# Load the ItemProtoset resource
	var item_protoset = load(tres_path) as ItemProtoset
	if not item_protoset:
		print("Failed to load ItemProtoset resource from:", tres_path)
		return

	# Update the json_data property
	item_protoset.json_data = new_json_data

	# Save the resource back to the .tres file
	var save_result = ResourceSaver.save(item_protoset, tres_path)
	if save_result != OK:
		print("Failed to save updated ItemProtoset resource to:", tres_path)
	else:
		print("ItemProtoset resource updated and saved successfully to:", tres_path)



# Function to filter items by type
func get_items_by_type(item_type: String) -> Array:
	var filtered_items = []
	
	# Check if the items data exists and is an array
	if Gamedata.data.has("items") and Gamedata.data.items.has("data") and typeof(Gamedata.data.items.data) == TYPE_ARRAY:
		# Iterate through each item in the items data
		for item in Gamedata.data.items.data:
			# Check if the item is a dictionary and has the specified type
			if item is Dictionary and item.has(item_type):
				# Add the item to the filtered items list
				filtered_items.append(item)

	return filtered_items
