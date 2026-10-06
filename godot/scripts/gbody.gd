class_name GBody
extends RigidBody2D
## A dynamic body. Mirrors a Matter body + its `plugin` bag.
## The node origin is the body's centre of mass (like Matter's body.position),
## so `loc` offsets and `wpt()` match the prototype.

var kind := ""            # block, boulder, barrel, enemy, player, rag, grenade, rocket, bullet
var p := {}               # per-kind data (Matter plugin)
var loc := {}             # named local anchor points (Matter plugin.loc)
var parts := []           # [{t:"rect", pos, size, rot} | {t:"circle", pos, r}] in local space
var prev_v := Vector2.ZERO  # velocity going into the current physics step (pre-impact)
var removed := false
var game: Node = null


func add_rect(pos: Vector2, size: Vector2, rot := 0.0) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	cs.rotation = rot
	add_child(cs)
	parts.append({"t": "rect", "pos": pos, "size": size, "rot": rot})


func add_circle(pos: Vector2, r: float) -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = r
	cs.shape = sh
	cs.position = pos
	add_child(cs)
	parts.append({"t": "circle", "pos": pos, "r": r})


func set_phys(friction: float, bounce: float) -> void:
	var m := PhysicsMaterial.new()
	m.friction = friction
	m.bounce = bounce
	physics_material_override = m


func set_air(frictionAir: float) -> void:
	# Matter frictionAir is a per-step velocity damping; Godot damp is per second.
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = frictionAir * C.STEP
	angular_damp = frictionAir * C.STEP


## Matter fires collisionStart per *part* pair, so a compound character can be hit on the
## head and the torso separately. body_shape_entered gives the same per-shape granularity.
func watch_contacts() -> void:
	contact_monitor = true
	max_contacts_reported = 16
	body_shape_entered.connect(_on_body_shape_entered)


func _on_body_shape_entered(_rid: RID, other: Node, _other_shape: int, _local_shape: int) -> void:
	if game and not removed and other != null:
		game.on_contact(self, other)


## Matter.js multiplies every body's geometric inertia by Body._inertiaScale = 4, and a
## compound body's inertia is the plain sum of its parts' (no parallel-axis term).
## Godot's automatic inertia is ~4x lower, which made towers and enemies tip far too easily.
func matter_inertia(part_masses: Array) -> void:
	var I := 0.0
	for i in parts.size():
		var pt: Dictionary = parts[i]
		var m: float = part_masses[i]
		if pt.t == "circle":
			I += m * pt.r * pt.r / 2.0
		else:
			I += m * (pt.size.x * pt.size.x + pt.size.y * pt.size.y) / 12.0
	inertia = 4.0 * I


func wpt(local: Vector2) -> Vector2:
	return global_position + local.rotated(global_rotation)


func alive() -> bool:
	return p.get("alive", false)


## World-space AABB of all parts (Matter body.bounds).
func aabb() -> Rect2:
	var r := Rect2()
	var first := true
	for pt in parts:
		var c: Vector2 = wpt(pt.pos)
		var e: Vector2
		if pt.t == "circle":
			e = Vector2(pt.r, pt.r)
		else:
			var a: float = global_rotation + pt.rot
			var hx: float = pt.size.x * 0.5
			var hy: float = pt.size.y * 0.5
			e = Vector2(absf(cos(a)) * hx + absf(sin(a)) * hy, absf(sin(a)) * hx + absf(cos(a)) * hy)
		var pr := Rect2(c - e, e * 2.0)
		r = pr if first else r.merge(pr)
		first = false
	return r
