class_name Levels
extends RefCounted
## LEVELS[] from prototype/index.html, as data. Same order, same numbers.
## `build` is a list of builder ops replayed by LevelBuilder:
##   ["ground", x1, x2, top]            ["plat", x1, x2, top, th?]
##   ["wall", x1, y1, x2, y2]           ["pad", x1, y1, x2, y2]
##   ["slope", x1, y1, x2, y2, th?]     ["block", cx, bottom, w, h, mat]
##   ["enemy", x, bottom, {opts}]       ["boulder", cx, bottom, r]
##   ["barrel", cx, bottom]
## Stage 1 ports levels 1-5. Stage 3 adds the rest.

const SH := {"shooter": true}

const LEVELS := [
	{"name": "Warm-up", "view": [0, 300, 820, 420], "ammo": {"grenade": 3}, "par": 1,
		"hint": "Drag back, aim, let go",
		"build": [
			["ground", 0, 190, 560], ["ground", 190, 900, 650],
			["block", 430, 650, 30, 70, "wood"], ["block", 430, 580, 30, 70, "wood"],
			["enemy", 560, 650], ["enemy", 650, 650],
		]},
	{"name": "Two floors", "view": [0, 260, 820, 460], "ammo": {"grenade": 2, "rocket": 1}, "par": 2,
		"build": [
			["ground", 0, 190, 560], ["ground", 190, 900, 650],
			["block", 490, 650, 22, 100, "wood"], ["block", 630, 650, 22, 100, "wood"], ["block", 560, 550, 180, 18, "wood"],
			["block", 505, 532, 20, 90, "wood"], ["block", 615, 532, 20, 90, "wood"], ["block", 560, 442, 150, 16, "wood"],
			["enemy", 560, 650], ["enemy", 560, 532], ["enemy", 560, 426],
		]},
	{"name": "Rolling stone", "view": [0, 280, 840, 440], "ammo": {"rocket": 2, "grenade": 1}, "par": 2,
		"build": [
			["ground", 0, 190, 560], ["ground", 190, 900, 650], ["ground", 380, 560, 470],
			["block", 420, 470, 18, 18, "wood"], ["block", 460, 470, 18, 18, "wood"], ["boulder", 440, 452, 38],
			["enemy", 530, 470], ["enemy", 620, 650], ["enemy", 690, 650], ["enemy", 760, 650],
		]},
	{"name": "Hot stuff", "view": [0, 300, 880, 420], "ammo": {"grenade": 2}, "par": 1,
		"build": [
			["ground", 0, 190, 560], ["ground", 190, 940, 650], ["ground", 380, 410, 480],
			["barrel", 520, 650], ["enemy", 575, 650], ["barrel", 630, 650], ["enemy", 685, 650], ["enemy", 745, 650], ["barrel", 800, 650],
		]},
	{"name": "Portal", "view": [0, 300, 880, 420], "ammo": {"grenade": 2, "rocket": 1}, "par": 1,
		"hint": "Shoot into the green portal",
		"portals": [{"a": [300, 420], "b": [560, 520]}],
		"build": [
			["ground", 0, 190, 560], ["ground", 190, 900, 650],
			["wall", 420, 410, 450, 650], ["wall", 800, 410, 830, 650], ["wall", 420, 410, 830, 450],
			["enemy", 650, 650], ["enemy", 720, 650], ["barrel", 775, 650],
		]},
]
