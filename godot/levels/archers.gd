class_name ArcherLevel
extends RefCounted
## Prototype level 19; stays reusable until the complete indexed level table is integrated.
const DATA := {"name": "Archers", "view": [0, 240, 960, 480], "ammo": {"grenade": 3, "rocket": 2}, "par": 3, "hint": "Archers lob arrows over cover", "build": [
	["ground", 0, 190, 560], ["ground", 190, 1000, 650], ["ground", 700, 1000, 540],
	["block", 722, 540, 16, 60, "wood"], ["enemy", 780, 540, {"archer": true}], ["enemy", 860, 540, {"archer": true}], ["enemy", 600, 650]
]}
