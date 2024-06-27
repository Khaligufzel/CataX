extends Control

#This scene is intended to be used inside the content editor
#It is supposed to edit exactly one quest
#It expects to save the data to a JSON file
#To load data, provide the name of the quest data file and an ID

@export var questImageDisplay: TextureRect = null
@export var IDTextLabel: Label = null
@export var PathTextLabel: Label = null
@export var NameTextEdit: TextEdit = null
@export var DescriptionTextEdit: TextEdit = null
@export var questSelector: Popup = null
@export var step_type_option_button: OptionButton
@export var steps_container: VBoxContainer
@export var rewards_item_list: GridContainer
@export var dropabletextedit: PackedScene = null

# This signal will be emitted when the user presses the save button
# This signal should alert Gamedata that the quest data array should be saved to disk
signal data_changed(game_data: Dictionary, new_data: Dictionary, old_data: Dictionary)

var olddata: Dictionary # Remember what the value of the data was before editing
# The data that represents this quest
# The data is selected from the Gamedata.data.quests.data array
# based on the ID that the user has selected in the content editor
var contentData: Dictionary = {}:
	set(value):
		contentData = value
		load_quest_data()
		questSelector.sprites_collection = Gamedata.data.quests.sprites
		olddata = contentData.duplicate(true)

func _ready():
	data_changed.connect(Gamedata.on_data_changed)


#The editor is closed, destroy the instance
#TODO: Check for unsaved changes
func _on_close_button_button_up() -> void:
	queue_free()


#This function updates the form based on the contentData that has been loaded
func load_quest_data() -> void:
	if questImageDisplay != null and contentData.has("sprite") and \
	not contentData["sprite"] == "" and Gamedata.data.quests.sprites.has(contentData["sprite"]):
		questImageDisplay.texture = Gamedata.data.quests.sprites[contentData["sprite"]]
		PathTextLabel.text = contentData["sprite"]
	if IDTextLabel != null:
		IDTextLabel.text = str(contentData["id"])
	if NameTextEdit != null and contentData.has("name"):
		NameTextEdit.text = contentData["name"]
	if DescriptionTextEdit != null and contentData.has("description"):
		DescriptionTextEdit.text = contentData["description"]
	if steps_container:
		steps_container.clear()
		if contentData.has("steps"):
			for step in contentData["steps"]:
				add_step_from_data(step)

# Function to add a step based on the step type selected
func _on_add_step_button_button_up():
	var step_type = step_type_option_button.get_selected_id()
	var empty_step = {}
	
	match step_type:
		0: # Craft item
			empty_step = {"type": "craft", "item": ""}
		1: # Collect x amount of item
			empty_step = {"type": "collect", "item": "", "amount": 1}
		2: # Call function
			empty_step = {"type": "call", "function": "QuestManager.testfunc()", "params": ""}
		3: # Enter map
			empty_step = {"type": "enter", "map_id": ""}
		4: # Kill x mobs of type
			empty_step = {"type": "kill", "mob": "", "amount": 1}
	
	add_step_from_data(empty_step)


# Function to add a step based on the step type selected
func _on_add_step_button_button_up1():
	var step_type = step_type_option_button.get_selected_id()
	var hbox = HBoxContainer.new()
	
	match step_type:
		0: # Craft item
			var labelinstance: Label = Label.new()
			labelinstance.text = "Craft item:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			hbox.add_child(dropabletextedit_instance)
		1: # Collect x amount of item
			var labelinstance: Label = Label.new()
			labelinstance.text = "Collect:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			hbox.add_child(dropabletextedit_instance)
			var spinbox = SpinBox.new()
			spinbox.min_value = 1
			spinbox.value = 1
			hbox.add_child(spinbox)
		2: # Call function
			var labelinstance: Label = Label.new()
			labelinstance.text = "Call function:"
			hbox.add_child(labelinstance)
			var optionbutton = OptionButton.new()
			optionbutton.add_item("QuestManager.testfunc()")
			hbox.add_child(optionbutton)
			var textedit = TextEdit.new()
			textedit.placeholder_text = "Parameters"
			hbox.add_child(textedit)
		3: # Enter map
			var labelinstance: Label = Label.new()
			labelinstance.text = "Enter map:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			hbox.add_child(dropabletextedit_instance)
		4: # Kill x mobs of type
			var labelinstance: Label = Label.new()
			labelinstance.text = "Kill:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			hbox.add_child(dropabletextedit_instance)
			var spinbox = SpinBox.new()
			spinbox.min_value = 1
			spinbox.value = 1
			hbox.add_child(spinbox)

	steps_container.add_child(hbox)


# This function collects data from each step in the steps_container and stores it in contentData
# Since contentData is a reference to an item in Gamedata.data.quests.data
# the central array for questdata is updated with the changes as well
# The function will signal to Gamedata that the data has changed and needs to be saved
func _on_save_button_button_up() -> void:
	contentData["sprite"] = PathTextLabel.text
	contentData["name"] = NameTextEdit.text
	contentData["description"] = DescriptionTextEdit.text
	contentData["steps"] = []
	for hbox in steps_container.get_children():
		var step = {}
		var step_type_label = hbox.get_child(0) as Label
		if step_type_label.text == "Craft item:":
			step["type"] = "craft"
			step["item"] = (hbox.get_child(1)).get_text()
		elif step_type_label.text == "Collect:":
			step["type"] = "collect"
			step["item"] = (hbox.get_child(1)).get_text()
			step["amount"] = (hbox.get_child(2) as SpinBox).value
		elif step_type_label.text == "Call function:":
			step["type"] = "call"
			step["function"] = (hbox.get_child(1) as OptionButton).get_item_text(0)
			step["params"] = (hbox.get_child(2) as TextEdit).text
		elif step_type_label.text == "Enter map:":
			step["type"] = "enter"
			step["map_id"] = (hbox.get_child(1)).get_text()
		elif step_type_label.text == "Kill:":
			step["type"] = "kill"
			step["mob"] = (hbox.get_child(1)).get_text()
			step["amount"] = (hbox.get_child(2) as SpinBox).value
		contentData["steps"].append(step)
	data_changed.emit(Gamedata.data.quests, contentData, olddata)
	olddata = contentData.duplicate(true)


# When the questImageDisplay is clicked, the user will be prompted to select an image from 
# "res://Mods/Core/Quests/". The texture of the questImageDisplay will change to the selected image
func _on_quest_image_display_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		questSelector.show()

func _on_sprite_selector_sprite_selected_ok(clicked_sprite) -> void:
	var questTexture: Resource = clicked_sprite.get_texture()
	questImageDisplay.texture = questTexture
	PathTextLabel.text = questTexture.resource_path.get_file()


# Function to create a step from loaded data
func add_step_from_data(step):
	var hbox = HBoxContainer.new()
	match step["type"]:
		"craft":
			var labelinstance: Label = Label.new()
			labelinstance.text = "Craft item:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			dropabletextedit_instance.set_text(step["item"])
			hbox.add_child(dropabletextedit_instance)
		"collect":
			var labelinstance: Label = Label.new()
			labelinstance.text = "Collect:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			dropabletextedit_instance.set_text(step["item"])
			hbox.add_child(dropabletextedit_instance)
			var spinbox = SpinBox.new()
			spinbox.min_value = 1
			spinbox.value = step["amount"]
			hbox.add_child(spinbox)
		"call":
			var labelinstance: Label = Label.new()
			labelinstance.text = "Call function:"
			hbox.add_child(labelinstance)
			var optionbutton = OptionButton.new()
			optionbutton.add_item(step["function"])
			hbox.add_child(optionbutton)
			var textedit = TextEdit.new()
			textedit.text = step["params"]
			hbox.add_child(textedit)
		"enter":
			var labelinstance: Label = Label.new()
			labelinstance.text = "Enter map:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			dropabletextedit_instance.set_text(step["map_id"])
			hbox.add_child(dropabletextedit_instance)
		"kill":
			var labelinstance: Label = Label.new()
			labelinstance.text = "Kill:"
			hbox.add_child(labelinstance)
			var dropabletextedit_instance: HBoxContainer = dropabletextedit.instantiate()
			dropabletextedit_instance.set_text(step["mob"])
			hbox.add_child(dropabletextedit_instance)
			var spinbox = SpinBox.new()
			spinbox.min_value = 1
			spinbox.value = step["amount"]
			hbox.add_child(spinbox)
	steps_container.add_child(hbox)


# Called when the user has successfully dropped data onto the texteditcontrol
# We have to check the dropped_data for the id property
func entity_drop(dropped_data: Dictionary, texteditcontrol: HBoxContainer) -> void:
	# Assuming dropped_data is a Dictionary that includes an 'id'
	if dropped_data and "id" in dropped_data:
		var item_id = dropped_data["id"]
		var item_data = Gamedata.get_data_by_id(Gamedata.data.skills, item_id)
		if item_data.is_empty():
			print_debug("No item data found for ID: " + item_id)
			return
		texteditcontrol.set_text(item_id)
	else:
		print_debug("Dropped data does not contain an 'id' key.")


func can_entity_drop(dropped_data: Dictionary, mydropabletextedit: HBoxContainer):
	# Check if the data dictionary has the 'id' property
	if not dropped_data or not dropped_data.has("id"):
		return false
	
	# Fetch item data by ID from the Gamedata to ensure it exists and is valid
	var item_data = Gamedata.get_data_by_id(Gamedata.data.items, dropped_data["id"])
	if item_data.is_empty():
		return false

	# If all checks pass, return true
	return true


# Set the drop functions on the provided control. It should be a dropabletextedit
# This enables them to receive drop data
func set_drop_functions(mydropabletextedit):
	mydropabletextedit.drop_function = entity_drop.bind(mydropabletextedit)
	mydropabletextedit.can_drop_function = can_entity_drop.bind(mydropabletextedit)
