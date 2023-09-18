extends CharacterBody2D

var tween: Tween 
var original_scale

@export var sprite: NodePath
@export var stats: NodePath

@export var corpse_scene: PackedScene

@export var root: NodePath

@onready var nav_agent := $NavigationAgent2D  as NavigationAgent2D

func _ready():
	original_scale = get_node(sprite).scale
	
func _get_hit(damage):
	
	tween = create_tween()
	tween.tween_property(get_node(sprite), "scale", get_node(sprite).scale * 1.35, 0.1)
	tween.tween_property(get_node(sprite), "scale", original_scale, 0.1)
	
	get_node(stats).current_health -= damage
	if get_node(stats).current_health <= 0:
		_die()
	
func _die():
	var corpse = corpse_scene.instantiate()
	#$"../../../..".add_child(corpse)
	$"../../../..".call_deferred("add_child", corpse)
	corpse.global_position = global_position
	queue_free()
