extends Node
## Checks generated PCM, score structure, real-time envelopes, mute and UI wiring.
var fails := []

func check(ok: bool, label: String) -> void:
	print("AUDIO ", label, " ", "ok" if ok else "FAIL")
	if not ok:
		fails.append(label)

func _ready() -> void:
	Save.enabled = false
	var saved := Save.prog.duplicate(true)
	Save.prog.music = true
	var main = await TestUtil.boot(self)
	var a: RangerAudio = main.audio
	a.set_process(false)
	check(not a.music_running, "title waits for interaction")
	for key in RangerAudio.EFFECTS:
		var wav := a.effect_stream(key)
		var peak := 0
		var energy := 0.0
		for i in range(0, wav.data.size(), 2):
			var value := absi(wav.data.decode_s16(i))
			peak = maxi(peak, value)
			energy += float(value) * value
		var duration := 0.0
		for c in RangerAudio.EFFECTS[key]:
			duration = maxf(duration, c[3] + c[7])
		check(wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.mix_rate == 22050 and absf(wav.get_length() - duration) < .0001 and peak > 100 and energy > 10000, "%s PCM %.3fs peak %d" % [key, wav.get_length(), peak])
		check(a.effect_stream(key) == wav, key + " cached")
	# Frequency sweep and exponential decay are measurable in the actual generated WAV.
	var clink := a.effect_stream("clink").data
	var early := 0.0
	var late := 0.0
	var early_crossings := 0
	var late_crossings := 0
	var count := 220
	for i in count:
		var e := clink.decode_s16(i * 2)
		var l := clink.decode_s16(clink.size() - (count - i) * 2)
		early += e * e
		late += l * l
		if i > 0:
			if e * clink.decode_s16((i - 1) * 2) < 0:
				early_crossings += 1
			if l * clink.decode_s16(clink.size() - (count - i + 1) * 2) < 0:
				late_crossings += 1
	check(early > late * 50 and early_crossings > late_crossings, "clink pitch falls and decays")
	check(is_equal_approx(RangerAudio.STEP, 60.0 / 112 / 4), "112 BPM sixteenth notes")
	for bar in 4:
		var events := a.music_events(bar * 16)
		check(is_equal_approx(events[2][1], RangerAudio.midi(RangerAudio.CHORDS[bar][0] - 24)), "chord %d bass root" % bar)
	check(a.music_events(0).size() == 5 and a.music_events(8 * 16)[3][1] == a.music_events(0)[3][1] * 2 and a.music_events(24 * 16).size() == 3, "melody octave section and 8-bar rest")
	a.start_music()
	a.advance(.1)
	check(a.music_step == 1 and a.echoes.size() == 1, "first beat and melody echo scheduled")
	a.advance(2.0)
	check(a.music_step == 15 and a.music_gain > .39, "continuous score and startup fade")
	var before := a.music_gain
	a.sfx("boom")
	a.advance(.12)
	check(a.music_gain < before * .46 and a.music_gain > RangerAudio.VOLUME * .39, "explosion ducks to 40 percent in 30ms time constant")
	a.advance(.28)
	a.advance(.6)
	check(a.music_gain > .31 and a.music_gain < .34, "recovery begins after .4s with .6s time constant")
	a.sfx("boom")
	a.advance(.35)
	a.sfx("boom")
	a.advance(.35)
	check(a.music_gain < .18, "repeated blasts restart duck hold")
	a.advance(2)
	check(a.music_gain > .41, "duck recovers to .42")
	check(a.sfx("launch") and not a.sfx("launch"), "same-effect 40ms throttle")
	a.advance(.041)
	check(a.sfx("launch"), "effect resumes after 40ms")
	a.toggle_mute()
	check(a.muted and not a.sfx("hurt") and AudioServer.is_bus_mute(AudioServer.get_bus_index(a.music_bus)) and AudioServer.is_bus_mute(AudioServer.get_bus_index(a.sfx_bus)), "mute both buses and effects")
	a.toggle_mute()
	check(not a.muted and not AudioServer.is_bus_mute(AudioServer.get_bus_index(a.music_bus)), "unmute restores buses")
	main.hud.show_title()
	var toggle: Button = main.hud.card_box.find_child("MusicToggle", true, false)
	await get_tree().process_frame
	await get_tree().process_frame
	var toggle_rect := toggle.get_global_rect()
	check(toggle.toggle_mode and toggle.size.y >= 56, "music toggle has a full touch target")
	toggle.button_pressed = not toggle.button_pressed
	check(not Save.prog.music and not a.music_running and toggle.text == "Music: off", "title button persists music off")
	await get_tree().process_frame
	await get_tree().process_frame
	check(toggle.get_global_rect() == toggle_rect, "music switch does not move on label change")
	a.advance(2)
	check(a.music_gain < .0001 and a.echoes.is_empty(), "music stop fades and clears echoes")
	toggle.button_pressed = not toggle.button_pressed
	check(Save.prog.music and a.music_running and toggle.text == "Music: on" and a.music_step == 0, "title button restarts score")
	await Debug.start_level(0)
	a.advance(.1)
	Debug.set_aim(1, -.5, .5, "grenade")
	var launches: int = a.played.get("launch", 0)
	check(Debug.fire() and a.played.get("launch", 0) == launches + 1, "game launch event connected")
	a.advance(.05)
	var booms: int = a.played.get("boom", 0)
	Debug.game.explode(Vector2(-10000,-10000), 10, 40, null, "self")
	check(a.played.get("boom", 0) == booms + 1 and a.duck_until > a.clock_s, "game explosion triggers SFX and duck")
	var hurt: int = a.played.get("hurt", 0)
	Debug.game.damage_player(1, Vector2.RIGHT, null, "crush")
	check(a.played.get("hurt", 0) == hurt + 1, "player damage connected")
	Debug.game.state = "won"
	Debug.game.show_result.emit()
	check(a.played.get("win", 0) == 1, "result fanfare connected")
	Save.prog = saved
	main.queue_free()
	await get_tree().process_frame
	# Fixed-fps headless frames can outrun the Dummy audio thread. Give it one
	# real mixing interval to release stopped polyphonic voices before shutdown.
	OS.delay_msec(60)
	await get_tree().process_frame
	print("AUDIO RESULT: ", "PASS" if fails.is_empty() else "FAIL %s" % [fails])
	get_tree().quit(0 if fails.is_empty() else 1)
