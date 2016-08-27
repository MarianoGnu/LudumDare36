
extends Node2D

onready var nav = get_node("nav")


func _enter_tree():
	Globals.set("level", self)


