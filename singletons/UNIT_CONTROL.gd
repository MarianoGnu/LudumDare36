
extends Node2D

var selected = []
var dragging = false
var selection_from = Vector2()
var selection_rect = Rect2()

func _ready():
	enable()

func enable():
	set_process_input(true)

func disable():
	set_process_input(false)

func _input(ev):
	if ev.type == InputEvent.MOUSE_BUTTON:
		if ev.button_index == BUTTON_LEFT:
			if ev.is_pressed():
				selection_from = get_global_mouse_pos()
				dragging = true
				update()
				get_tree().set_input_as_handled()
			else:
				if dragging:
					dragging = false
					var selection_to = get_global_mouse_pos()
					for u in get_tree().get_nodes_in_group("unit"):
						if selection_rect.has_point(u.get_global_pos()):
							u.select()
						else:
							u.unselect()
				
				selection_rect = Rect2()
				update()
	elif ev.type == InputEvent.MOUSE_MOTION:
		if dragging:
			var selection_to = get_global_mouse_pos()
			selection_rect = Rect2(selection_from,selection_to-selection_from)
			update()

func _draw():
	draw_rect(selection_rect, Color(0.271606,0.476839,0.695313,0.587775))