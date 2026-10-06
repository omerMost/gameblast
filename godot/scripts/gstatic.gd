class_name GStatic
extends StaticBody2D
## A static level piece (ground / plat / wall / pad / slope).

var kind := "plat"
var size := Vector2.ZERO
var poly := PackedVector2Array()   # world-space corners, for drawing
var cracks := []                    # decorative crack polylines (world space)
var removed := false
