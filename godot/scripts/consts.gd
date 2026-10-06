class_name C
extends RefCounted
## Shared numbers, ported 1:1 from prototype/index.html.
##
## Unit conversion (Matter.js runs at a fixed 60 Hz step):
##   velocity  px/s    = Matter px/step   * 60   (STEP)
##   accel     px/s^2  = Matter px/step^2 * 3600
##   angular   rad/s   = Matter rad/step  * 60
##   mass      Godot mass = Matter mass (area * density), so impulse ratios stay identical
##   Matter.applyForce(F) for one step == Godot impulse F * FORCE_IMPULSE

const STEP := 60.0
const DT := 1000.0 / 60.0
const GS := 0.001 * DT * DT          # Matter gravity per step^2 (~0.2778 px/step^2 == 1000 px/s^2)
const FORCE_IMPULSE := DT * DT * STEP  # Matter force applied for one step -> Godot impulse
const AIR := 0.6                     # Matter default frictionAir 0.01/step == linear_damp 0.6/s

const R_GREN := 125.0
const P_GREN := 30.0
const R_ROCK := 110.0
const P_ROCK := 32.0
const R_BAR := 150.0
const P_BAR := 40.0

const MAT := {
	"wood":  {"density": 0.0015, "friction": 0.7,  "rest": 0.05, "hp": 18.0,
		"fill": Color("#d08a48"), "dark": Color("#8d5527"), "light": Color("#f0b06c")},
	"stone": {"density": 0.003,  "friction": 0.8,  "rest": 0.02, "hp": 1e9,
		"fill": Color("#a3acb8"), "dark": Color("#646d7a"), "light": Color("#cfd5dc")},
	"sand":  {"density": 0.0018, "friction": 0.8,  "rest": 0.02, "hp": 45.0,
		"fill": Color("#e2b66c"), "dark": Color("#a97c3a"), "light": Color("#f6d699")},
	"ice":   {"density": 0.0012, "friction": 0.03, "rest": 0.05, "hp": 7.0,
		"fill": Color(196 / 255.0, 236 / 255.0, 1.0, 0.88), "dark": Color("#5fb3df"), "light": Color("#ffffff")},
}

# Collision layers (bit values). A pair collides when (A.mask & B.layer) or (B.mask & A.layer).
const L_STATIC := 1     # ground, platforms, walls, pads, slopes
const L_BODY := 2       # blocks, boulders, barrels, rags, player
const L_ENEMY := 4      # Matter category 4
const L_BLOCKER := 8    # stone blocks: occlude blasts (layer only, used by ray queries)
const L_PROJ := 16      # player grenade / rocket
const L_MISSILE := 32   # enemy bullets (Matter EMF: never hit enemies)
const L_SOLID := 64     # blocks/boulders/barrels: block enemy line of sight (layer only)

const L_BALLOON := 128

const M_BODY := L_STATIC | L_BODY | L_ENEMY | L_PROJ | L_MISSILE
const M_ENEMY := L_STATIC | L_BODY | L_ENEMY | L_PROJ
const M_PROJ := L_STATIC | L_BODY | L_ENEMY | L_BALLOON
const M_MISSILE := L_STATIC | L_BODY | L_BALLOON

const CAUSES := {
	"self": ["Caught in your own blast", "Blasts hurt you too. Aim farther from yourself."],
	"enemy": ["Blown up", "Hit jetpack troopers before they get a throw off."],
	"barrel": ["A barrel went off too close", "Keep barrels at a distance before you set them off."],
	"bullet": ["Shot down", "Take out the green helmets first."],
	"arrow": ["Hit by arrows", "Archers shoot over cover. Get them early."],
	"sword": ["Cut down by a knight", "Lob grenades on top of knights before they reach you."],
	"crush": ["Crushed", "Watch out for heavy things flying your way."],
	"fall": ["You fell", "Explosions can push you off the edge."],
	"fire": ["Burned by dragon fire", "Lob a grenade into the dragon's mouth while it's open."],
	"titan": ["Smashed by a titan", "Only a hit to the glowing belly stops a titan."],
}

static func norm_a(a: float) -> float:
	return wrapf(a, -PI, PI)


static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	var l := d.length_squared()
	if l == 0.0:
		l = 1.0
	var t := clampf((p - a).dot(d) / l, 0.0, 1.0)
	return p.distance_to(a + d * t)
