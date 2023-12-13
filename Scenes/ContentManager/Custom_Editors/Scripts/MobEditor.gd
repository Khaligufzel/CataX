extends Control

#This scene is intended to be used inside the content editor
#It is supposed to edit exactly one mob (friend and foe)
#It expects to save the data to a JSON file that contains all data from a mod
#To load data, provide the name of the mob data file and an ID

@export var mobImageDisplay: TextureRect = null
@export var IDTextLabel: Label = null
@export var PathTextLabel: Label = null
@export var NameTextEdit: TextEdit = null
@export var DescriptionTextEdit: TextEdit = null
@export var mobSelector: Popup = null
@export var melee_damage_numedit: SpinBox
@export var melee_range_numedit: SpinBox
@export var health_numedit: SpinBox
@export var moveSpeed_numedit: SpinBox
@export var idle_move_speed_numedit: SpinBox
@export var sightRange_numedit: SpinBox
@export var senseRange_numedit: SpinBox
@export var hearingRange_numedit: SpinBox
# This signal will be emitted when the user presses the save button
# This signal should alert Gamedata that the mob data array should be saved to disk
# The content editor has connected this signal to Gamedata already
signal data_changed()

# The data that represents this mob
# The data is selected from the Gamedata.all_mobs array
# based on the ID that the user has selected in the content editor
var contentData: Dictionary = {}:
	set(value):
		contentData = value
		load_mob_data()
		mobSelector.sprites_collection = Gamedata.mob_materials

#This function update the form based on the contentData that has been loaded
func load_mob_data() -> void:
	if mobImageDisplay != null and contentData.has("imagePath"):
		mobImageDisplay.texture = load(contentData["imagePath"])
		PathTextLabel.text = contentData["imagePath"]
	if IDTextLabel != null:
		IDTextLabel.text = str(contentData["id"])
	if NameTextEdit != null and contentData.has("name"):
		NameTextEdit.text = contentData["name"]
	if DescriptionTextEdit != null and contentData.has("description"):
		DescriptionTextEdit.text = contentData["description"]
	if melee_damage_numedit != null and contentData.has("melee_damage"):
		melee_damage_numedit.get_line_edit().text = contentData["melee_damage"]
	if melee_range_numedit != null and contentData.has("melee_range"):
		melee_damage_numedit.get_line_edit().text = contentData["melee_range"]
	if health_numedit != null and contentData.has("health"):
		health_numedit.get_line_edit().text = contentData["health"]
	if moveSpeed_numedit != null and contentData.has("move_speed"):
		moveSpeed_numedit.get_line_edit().text = contentData["move_speed"]
	if idle_move_speed_numedit != null and contentData.has("idle_move_speed"):
		idle_move_speed_numedit.get_line_edit().text = contentData["idle_move_speed"]
	if sightRange_numedit != null and contentData.has("sight_range"):
		sightRange_numedit.get_line_edit().text = contentData["sight_range"]
	if senseRange_numedit != null and contentData.has("sense_range"):
		senseRange_numedit.get_line_edit().text = contentData["sense_range"]
	if hearingRange_numedit != null and contentData.has("hearing_range"):
		hearingRange_numedit.get_line_edit().text = contentData["hearing_range"]
	

#The editor is closed, destroy the instance
#TODO: Check for unsaved changes
func _on_close_button_button_up() -> void:
	queue_free()

# This function takes all data fro the form elements stores them in the contentData
# Since contentData is a reference to an item in Gamedata.all_mobs
# the central array for mobdata is updated with the changes as well
# The function will signal to Gamedata that the data has changed and needs to be saved
func _on_save_button_button_up() -> void:
	contentData["imagePath"] = PathTextLabel.text
	contentData["name"] = NameTextEdit.text
	contentData["description"] = DescriptionTextEdit.text
	contentData["melee_damage"] = melee_damage_numedit.get_line_edit().text
	contentData["melee_range"] = melee_damage_numedit.get_line_edit().text
	contentData["health"] = health_numedit.get_line_edit().text
	contentData["move_speed"] = moveSpeed_numedit.get_line_edit().text
	contentData["idle_move_speed"] = idle_move_speed_numedit.get_line_edit().text
	contentData["sight_range"] = sightRange_numedit.get_line_edit().text
	contentData["sense_range"] = senseRange_numedit.get_line_edit().text
	contentData["hearing_range"] = hearingRange_numedit.get_line_edit().text
	data_changed.emit()

#When the mobImageDisplay is clicked, the user will be prompted to select an image from 
# "res://Mods/Core/mobs/". The texture of the mobImageDisplay will change to the selected image
func _on_mob_image_display_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		mobSelector.show()


func _on_sprite_selector_sprite_selected_ok(clicked_sprite) -> void:
	var mobTexture: Resource = clicked_sprite.get_texture()
	mobImageDisplay.texture = mobTexture
	PathTextLabel.text = mobTexture.resource_path.replace("res://","")
