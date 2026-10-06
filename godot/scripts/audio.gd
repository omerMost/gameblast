class_name RangerAudio
extends Node
## Procedural Web Audio score / effects from prototype/index.html SOUND & MUSIC.
## PCM is generated lazily and cached; audio randomness never touches the game RNG.

const RATE := 22050
const STEP := 60.0 / 112.0 / 4.0
const VOLUME := 0.42
const CHORDS := [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]]
const MELODY := [
	[[0,72],[3,76],[6,79],[8,76],[10,74],[12,72]],
	[[0,71],[3,74],[6,79],[10,74],[12,71],[14,67]],
	[[0,72],[3,76],[6,81],[8,79],[10,76],[12,72]],
	[[0,77],[2,76],[4,72],[8,69],[12,72]],
	[[0,79],[2,76],[4,72],[6,76],[8,79],[12,84]],
	[[0,83],[4,79],[6,74],[8,79],[10,83]],
	[[0,81],[2,79],[4,76],[8,72],[10,76]],
	[[0,77],[4,72],[6,69],[8,72],[12,74]]]
# component: [kind, start frequency/filter cutoff, end frequency, duration,
# gain, waveform/filter, noise decay, start delay]. Values mirror sfx() verbatim.
const EFFECTS := {
	"boom": [["noise",700,0,1.1,.8,"lowpass",3,0],["tone",95,35,.6,.7,"sine",0,0]],
	"launch": [["noise",1400,0,.3,.35,"bandpass",2,0],["tone",320,120,.15,.2,"sine",0,0]],
	"clink": [["tone",1300,800,.06,.07,"triangle",0,0]],
	"pop": [["tone",540,170,.16,.18,"sine",0,0]],
	"splat": [["noise",500,0,.35,.5,"lowpass",2,0],["tone",200,60,.25,.3,"sine",0,0]],
	"hurt": [["tone",260,140,.2,.25,"square",0,0],["noise",900,0,.12,.3,"lowpass",2,0]],
	"shot": [["noise",1200,0,.14,.35,"highpass",4,0],["tone",180,70,.08,.2,"sine",0,0]],
	"ric": [["tone",2400,900,.12,.05,"triangle",0,0]],
	"alert": [["tone",880,1200,.12,.08,"square",0,0]],
	"warp": [["tone",200,1400,.25,.12,"sawtooth",0,0],["tone",1400,300,.3,.08,"sine",0,0]],
	"bow": [["tone",160,90,.12,.15,"triangle",0,0],["noise",2500,0,.1,.15,"highpass",3,0]],
	"thunk": [["tone",220,90,.08,.2,"triangle",0,0]],
	"swing": [["noise",2200,0,.2,.25,"bandpass",1.5,0]],
	"clang": [["tone",1800,1500,.25,.1,"square",0,0],["tone",2700,2400,.2,.06,"triangle",0,0]],
	"jump": [["tone",200,380,.12,.1,"triangle",0,0]],
	"toss": [["noise",1800,0,.15,.2,"bandpass",2,0]],
	"snap": [["noise",3000,0,.08,.4,"highpass",3,0],["tone",600,200,.08,.12,"triangle",0,0]],
	"balloon": [["noise",1500,0,.07,.6,"highpass",4,0]],
	"roar": [["noise",500,0,.9,.45,"lowpass",1.2,0],["tone",140,70,.8,.25,"sawtooth",0,0]],
	"fire": [["noise",900,0,.3,.25,"bandpass",1.5,0]],
	"gulp": [["tone",400,90,.25,.3,"sine",0,0],["tone",200,60,.3,.2,"triangle",0,0]],
	"stomp": [["tone",70,35,.25,.4,"sine",0,0],["noise",300,0,.15,.2,"lowpass",2,0]],
	"smash": [["noise",400,0,.5,.7,"lowpass",2,0],["tone",90,30,.4,.5,"sine",0,0]],
	"win": [["tone",523,528.23,.2,.15,"triangle",0,0],["tone",659,665.59,.2,.15,"triangle",0,.11],["tone",784,791.84,.2,.15,"triangle",0,.22],["tone",1047,1057.47,.2,.15,"triangle",0,.33]],
	"lose": [["tone",330,110,.55,.15,"triangle",0,0]]}

var game: Game
var muted := false
var music_running := false
var music_step := 0
var music_gain := 0.0
var clock_s := 0.0
var next_step := 0.0
var duck_until := -1.0
var last_sfx := {}
var played := {} # diagnostic event counts (includes dummy audio-driver tests)
var cache := {}
var rng := RandomNumberGenerator.new()
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_bus := "BlastMusic"
var sfx_bus := "BlastSfx"
var echoes := []

func _ready() -> void:
	rng.randomize()
	for bus in [music_bus, sfx_bus]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	sfx_player = _player(sfx_bus, 32)
	music_player = _player(music_bus, 64)
	_apply_gain()
	if OS.get_name() == "Android":
		# Generate effects on the launch screen, before the first impact.
		for key in EFFECTS:
			effect_stream(key)

func _exit_tree() -> void:
	sfx_player.stop()
	music_player.stop()
	echoes.clear()
	cache.clear()

func _player(bus: String, polyphony: int) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	var stream := AudioStreamPolyphonic.new()
	stream.polyphony = polyphony
	p.stream = stream
	add_child(p)
	p.play()
	return p

func start_music() -> void:
	if music_running or not Save.prog.music:
		return
	music_running = true
	if not music_player.playing:
		music_player.play()
	music_step = 0
	next_step = clock_s + 0.1
	duck_until = -1.0

func stop_music() -> void:
	music_running = false
	echoes.clear()

func toggle_music() -> void:
	Save.prog.music = not Save.prog.music
	Save.save()
	if Save.prog.music:
		start_music()
	else:
		stop_music()

func toggle_mute() -> void:
	muted = not muted
	start_music()
	_apply_gain()

func duck() -> void:
	if music_running and not muted:
		duck_until = clock_s + 0.4

func hurt(_damage: int) -> void:
	sfx("hurt")
	duck()

func result() -> void:
	sfx("win" if game.state == "won" else "lose")

func sfx(key: String, gain := 1.0) -> bool:
	if muted or not EFFECTS.has(key):
		return false
	if clock_s - float(last_sfx.get(key, -100.0)) < 0.04:
		return false
	last_sfx[key] = clock_s
	# Only boom and clink use the optional gain in the prototype.
	var scale: float = gain if key in ["boom", "clink"] else 1.0
	sfx_player.get_stream_playback().play_stream(effect_stream(key), 0.0, linear_to_db(maxf(0.000001, scale)))
	played[key] = played.get(key, 0) + 1
	if key == "boom":
		duck()
	return true

func _process(dt: float) -> void:
	# The score keeps its real-time tempo while the physics enters slow motion.
	advance(dt / maxf(Engine.time_scale, 0.001))

func advance(dt: float) -> void:
	var old := clock_s
	clock_s += dt
	if music_running:
		while next_step <= clock_s:
			_play_step(music_step)
			music_step += 1
			next_step += STEP
		for echo in echoes.duplicate():
			if echo.at <= clock_s:
				_music_voice(echo.voice, echo.gain)
				echoes.erase(echo)
				if echo.gain > 0.003:
					echoes.append({"at": echo.at + 60.0 / 112.0 * .75, "voice": echo.voice, "gain": echo.gain * .25})
	var target := 0.0
	var tau := 0.2
	if music_running:
		target = VOLUME * .4 if clock_s < duck_until else VOLUME
		tau = .03 if clock_s < duck_until else .6
	# Split at the duck hold boundary so a long frame preserves both envelope phases.
	if old < duck_until and clock_s >= duck_until and music_running:
		music_gain = lerpf(music_gain, VOLUME * .4, 1.0 - exp(-(duck_until - old) / .03))
		dt = clock_s - duck_until
	music_gain = lerpf(music_gain, target, 1.0 - exp(-dt / tau))
	_apply_gain()
	if not music_running and music_gain < 0.0001 and music_player.playing:
		# Reset polyphonic playback only once the fade has become inaudible.
		music_player.stop()

func _apply_gain() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music_bus), linear_to_db(maxf(0.000001, music_gain)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(music_bus), muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(sfx_bus), muted)

func music_events(step: int) -> Array:
	var bar := step / 16
	var pos := step % 16
	var ch: Array = CHORDS[bar % 4]
	var bright := 1.3 if game != null and game.L.get("theme", "desert") == "sky" else 1.0
	var voices := []
	if pos in [0, 8]:
		voices.append(["kick",130.0,48.0,.16,.16,0.0,false])
	if pos % 2 == 0:
		voices.append(["shaker",0.0,0.0,.08,.05 if pos % 4 == 2 else .025,7000.0,false])
	var bass := {0:0,3:0,6:12,8:7,11:0,14:12}
	if bass.has(pos):
		voices.append(["triangle",midi(ch[0] - 24 + bass[pos]),0.0,.22,.13,700.0,false])
	if pos % 2 == 1:
		voices.append(["square",midi(ch[(pos >> 1) % 3] + 12),0.0,.09,.018,1400.0 * bright,false])
	var section := (bar / 8) % 4
	if section != 3:
		for note in MELODY[bar % 8]:
			if note[0] == pos:
				var f := midi(note[1] + (12 if section == 1 else 0))
				voices.append(["sine",f,0.0,.42,.075,4000.0,true])
				voices.append(["sine",f * 4,0.0,.06,.012,8000.0,false])
	return voices

func _play_step(step: int) -> void:
	for voice in music_events(step):
		_music_voice(voice)
		if voice[6]:
			var echo: Array = voice.duplicate()
			echo[5] = 2500.0
			echoes.append({"at": next_step + 60.0 / 112.0 * .75, "voice": echo, "gain": .35})

func _music_voice(voice: Array, gain := 1.0) -> void:
	var key := str(voice.slice(0, 6))
	if not cache.has(key):
		var samples: PackedFloat32Array
		if voice[0] == "shaker":
			samples = _noise(voice[3], voice[4], "highpass", voice[5], 3.0)
		elif voice[0] == "kick":
			samples = _tone(130, 48, .16, .16, "sine", .001, false, .12)
		else:
			samples = _tone(voice[1], voice[1], voice[3], voice[4], voice[0], .0005, true)
			samples = _filter(samples, "lowpass", voice[5])
		cache[key] = _wav(samples)
	music_player.get_stream_playback().play_stream(cache[key], 0.0, linear_to_db(gain))

static func midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)

func effect_stream(key: String) -> AudioStreamWAV:
	if cache.has(key):
		return cache[key]
	var out := PackedFloat32Array()
	for c in EFFECTS[key]:
		var samples := _noise(c[3], c[4], c[5], c[1], c[6]) if c[0] == "noise" else _tone(c[1], c[2], c[3], c[4], c[5])
		var offset := int(c[7] * RATE)
		if out.size() < samples.size() + offset:
			out.resize(samples.size() + offset)
		for i in samples.size():
			out[i + offset] += samples[i]
	cache[key] = _wav(out)
	return cache[key]

func _tone(f0: float, f1: float, dur: float, vol: float, wave: String, floor_gain := .001, attack := false, sweep_duration := -1.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * dur))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var k := t / dur
		var freq := f0 * pow(f1 / f0, minf(1.0, t / (sweep_duration if sweep_duration > 0 else dur)))
		var value := sin(TAU * phase)
		if wave == "triangle":
			value = 1.0 - 4.0 * absf(fmod(phase + .25, 1.0) - .5)
		elif wave == "square":
			value = 1.0 if fmod(phase, 1.0) < .5 else -1.0
		elif wave == "sawtooth":
			value = 2.0 * fmod(phase, 1.0) - 1.0
		var envelope := vol * pow(floor_gain / vol, k)
		if attack:
			envelope = vol * t / .006 if t < .006 else vol * pow(floor_gain / vol, (t - .006) / (dur - .006))
		out[i] = value * envelope
		phase += freq / RATE
	return out

func _noise(dur: float, vol: float, kind: String, cutoff: float, decay: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * dur))
	for i in out.size():
		out[i] = rng.randf_range(-1, 1) * pow(1.0 - float(i) / out.size(), decay)
	out = _filter(out, kind, cutoff)
	for i in out.size():
		out[i] *= vol
	return out

# Procedural biquad approximation, Q=1/sqrt(2).
func _filter(input: PackedFloat32Array, kind: String, cutoff: float) -> PackedFloat32Array:
	var w := TAU * cutoff / RATE
	var cw := cos(w)
	var alpha := sin(w) / (2.0 * sqrt(.5))
	var a0 := 1.0 + alpha
	var a1 := -2.0 * cw / a0
	var a2 := (1.0 - alpha) / a0
	var b0 := (1.0 - cw) / 2.0 / a0
	var b1 := (1.0 - cw) / a0
	var b2 := b0
	if kind == "highpass":
		b0 = (1.0 + cw) / 2.0 / a0
		b1 = -(1.0 + cw) / a0
		b2 = b0
	elif kind == "bandpass":
		b0 = alpha / a0
		b1 = 0.0
		b2 = -b0
	var out := PackedFloat32Array()
	out.resize(input.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in input.size():
		var x := input[i]
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		out[i] = y
		x2 = x1; x1 = x; y2 = y1; y1 = y
	return out

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, roundi(clampf(samples[i], -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
