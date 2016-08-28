
tool

extends KinematicBody2D

export(float) var speed = 100
var _health = 100
var path_selection_ring = "sprite/viewport/Spatial/Circle"
var path_target_ring = "sprite/viewport/Spatial/attack_circle"
var path_mesh  = "sprite/viewport/Spatial/armature/Skeleton/body"
var path_armature = "sprite/viewport/Spatial/armature"
var path_sword = "sprite/viewport/Spatial/armature/Skeleton/right_hand/sword"
var path_spear = "sprite/viewport/Spatial/armature/Skeleton/right_hand/spear"
var path_bow = "sprite/viewport/Spatial/armature/Skeleton/left_hand/bow"

var attack_range = [32,32,64,256] setget ,get_attack_range #getter only
var attack = [1,10,15,20] setget ,get_attack #getter only
var defense = [0,15,10,5] setget ,get_defense #getter only

var path = []

var target = null
var target_pos = null
onready var selection_ring = get_node(path_selection_ring)
onready var attack_ring = get_node(path_target_ring)
onready var armature = get_node(path_armature)
onready var mesh = get_node(path_mesh)
var _team
var _weapon
var anim
func _init():
	add_to_group("unit")
var is_Ready = false
func _ready():
	anim = get_node("sprite/viewport/Spatial/AnimationPlayer")
	is_Ready = true
	mesh.set_mesh(mesh.get_mesh().duplicate(true))
	var material = mesh.get_mesh().surface_get_material(0).duplicate(true)
	mesh.get_mesh().surface_set_material(0,material)
	if get_tree().is_editor_hint(): return
	selection_ring.hide()
	attack_ring.hide()
	set_fixed_process(true)
	var timer_path = Timer.new()
	add_child(timer_path)
	timer_path.connect("timeout",self,"calculate_target_route")
	timer_path.set_one_shot(false)
	timer_path.start()
	pass

func _unhandled_input(ev):
	if get_tree().is_editor_hint(): return
	if ev.type == InputEvent.MOUSE_BUTTON && ev.button_index == BUTTON_RIGHT && ev.is_pressed():
		var mouse_pos = get_global_mouse_pos()
		target = null
		for u in get_tree().get_nodes_in_group("unit"):
			if u == self: continue
			var r = u.get_item_rect()
			r.pos += u.get_global_pos()
			if r.has_point(mouse_pos):
				target = u
				u.focused()
				break;
			
			target_pos = get_global_mouse_pos()
			calculate_route(target_pos)

func calculate_target_route():
	if get_tree().is_editor_hint(): return
	if target != null:
		if (target.get_global_pos() - get_global_pos()).length_squared() >= 64*64:
			calculate_route(target.get_global_pos())

func calculate_route(to):
	if get_tree().is_editor_hint(): return
	var nav = Globals.get("level").nav
#	nav = Navigation2D.new() #luego lo borro, es para autocompletar
	path = nav.get_simple_path(get_global_pos(), to, false)
	path.remove(0)

const attack_anims = ["idle","sword","spear","bow"]
func _fixed_process(delta):
	if target != null && !target.is_queued_for_deletion():
		if target._team != _team && get_global_pos().distance_squared_to(target.get_global_pos()) <= pow(self.attack_range,2):
			print("attack")
			path = []
			armature.set_rotation(Vector3(0,Vector2(0,1).angle_to(target.get_global_pos()-get_global_pos()),0))
			set_fixed_process(false)
			anim.play(attack_anims[_weapon])
			yield(anim,"finished")
			if target != null: #in case he died
				var dmg = self.attack - target.defense
				dmg = clamp(dmg,1,100)
				if is_strong_agains(target):
					dmg * 2
				target._set("health",target._health-dmg)
				set_fixed_process(true)

	if get_tree().is_editor_hint(): return
	if path.size() > 0:
		if !anim.get_current_animation() == "walk":
			anim.play("walk")
		var from = get_global_pos()
		var to = path[0]
		var motion = to-from
		var now = motion.normalized() * delta * speed
		if (motion.length_squared() < now.length_squared()):
			now = motion
			path.remove(0)
		armature.set_rotation(Vector3(0,Vector2(0,1).angle_to(motion),0))
		if move(now).length_squared() > 0:
			if target_pos != null && (target_pos - get_global_pos()).length_squared() <= 64*64:
				path = []
				return
			calculate_route(target_pos)
			var desviation = get_collision_normal()
			desviation = Vector2(desviation.y, -desviation.x) * 32
			path.insert(0,get_global_pos()+desviation)
	else:
		if !anim.get_current_animation() == "idle":
			anim.play("idle")

func is_strong_agains(other):
	if abs(_weapon-other._weapon) == 1:
		return true
	return false

func select():
	if get_tree().is_editor_hint(): return
	set_process_unhandled_input(true)
	selection_ring.show()

func unselect():
	if get_tree().is_editor_hint(): return
	set_process_unhandled_input(false)
	selection_ring.hide()

func focused():
	for i in range(0,3):
		attack_ring.show()
		yield(get_tree().create_timer(0.2),"timeout")
		attack_ring.hide()
		yield(get_tree().create_timer(0.2),"timeout")

#region getters&setters

func _get_property_list():
	var properties = []
	var d = {}
	d.name = "health"
	d.type = TYPE_INT
	d.hint = PROPERTY_HINT_RANGE
	d.hint_string = "0,100,1"
	properties.push_back(d)
	var d = {}
	d.name = "team"
	d.type = TYPE_INT
	d.hint = PROPERTY_HINT_ENUM
	d.hint_string = "RED,GREEN"
	properties.push_back(d)
	var d = {}
	d.name = "weapon"
	d.type = TYPE_INT
	d.hint = PROPERTY_HINT_ENUM
	d.hint_string = "NONE,SWRDMAN,SPEARMAN,BOWMAN"
	properties.push_back(d)
	return properties;

func _get(property):
	if (property == "health"):
		return _health
	if (property == "team"):
		return _team
	if property == "weapon":
		return _weapon

const colors = [Color(0.64,0.043096,0.043096),Color(0.242203,0.8125,0.177734)]
func _set(property, value):
	if (property == "health"):
		_health = value
		var bar = get_node("health")
		if (_health <= 0 && !get_tree().is_editor_hint()):
			queue_free()
			return
		if bar != null:
			bar.set_val(value)
	if (property == "team"):
		call_deferred("set_armor_color",value)
		_team = value
	if property == "weapon":
		call_deferred("change_weapon",value)
		_weapon = value

func change_weapon(w):
	if w == 0: #NONE
		get_node(path_sword).hide()
		get_node(path_spear).hide()
		get_node(path_bow).hide()
	if w == 1: #SWORDMAN
		get_node(path_sword).show()
		get_node(path_spear).hide()
		get_node(path_bow).hide()
	if w == 2: #SPEARMAN
		get_node(path_sword).hide()
		get_node(path_spear).show()
		get_node(path_bow).hide()
	if w == 3: #BOWMAN
		get_node(path_sword).hide()
		get_node(path_spear).hide()
		get_node(path_bow).show()

func set_armor_color(c):
	if c == null: return
	var mesh = get_node(path_mesh)
	if mesh != null:
		mesh.get_mesh().surface_get_material(0).set_parameter(0,colors[c])

func get_attack_range():
	return attack_range[_weapon]

func get_attack():
	return attack[_weapon]

func get_defense():
	return defense[_weapon]