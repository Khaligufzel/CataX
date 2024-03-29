extends Node

#This script is a generic helper script to load and manipulate JSOn files.
#In Helper.gd, this script is loaded on game start
#It can be accessed trough Helper.json_helper


#This function takes the path to a json file and returns its contents as an array
#It should check if the contents is an array or not. If it is not an array, 
#it should return an empty array
func load_json_array_file(source: String) -> Array:
	var data_json: Array = []
	var file = FileAccess.open(source, FileAccess.READ)
	if file:
		var parsed_data = JSON.parse_string(file.get_as_text())
		if typeof(parsed_data) == TYPE_ARRAY:
			data_json = parsed_data
		else:
			print_debug("The file does not contain a JSON array: " + source)
	else:
		print_debug("Unable to load file: " + source)
	return data_json
	
#This function takes the path to a json file and returns its contents as an array
#It should check if the contents is an array or not. If it is not an array, 
#it should return an empty array
func load_json_dictionary_file(source: String) -> Dictionary:
	var data_json: Dictionary = {}
	var file = FileAccess.open(source, FileAccess.READ)
	if file:
		var parsed_data = JSON.parse_string(file.get_as_text())
		if typeof(parsed_data) == TYPE_DICTIONARY:
			data_json = parsed_data
		else:
			print_debug("The file does not contain a JSON dictionary: " + source)
	else:
		print_debug("Unable to load file: " + source)
	return data_json


# This function lists all the files in a specified directory. 
# it takes two arguments: `dirName` (the path of the directory
# to list files from) and `extensionFilter` (an optional
# array of file extensions to filter by).
# If the `extensionFilter` is empty, all filenames will be returned. 
# If not, it will only return filenames which file extentnion is in `extensionFilter`
func file_names_in_dir(dirName: String, extensionFilter: Array = []) -> Array:
	var fileNames: Array = []
	var dir = DirAccess.open(dirName)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if extensionFilter.is_empty():
					fileNames.append(file_name)
				elif file_name.get_extension() in extensionFilter:
					fileNames.append(file_name)
			file_name = dir.get_next()
	else:
		print_debug("An error occurred when trying to access the path: " + dirName)
	dir.list_dir_end()
	return fileNames


# This function lists all the files in a specified directory. 
# it takes ne argument: `dirName` (the path of the directory
# to list folders from) 
func folder_names_in_dir(path: String) -> Array:
	var dirs: Array = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir():
				dirs.append(folder_name)
			folder_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return dirs

#This function takes a json string and saves it as a json file.
func write_json_file(path: String, json: String):
	# Save the JSON string to the selected file location
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
	else:
		print_debug("Unable to write file " + path)
		
# This function will take a path and create a new json file with just {} or [] as the contents.
#If the file already exists, we do not overwrite it
func create_new_json_file(filename: String = "", isArray: bool = true):
	# If no string was provided, return without doing anything.
	if filename.is_empty():
		return

	# If the file already exists, alert the user that the file already exists.
	if FileAccess.file_exists(filename):
		return

	var file = FileAccess.open(filename, FileAccess.WRITE)
	#The file cen contain either one object or one array with a list of objects
	if isArray:
		file.store_string("[]")
	else:
		file.store_string("{}")
	file.close()



#This function enters a new item into the json file specified by the source variable
#The item will just be an object like this: {"id": id}
#If an item with that ID already exists in that file, do nothing
func add_id_to_json_file(source: String, id: String):
# If the source is not a JSON file, return without doing anything.
	if !source.ends_with(".json"):
		return

	# If the file does not exist, create a new JSON file.
	if !FileAccess.file_exists(source):
		create_new_json_file(source, true)
		
	var data_json: Array = load_json_array_file(source)

	# Check if an item with the given ID already exists in the file.
	for item in data_json:
		if item.get("id", "") == id:
			print_debug("An item with ID (" + id + ") already exists in the file.")
			return

	# If no item with the given ID exists, add a new item to the JSON data.
	data_json.append({"id": id})
	write_json_file(source, JSON.stringify(data_json, "\t"))


#This function will take a path to a json file and delete it
func delete_json_file(path: String):
	var dir = DirAccess.open(path)
	if dir:
		# Delete the file
		var err = dir.remove(path)
		if err == OK:
			print_debug("File deleted successfully: " + path)
		else:
			print_debug("An error occurred when trying to delete the file: " + path)
