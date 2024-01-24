extends Node3D

var weapon
var magazine
var ammo

var current_ammo : int
var max_ammo : int



# Define properties for left-hand and right-hand weapons.
var left_hand_weapon
var right_hand_weapon
var left_hand_magazine
var right_hand_magazine
var left_hand_ammo
var right_hand_ammo

var current_left_ammo : int
var max_left_ammo : int
var current_right_ammo : int
var max_right_ammo : int

signal ammo_changed(current_ammo: int, max_ammo: int, leftHand: bool)

@export var projectiles: NodePath
@export var bullet_speed: float
@export var bullet_damage: float
#@export var cooldown = 0.25
@export var bullet_scene: PackedScene

@export var bullet_line_scene: PackedScene

@export var left_attack_cooldown : Timer
@export var right_attack_cooldown : Timer
@export var left_reload_timer : Timer
@export var right_reload_timer : Timer


@export var player: NodePath
@export var hud: NodePath

@export var shoot_audio_player : AudioStreamPlayer3D
@export var shoot_audio_randomizer : AudioStreamRandomizer

@export var reload_audio_player : AudioStreamPlayer3D
#@export var reload_audio_randomizer : AudioStreamRandomizer

var damage = 25


func _input(event):
	if not weapon:
		return  # Return early if no weapon is equipped
	
	if event.is_action_pressed("reload_weapon"):
		# Reload logic for both weapons with additional checks.
		if left_hand_weapon and current_left_ammo < max_left_ammo and right_reload_timer.is_stopped():
			reload_left_weapon()
		elif right_hand_weapon and current_right_ammo < max_right_ammo and left_reload_timer.is_stopped():
			reload_right_weapon()

	# Handling left and right click for different weapons.
	if event.is_action_pressed("click_left") and General.is_mouse_outside_HUD and General.is_allowed_to_shoot:
		fire_weapon(left_hand_weapon, current_left_ammo, max_left_ammo, "left")

	if event.is_action_pressed("click_right") and General.is_mouse_outside_HUD and General.is_allowed_to_shoot:
		fire_weapon(right_hand_weapon, current_right_ammo, max_right_ammo, "right")

# New function to handle firing logic for a weapon.
func fire_weapon(weapon, current_ammo, max_ammo, hand):
	if not weapon or current_ammo <= 0:
		return  # Return if no weapon is equipped or no ammo.
	
	
	var cooldown_timer = get_cooldown_timer(hand)
	if cooldown_timer.is_stopped() and reload_timer_is_stopped(hand):
		cooldown_timer.start()
		# Update ammo and emit signal.
		if hand == "left":
			current_left_ammo -= 1
			ammo_changed.emit(current_left_ammo, max_left_ammo, true)
		elif hand == "right":
			current_right_ammo -= 1
			ammo_changed.emit(current_right_ammo, max_right_ammo, false)
			
		
		shoot_audio_player.stream = shoot_audio_randomizer
		shoot_audio_player.play()
		
		var space_state = get_world_3d().direct_space_state
		var mouse_pos : Vector2 = get_viewport().get_mouse_position()
		
		var layer = pow(2, 1-1) + pow(2, 2-1) + pow(2, 3-1)
		var mouse_pos_in_world = Helper.raycast_from_mouse(mouse_pos, layer).position
		var query = PhysicsRayQueryParameters3D.create(global_position, global_position + (Vector3(mouse_pos_in_world.x - global_position.x, 0, mouse_pos_in_world.z - global_position.z)).normalized() * 10000, layer, [self])

		var result = space_state.intersect_ray(query)
		
		if result:
			print("hit")
			Helper.line(global_position, result.position)
			
			if result.collider.has_method("_get_hit"):
				result.collider._get_hit(damage)


# Helper function to get the appropriate cooldown timer based on the hand.
func get_cooldown_timer(hand: String) -> Timer:
	if hand == "left":
		return left_attack_cooldown
	else:
		return right_attack_cooldown

# Helper function to check if reload timer is stopped based on the hand.
func reload_timer_is_stopped(hand: String) -> bool:
	if hand == "left":
		return left_reload_timer.is_stopped()
	else:
		return right_reload_timer.is_stopped()

# Called when the left weapon is reloaded
# Since only one reload action can run at a time, 
# We check that the right reload timer is stopped
func reload_left_weapon():
	if right_reload_timer.is_stopped():
		# Logic to reload left-hand weapon.
		current_left_ammo = max_left_ammo
		left_reload_timer.start()  # Start the left reload timer
		ammo_changed.emit(current_left_ammo, max_left_ammo, true)

# Called when the right weapon is reloaded
# Since only one reload action can run at a time, 
# We check that the left reload timer is stopped
func reload_right_weapon():
	if left_reload_timer.is_stopped():
		# Logic to reload right-hand weapon.
		current_right_ammo = max_right_ammo
		right_reload_timer.start()  # Start the right reload timer
		ammo_changed.emit(current_right_ammo, max_right_ammo, false)



# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize without assigning a default weapon, magazine, or ammo.
	weapon = null
	magazine = null
	ammo = null
	current_ammo = 0
	max_ammo = 0



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Check if the left-hand weapon is reloading.
	if left_reload_timer.is_started() and not left_reload_timer.is_stopped() and left_reload_timer.time_left <= reload_audio_player.stream.get_length() and not reload_audio_player.playing:
		reload_audio_player.play()  # Play reload sound for left-hand weapon.

	# Check if the right-hand weapon is reloading.
	if right_reload_timer.is_started() and not right_reload_timer.is_stopped() and right_reload_timer.time_left <= reload_audio_player.stream.get_length() and not reload_audio_player.playing:
		reload_audio_player.play()  # Play reload sound for right-hand weapon.


# The weapon is reloaded once the timer has stopped
func _on_reload_time_timeout():
	if left_reload_timer.is_stopped() and left_hand_weapon:
		current_left_ammo = max_left_ammo
		ammo_changed.emit(current_left_ammo, max_left_ammo, true)

	if right_reload_timer.is_stopped() and right_hand_weapon:
		current_right_ammo = max_right_ammo
		ammo_changed.emit(current_right_ammo, max_right_ammo, false)


# The player has equipped an item in one of the equipmentslots
# equippedItem is an InventoryItem
# slotName is a string, for example "LeftHand" or "RightHand"
func _on_hud_item_was_equipped(equippedItem: InventoryItem, slotName: String):
	# Adjust this function to handle dual-wielding.
	var weaponID = equippedItem.prototype_id
	var weaponData = Gamedata.get_data_by_id(Gamedata.data.items, weaponID)
	if weaponData.has("Ranged"):
		var newMagazineID = weaponData.Ranged.used_magazine
		var newAmmoID = weaponData.Ranged.used_ammo
		# Set the weapon for the corresponding hand.
		if slotName == "LeftHand":
			left_hand_weapon = weaponData
			left_hand_magazine = Gamedata.get_data_by_id(Gamedata.data.items, newMagazineID)
			left_hand_ammo = Gamedata.get_data_by_id(Gamedata.data.items, newAmmoID)
			max_left_ammo = int(left_hand_magazine.Magazine["max_ammo"])
			current_left_ammo = max_left_ammo
		elif slotName == "RightHand":
			right_hand_weapon = weaponData
			right_hand_magazine = Gamedata.get_data_by_id(Gamedata.data.items, newMagazineID)
			right_hand_ammo = Gamedata.get_data_by_id(Gamedata.data.items, newAmmoID)
			max_right_ammo = int(right_hand_magazine.Magazine["max_ammo"])
			current_right_ammo = max_right_ammo
		# Check for two-handed weapon and adjust accordingly.
		if weaponData.Ranged.two_handed:
			if slotName == "LeftHand":
				right_hand_weapon = null  # Clear the right hand if a two-handed weapon is equipped in the left hand.
			elif slotName == "RightHand":
				left_hand_weapon = null  # Clear the left hand if a two-handed weapon is equipped in the right hand.
	else:
		# Reset weapon, magazine, and ammo if the equipped item is not a weapon.
		if slotName == "LeftHand":
			left_hand_weapon = null
			left_hand_magazine = null
			left_hand_ammo = null
			current_left_ammo = 0
			max_left_ammo = 0
		elif slotName == "RightHand":
			right_hand_weapon = null
			right_hand_magazine = null
			right_hand_ammo = null
			current_right_ammo = 0
			max_right_ammo = 0
