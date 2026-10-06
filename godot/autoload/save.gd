extends Node
## Progress save (prototype: localStorage['blastRanger2']) -> user://save.json

const PATH := "user://save.json"

var prog := {"unlocked": 1, "stars": {}, "blood": true, "music": true}
var enabled := true   # tests turn this off so they never touch the real save


func _ready() -> void:
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				prog.merge(d, true)


func save() -> void:
	if not enabled:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(prog))


func stars(i: int) -> int:
	return int(prog.stars.get(str(i), 0))


func record_win(i: int, n: int, level_count: int) -> void:
	prog.stars[str(i)] = maxi(stars(i), n)
	prog.unlocked = maxi(int(prog.unlocked), mini(level_count, i + 2))
	save()
