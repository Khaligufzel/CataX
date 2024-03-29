extends Control

var saved_game_folders : Array
@export var load_game_list : OptionButton 
func _ready():
	saved_game_folders = Helper.json_helper.folder_names_in_dir("user://save/")
	# Reverse the order of the saved_game_folders array
	saved_game_folders.reverse()

	# Populate the load_game_list with the saved game folders
	for saved_game in saved_game_folders:
		load_game_list.add_item(saved_game)

func _on_load_game_button_pressed():
	var selected_game_folder = saved_game_folders[load_game_list.get_selected_id()]
	Helper.save_helper.load_game_from_folder(selected_game_folder)
	Helper.save_helper.load_overmap_state()
	Helper.save_helper.load_player_inventory()
	Helper.save_helper.load_player_equipment()
	# We pass the name of the default map and coordinates
	# If there is a saved game, it will not load the provided map
	# but rather the one that was saved in the game that was loaded
	Helper.switch_level("DefaultTacticalMap.json", Vector2(0, 0))

# When the play demo button is pressed
# Create a new folder in the user directory
# The name of the folder should be the current date and time so it's unique
# This unique folder will contain save data for this game and can be loaded later
func _on_play_demo_pressed():
	Helper.save_helper.create_new_save()
	Helper.switch_level("DefaultTacticalMap.json", Vector2(0, 0))

func _on_help_button_pressed():
	get_tree().change_scene_to_file("res://documentation.tscn")

func _on_content_manager_button_button_up():
	get_tree().change_scene_to_file("res://Scenes/ContentManager/contentmanager.tscn")
