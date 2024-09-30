class_name DMaps
extends RefCounted

# There's a D in front of the class name to indicate this class only handles map data, nothing more
# This script is intended to be used inside the GameData autoload singleton
# This script handles the list of maps. You can access it trough Gamedata.maps

var dataPath: String = "./Mods/Core/Maps/"
var mapdict: Dictionary = {}


func _init():
	load_maps_from_disk()

# Load all mapdata from disk into memory
func load_maps_from_disk() -> void:
	var maplist: Array = Helper.json_helper.file_names_in_dir(dataPath, ["json"])
	for mapitem in maplist:
		var mapid: String = mapitem.replace(".json","")
		var map: DMap = DMap.new(mapid, dataPath)
		map.load_data_from_disk()
		mapdict[mapid] = map


func get_all() -> Dictionary:
	return mapdict


func duplicate_to_disk(mapid: String, newmapid: String) -> void:
	var newmap: DMap = DMap.new(newmapid, dataPath)
	var newdata: Dictionary = by_id(mapid).get_data().duplicate(true)
	# A duplicated map is brand new and can't already be referenced by something
	# So we delete the references from the duplicated data if it is present
	newdata.erase("references")
	newmap.set_data(newdata)
	newmap.save_data_to_disk()
	mapdict[newmapid] = newmap


func add_new(newid: String) -> void:
	var newmap: DMap = DMap.new(newid, dataPath)
	newmap.save_data_to_disk()
	mapdict[newid] = newmap
	

func delete_by_id(mapid: String) -> void:
	mapdict[mapid].delete()
	mapdict.erase(mapid)


func by_id(mapid: String) -> DMap:
	return mapdict[mapid.replace(".json","")]


func has_id(mapid: String) -> bool:
	return mapdict.has(mapid.replace(".json",""))


# Returns the sprite of the map
func sprite_by_id(mapid: String) -> Texture:
	return by_id(mapid).sprite


# Loop over all maps and delete the entity from it. It will be removed from all levels and areas
# entity_type: "tile", "furniture", "mob", "itemgroup"
# entity_id: the id of the entity
func remove_entity_from_all_maps(entity_type: String, entity_id: String):
	remove_entity_from_selected_maps(entity_type, entity_id, mapdict.keys())


# Removes the entity from the maps provided in the maps array
# entity_type: "tile", "furniture", "mob", "itemgroup"
# entity_id: the id of the entity
# maps: An array of map id's (Strings)
func remove_entity_from_selected_maps(entity_type: String, entity_id: String, maps: Array):
	for map in maps:
		mapdict[map].remove_entity_from_map(entity_type, entity_id)


# Removes the reference from the selected map
func remove_reference_from_map(mapid: String, module: String, type: String, refid: String):
	var mymap: DMap = mapdict[mapid]
	mymap.remove_reference(module, type, refid)


# Adds a reference to the references list
# For example, add "town_00" to references.Core.tacticalmaps
# mapid: The id of the map to add the reference to
# module: the mod that the entity belongs to, for example "Core"
# type: The type of entity, for example "tacticlmaps"
# refid: The id of the entity to reference, for example "town_00"
func add_reference_to_map(mapid: String, module: String, type: String, refid: String):
	var mymap: DMap = by_id(mapid)
	mymap.add_reference(module, type, refid)



# Function to get maps by category
func get_maps_by_category(category: String) -> Array[DMap]:
	var maplist: Array[DMap] = []
	for key in mapdict.keys():
		if mapdict[key].categories.has(category):
			maplist.append(mapdict[key])
	return maplist
