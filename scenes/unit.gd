
tool

extends KinematicBody2D

export(float) var speed = 100
var path_selection_ring = "sprite/viewport/Spatial/Circle"
var path_mesh  = "sprite/viewport/Spatial/armature/Skeleton/body"
var path_armature = "sprite/viewport/Spatial/armature"
var path_sword = "sprite/viewport/Spatial/armature/Skeleton/BoneAttachment/Spatial"
var path_spear = "sprite/viewport/Spatial/armature/Skeleton/BoneAttachment/Spatial 2"
var path_bow = "sprite/viewport/Spatial/armature/Skeleton/BoneAttachment/Spatial 3"

var attack_range = [32,32,64,256] setget ,get_attack_range #getter only

var path = []

var target = null
var target_pos = null
onready var selection_ring = get_node(path_selection_ring)
onready var armature = get_node(path_armature)
onready var mesh = get_node(path_mesh)
var team
var weapon
func _init():
	add_to_group("unit")
var is_Ready = false
func _ready():
	is_Ready = true
	mesh.set_mesh(mesh.get_mesh().duplicate(true))
	var material = mesh.get_mesh().surface_get_material(0).duplicate(true)
	mesh.get_mesh().surface_set_material(0,material)
	if get_tree().is_editor_hint(): return
	selection_ring.hide()
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

func _fixed_process(delta):
	if target != null:
		if target.team != team && get_global_pos().distance_squared_to(target.get_global_pos()) <= pow(self.attack_range,2):
			print("attack")
			path = []
			set_fixed_process(false)
			yield(get_tree().create_timer(1),"timeout")
			set_fixed_process(true)

	if get_tree().is_editor_hint(): return
	if path.size() > 0:
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


func select():
	if get_tree().is_editor_hint(): return
	set_process_unhandled_input(true)
	selection_ring.show()

func unselect():
	if get_tree().is_editor_hint(): return
	set_process_unhandled_input(false)
	selection_ring.hide()

#region getters&setters

func _get_property_list():
	var properties = []
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

const colors = [Color(0.64,0.043096,0.043096),Color(0.242203,0.8125,0.177734)]
func _set(property, value):
	print(property+" -> "+str(value))
	if (property == "team"):
		var mesh = get_node(path_mesh)
		if mesh != null:
			mesh.get_mesh().surface_get_material(0).set_parameter(0,colors[value])
			team = value
	if property == "weapon":
		if value == 0: #NONE
			get_node(path_sword).hide()
			get_node(path_spear).hide()
			get_node(path_bow).hide()
		if value == 1: #SWORDMAN
			get_node(path_sword).show()
			get_node(path_spear).hide()
			get_node(path_bow).hide()
		if value == 2: #SPEARMAN
			get_node(path_sword).hide()
			get_node(path_spear).show()
			get_node(path_bow).hide()
		if value == 3: #BOWMAN
			get_node(path_sword).hide()
			get_node(path_spear).hide()
			get_node(path_bow).show()
		weapon = value

func _get(property):
	if (property == "team"):
		return team
	if property == "weapon":
		return weapon

func get_attack_range():
	return attack_range[weapon]