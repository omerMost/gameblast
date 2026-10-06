class_name Hud
extends CanvasLayer
## HUD + overlays (prototype UI section): level chip, enemies left, HP bar, weapon buttons,
## hint, title / level select / result cards, aim gizmo and screen flashes.

const INK := Color("#2a2140")
const PANEL := Color("#fff7e8")
const PANEL2 := Color("#ffe6bf")
const ACCENT := Color("#ff6a3d")
const ACCENT_D := Color("#c2441c")
const TEAL := Color("#17a99b")
const TEAL_D := Color("#0d7469")
const CHIP := Color(1, 1, 1, 0.93)
const SHADOW := Color(42 / 255.0, 33 / 255.0, 64 / 255.0, 0.25)

var main: Node
var game: Game
var disp: Font
var top_h := 70.0
var bot_h := 92.0

var lvl_lbl: Label
var foes_lbl: Label
var hp_bar: ColorRect
var hp_back: Control
var hp_inner: Control          # shaken on damage (prototype .hp.shake: 0.3 s, -4px at 25%, +4px at 75%)
var hp_shake_t := -1.0         # seconds into the shake, -1 = idle
var hp_base_x := 0.0
var hp_shakes := 0             # how many times the chip shook (tests)
var result_title := ""         # text of the last result card (tests read these, not pixels)
var result_text := ""
var w_btns := {}
var weapon_styles := {}
var weapon_selected := {}
var hint: Label
var fx_layer: Control
var dim: ColorRect
var card: PanelContainer
var card_box: VBoxContainer


func _ready() -> void:
	layer = 5
	disp = load("res://assets/fonts/lilita-one-latin.woff2") if ResourceLoader.exists("res://assets/fonts/lilita-one-latin.woff2") else ThemeDB.fallback_font
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	fx_layer = Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.draw.connect(_draw_fx)
	root.add_child(fx_layer)

	# --- top bar
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12; top.offset_right = -12; top.offset_top = 10; top.offset_bottom = 56
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	top.add_child(_icon_btn("≡", func(): main.open_levels()))
	lvl_lbl = _chip(top, "Level 1")
	foes_lbl = _chip(top, "● 0")
	foes_lbl.add_theme_color_override("font_color", Color("#f06a3b"))
	var hp_chip := PanelContainer.new()
	hp_chip.add_theme_stylebox_override("panel", _box(CHIP, 999, 4, 14, 12))
	top.add_child(hp_chip)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hp_chip.add_child(hb)
	hp_inner = hb
	var heart := Label.new()
	heart.text = "♥"
	heart.add_theme_color_override("font_color", Color("#ff4d5e"))
	heart.add_theme_font_size_override("font_size", 20)
	hb.add_child(heart)
	hp_back = Panel.new()
	hp_back.custom_minimum_size = Vector2(74, 10)
	hp_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_back.add_theme_stylebox_override("panel", _box(Color(42 / 255.0, 33 / 255.0, 64 / 255.0, 0.18), 6, 0))
	hb.add_child(hp_back)
	hp_bar = ColorRect.new()
	hp_bar.color = Color("#3fc46a")
	hp_bar.size = Vector2(74, 10)
	hp_back.add_child(hp_bar)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	top.add_child(_icon_btn("↻", func(): main.restart()))
	var sound := _icon_btn("♪", func():
		main.audio.toggle_mute())
	sound.pressed.connect(func(): sound.text = "×♪" if main.audio.muted else "♪")
	sound.tooltip_text = "Mute / unmute sound"
	top.add_child(sound)

	weapon_styles = {
		"selected": _box(ACCENT, 20, 5, 16, 8),
		"available": _box(CHIP, 20, 5, 16, 8),
		"disabled": _box(Color(CHIP, 0.45), 20, 5, 16, 8),
	}
	# --- weapon bar
	var wbar := HBoxContainer.new()
	wbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wbar.offset_top = -78; wbar.offset_bottom = -14
	wbar.alignment = BoxContainer.ALIGNMENT_CENTER
	wbar.add_theme_constant_override("separation", 12)
	wbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wbar)
	for w in ["grenade", "rocket"]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.icon = load("res://assets/images/" + w + ".svg")
		b.add_theme_constant_override("icon_max_width", 36)
		b.add_theme_constant_override("h_separation", 8)
		b.add_theme_font_override("font", disp)
		b.add_theme_font_size_override("font_size", 20)
		b.custom_minimum_size = Vector2(170, 56)
		b.pressed.connect(_pick.bind(w))
		wbar.add_child(b)
		w_btns[w] = b

	# --- hint
	hint = Label.new()
	hint.add_theme_font_override("font", disp)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_stylebox_override("normal", _box(Color(42 / 255.0, 33 / 255.0, 64 / 255.0, 0.85), 999, 0, 18, 10))
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.anchor_top = 0.22; hint.anchor_bottom = 0.22
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.visible = false
	root.add_child(hint)

	# --- overlay card
	dim = ColorRect.new()
	dim.color = Color(34 / 255.0, 24 / 255.0, 56 / 255.0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 0)
	card.add_theme_stylebox_override("panel", _box(PANEL, 28, 10, 22, 24))
	center.add_child(card)
	card_box = VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 14)
	card.add_child(card_box)
	dim.visible = false


func _process(dt: float) -> void:
	fx_layer.queue_redraw()
	if hp_shake_t >= 0:
		hp_shake_t += dt
		var k := hp_shake_t / 0.3
		var x := 0.0
		if k >= 1.0:
			hp_shake_t = -1.0
		elif k < 0.25:
			x = -4.0 * k / 0.25
		elif k < 0.75:
			x = -4.0 + 8.0 * (k - 0.25) / 0.5
		else:
			x = 4.0 * (1.0 - k) / 0.25
		hp_inner.position.x = hp_base_x + x


## Prototype damagePlayer(): restart the hpChip 'shake' animation.
func hurt(_dmg: int) -> void:
	if hp_shake_t < 0:
		hp_base_x = hp_inner.position.x
	hp_shake_t = 0.0
	hp_shakes += 1


# ---------------- widgets ----------------

func _box(bg: Color, radius: int, shadow: int, px := 0, py := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if shadow > 0:
		s.shadow_color = SHADOW
		s.shadow_offset = Vector2(0, shadow)
		s.shadow_size = 1
	s.content_margin_left = px; s.content_margin_right = px
	s.content_margin_top = py; s.content_margin_bottom = py
	return s


func _chip(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", disp)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_stylebox_override("normal", _box(CHIP, 999, 3, 14, 7))
	parent.add_child(l)
	return l


func _icon_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 44)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _box(CHIP, 14, 4))
	b.pressed.connect(cb)
	return b


func _big_btn(text: String, kind: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 54)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", disp)
	b.add_theme_font_size_override("font_size", 22)
	var bg := ACCENT if kind == "main" else (TEAL if kind == "alt" else PANEL2)
	var fc := INK if kind == "ghost" else Color.WHITE
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, fc)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _box(bg, 18, 6 if st != "pressed" else 2, 20, 10))
	b.pressed.connect(cb)
	return b


func _title(text: String, size: int, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", disp)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _text(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(316, 0)
	l.add_theme_color_override("font_color", Color(INK, 0.75))
	l.add_theme_font_size_override("font_size", 16)
	return l


func _row(btns: Array) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 12)
	for b in btns:
		r.add_child(b)
	return r


func _clear_card() -> void:
	for c in card_box.get_children():
		card_box.remove_child(c)
		c.queue_free()
	dim.visible = true


func blocking() -> bool:
	return dim.visible


func hide_overlay() -> void:
	dim.visible = false


# ---------------- screens ----------------

func show_title() -> void:
	_clear_card()
	card_box.add_child(_title("Blast", 60, ACCENT))
	card_box.add_child(_title("Ranger", 60, TEAL))
	card_box.add_child(_text("Topple towers, outlast knights and archers, and bend your shots through portals and black holes."))
	card_box.add_child(_big_btn("Play", "main", func(): main.play()))
	card_box.add_child(_big_btn("Choose level", "ghost", func(): main.open_levels()))
	var music := _setting_toggle("MusicToggle", "Music", Save.prog.music)
	music.toggled.connect(func(on: bool):
		if on != bool(Save.prog.music):
			main.audio.toggle_music()
		music.text = "Music: " + ("on" if on else "off"))
	var blood := _setting_toggle("BloodToggle", "Blood", Save.prog.blood)
	blood.toggled.connect(func(on: bool):
		Save.prog.blood = on
		Save.save()
		blood.text = "Blood: " + ("on" if on else "off"))
	card_box.add_child(_row([music, blood]))


func _setting_toggle(node_name: String, label: String, on: bool) -> Button:
	var button := _big_btn(label + ": " + ("on" if on else "off"), "ghost", func(): pass)
	button.name = node_name
	button.toggle_mode = true
	button.set_pressed_no_signal(on)
	button.custom_minimum_size = Vector2(152, 56)
	button.add_theme_font_size_override("font_size", 18)
	# Stable bounds and explicit colors for touch's emulated hover/pressed states.
	button.add_theme_stylebox_override("pressed", _box(TEAL, 18, 2, 16, 10))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	return button



func show_levels() -> void:
	_clear_card()
	card_box.add_child(_title("Levels", 36))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	card_box.add_child(grid)
	for i in game.available_levels():
		var open: bool = i < int(Save.prog.unlocked)
		var s := Save.stars(i)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(58, 58)
		b.add_theme_font_override("font", disp)
		b.add_theme_font_size_override("font_size", 18)
		b.text = ("%d\n%s%s" % [i + 1, "★".repeat(s), "☆".repeat(3 - s)]) if open else "🔒"
		var bg := ACCENT if open else PANEL2
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, _box(bg, 16, 5))
		b.disabled = not open
		if open:
			b.pressed.connect(main.start.bind(i))
		grid.add_child(b)
	card_box.add_child(_big_btn("Back", "ghost", func(): show_title()))


func show_result() -> void:
	_clear_card()
	if game.state == "won":
		var n := game.stars_for(game.shots)
		var last := game.next_level(game.level_idx) == -1
		result_title = "All clear!" if last else "Level cleared"
		result_text = "%s: %d shot%s (par %d), %d health left" % [game.L.name, game.shots, "" if game.shots == 1 else "s", game.L.par, game.player.p.hp]
		card_box.add_child(_title(result_title, 36))
		var st := HBoxContainer.new()
		st.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in 3:
			st.add_child(_title("★", 48, Color("#ffc93c") if i < n else PANEL2))
		card_box.add_child(st)
		card_box.add_child(_text(result_text))
		card_box.add_child(_row([_big_btn("Retry", "ghost", func(): main.restart()),
			_big_btn("Levels" if last else "Next level", "main", func(): show_levels() if last else main.start(game.next_level(game.level_idx)))]))
	else:
		var ko := game.lose_why == "ko"
		var c: Array = C.CAUSES.get(game.player.p.cause, C.CAUSES.crush)
		var n := game.alive_count()
		result_title = c[0] if ko else "Out of ammo"
		result_text = c[1] if ko else "%d enem%s still standing. Try a different angle or weapon." % [n, "y" if n == 1 else "ies"]
		card_box.add_child(_title(result_title, 36))
		card_box.add_child(_text(result_text))
		card_box.add_child(_row([_big_btn("Levels", "ghost", func(): show_levels()), _big_btn("Try again", "alt", func(): main.restart())]))


func set_hint(text: String) -> void:
	hint.text = text
	hint.visible = text != ""


func _pick(w: String) -> void:
	if game.ammo.get(w, 0) > 0:
		game.weapon = w
		refresh()


func refresh() -> void:
	if game == null or game.L.is_empty():
		return
	lvl_lbl.text = "Level %d" % (game.level_idx + 1)
	foes_lbl.text = "● %d" % game.alive_count()
	var hp: float = game.player.p.hp if game.player else 100.0
	hp_bar.size = Vector2(74 * hp / 100.0, 10)
	hp_bar.color = Color("#3fc46a") if hp > 50 else (Color("#ffb020") if hp > 25 else Color("#ff3b4e"))
	for w in w_btns:
		var b: Button = w_btns[w]
		var n: int = game.ammo.get(w, 0)
		b.visible = game.L.ammo.get(w, 0) > 0
		b.text = "%s  ×%d" % [w.capitalize(), n]
		b.disabled = n == 0
		var sel: bool = game.weapon == w and n > 0
		if weapon_selected.get(w, null) == sel:
			continue
		weapon_selected[w] = sel
		var fc := Color.WHITE if sel else INK
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(c, fc if c != "font_disabled_color" else Color(INK, 0.45))
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, weapon_styles["disabled" if st == "disabled" else ("selected" if sel else "available")])


func _draw_fx() -> void:
	if game == null:
		return
	var sz := fx_layer.size
	if game.flash_a > 0:
		fx_layer.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 248 / 255.0, 220 / 255.0, game.flash_a))
	if game.hurt_a > 0:
		var a := game.hurt_a
		var e := minf(sz.x, sz.y) * 0.18
		var c0 := Color(220 / 255.0, 20 / 255.0, 40 / 255.0, a)
		var c1 := Color(220 / 255.0, 20 / 255.0, 40 / 255.0, 0)
		fx_layer.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), Vector2(sz.x, e), Vector2(0, e)]), PackedColorArray([c0, c0, c1, c1]))
		fx_layer.draw_polygon(PackedVector2Array([Vector2(0, sz.y - e), Vector2(sz.x, sz.y - e), sz, Vector2(0, sz.y)]), PackedColorArray([c1, c1, c0, c0]))
		fx_layer.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(e, 0), Vector2(e, sz.y), Vector2(0, sz.y)]), PackedColorArray([c0, c1, c1, c0]))
		fx_layer.draw_polygon(PackedVector2Array([Vector2(sz.x - e, 0), Vector2(sz.x, 0), sz, Vector2(sz.x - e, sz.y)]), PackedColorArray([c1, c0, c0, c1]))
	var d = main.drag
	if d != null and game.aim.active:
		var a0 := Vector2(d.x0, d.y0)
		var a1 := Vector2(d.x, d.y)
		fx_layer.draw_circle(a0, 24, Color(1, 1, 1, 0.25))
		fx_layer.draw_arc(a0, 24, 0, TAU, 32, Color(1, 1, 1, 0.8), 2)
		fx_layer.draw_dashed_line(a0, a1, Color(1, 1, 1, 0.85), 3, 7)
		fx_layer.draw_circle(a1, 10, ACCENT if game.aim.pow > 0.95 else Color.WHITE)
