extends Node

const SAVE_PATH := "user://slimefall.cfg"
const SLIME_PALETTE := [Color8(72, 192, 80), Color8(128, 228, 108), Color8(22, 62, 32), Color8(40, 128, 58),
	Color8(220, 255, 200), Color8(235, 255, 235)] 

signal coins_changed

var coins := 0
var owned := ["hat:none", "color:green", "trail:none"]
var equipped := {"hat": "none", "color": "green", "trail": "none"}
var difficulty := "medium"
var sound_on := true
var shake_on := true
var best_height := 0
var matches_won := 0
var best_time := 0.0
var ghost := PackedVector2Array()

var music: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	load_game()
	music = AudioStreamPlayer.new()
	music.volume_db = -16.0
	add_child(music)
	for i in 6: 
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit()
	save_game()


func owns(kind: String, id: String) -> bool:
	return "%s:%s" % [kind, id] in owned


func buy(kind: String, id: String) -> bool:
	var price := Items.price(kind, id)
	if owns(kind, id) or coins < price:
		return false
	coins -= price
	owned.append("%s:%s" % [kind, id])
	equipped[kind] = id
	coins_changed.emit()
	play_sfx("buy")
	save_game()
	return true


func equip(kind: String, id: String) -> void:
	if owns(kind, id):
		equipped[kind] = id
		save_game()

func record_height(meters: int) -> bool:
	if meters <= best_height:
		return false
	best_height = meters
	save_game()
	return true

const ANIMATIONS := [["idle", 6, 6.0, true], ["jump", 4, 12.0, false], ["fall", 4, 8.0, true],
	["land", 3, 16.0, false], ["die", 8, 10.0, false]]
var _frames_cache := {}


func skin_frames(hat: String) -> SpriteFrames:
	if _frames_cache.has(hat):
		return _frames_cache[hat]
	var sheet: Texture2D = load("res://art/slime/slime_%s.png" % hat)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in ANIMATIONS.size():
		var a: Array = ANIMATIONS[row]
		frames.add_animation(a[0])
		frames.set_animation_speed(a[0], a[2])
		frames.set_animation_loop(a[0], a[3])
		for i in a[1]:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(i * 32, row * 32, 32, 32)
			frames.add_frame(a[0], frame)
	_frames_cache[hat] = frames
	return frames


func slime_material(color_id: String) -> ShaderMaterial:
	var c: Array = Items.COLORS[color_id]
	var from := PackedVector3Array()
	var to := PackedVector3Array()
	for src: Color in SLIME_PALETTE:
		from.append(Vector3(src.r, src.g, src.b))
		var col := Color.from_hsv(fposmod(src.h + c[1], 1.0), clampf(src.s * c[2], 0.0, 1.0), clampf(src.v * c[3], 0.0, 1.0))
		to.append(Vector3(col.r, col.g, col.b))
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/slime_color.gdshader")
	m.set_shader_parameter("from_colors", from)
	m.set_shader_parameter("to_colors", to)
	return m



func play_sfx(name: String, pitch := 1.0) -> void:
	if not sound_on:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = load("res://audio/%s.wav" % name)
			p.pitch_scale = pitch
			p.play()
			return


func play_music(name: String) -> void:
	var stream: AudioStream = load("res://audio/%s.wav" % name)
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	if sound_on:
		music.play()


func set_sound(on: bool) -> void:
	sound_on = on
	if on:
		music.play()
	else:
		music.stop()
	save_game()


func _exit_tree() -> void:
	for p in [music] + sfx_players: 
		if p:
			p.stop()
			p.stream = null
	_frames_cache.clear() 
	UI.clear()


const SAVED := ["coins", "owned", "equipped", "difficulty", "sound_on", "shake_on", "best_height", "matches_won", "best_time", "ghost"]


func save_game() -> void:
	if has_meta("no_save"):
		return
	var cfg := ConfigFile.new()
	for key in SAVED:
		cfg.set_value("player", key, get(key))
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in SAVED:
		var value = cfg.get_value("player", key, get(key))
		if typeof(value) == typeof(get(key)): 
			set(key, value)
	if not equipped.has("trail"):
		equipped["trail"] = "none"
	if not "trail:none" in owned:
		owned.append("trail:none")
