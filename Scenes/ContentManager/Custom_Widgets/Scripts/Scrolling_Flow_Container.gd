extends Control

#This script belongs to the Scrolling_Flow_Container scene
#It shows a flowcontianer in a scrollcontainer and optionally a collapse button
#Once instanced, set the collapse button text to the text you want
#If you set the header as empty it will hide the collapse button

@export var contentItems: FlowContainer = null
@export var collapseButton: Button = null
var is_collapsed: bool = false
var header: String = "Items":
	set(newName):
		header = newName
		if newName == "":
			collapseButton.hide()
		else:
			collapseButton.show()
			collapseButton.text = header

#This function will collapse and expand the $Content/ContentItems when the collapse button is pressed
func _on_collapse_button_button_up():
	contentItems.visible = is_collapsed
	if is_collapsed:
		size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	is_collapsed = !is_collapsed

func add_content_item(item: Node):
	contentItems.add_child(item)
	
func get_content_items() -> Array[Node]:
	return contentItems.get_children()
