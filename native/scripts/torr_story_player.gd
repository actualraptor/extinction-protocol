extends Control
signal completed

const ART = "res://assets/torr-story/"
const AUDIO = "res://assets/audio/torr-story/"
const UiArt = preload("res://scripts/ui_art.gd")
const BREAK_AT = 13.05
const CATCH_AT = 20.74
const END = 23.09
const FRAMES = ["inspect", "windup", "downswing", "swing", "snap", "aftermath", "summon", "catch"]
const CUES = [0.0, 8.3, 12.4, 12.72, BREAK_AT, 13.38, 18.75, CATCH_AT]
const BLENDS = [0.0, 0.85, 0.12, 0.12, 0.065, 0.22, 0.85, 0.0]
const WORDS = [
	[1.25, 4.35, "Men had carried it through ages of war.", "NARRATOR"],
	[4.63, 8.0, "Ancestor’s Wrath, eh? Let’s have a look.", "TORR"],
	[8.23, 10.9, "Torr gave it one easy swing.", "NARRATOR"],
	[11.05, 13.05, "Easy now. I haven’t even—", "TORR"],
	[14.15, 16.5, "That was one swing too many.", "NARRATOR"],
	[16.73, 20.84, "Ah. Right. God-forged from now on.", "TORR"]
]
var external_clock = false
var sound_enabled = true
var clock = 0.0
var finished = false
var held = 0.0
var pointer_skip = false
var key_skip = false
var stage: Control
var pages: Array[TextureRect] = []
var rain: ColorRect
var hammer: TextureRect
var caption: Label
var speaker_label: Label
var narrator_font: FontVariation
var current_speaker = ""
var skip: Button
var meter: ProgressBar
var voice: AudioStreamPlayer
var effects: AudioStreamPlayer

static func frame_at(at: float) -> int:
	var index = 0
	for i in CUES.size():
		if at >= CUES[i]: index = i
	return index

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	stage = Control.new()
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	for pose in FRAMES:
		var page = TextureRect.new()
		page.texture = load(ART + pose + ".png")
		page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		page.stretch_mode = TextureRect.STRETCH_SCALE
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(page)
		pages.append(page)
	hammer = TextureRect.new()
	hammer.texture = load(ART + "hammer.png")
	hammer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hammer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hammer)
	rain = ColorRect.new()
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rain_material = ShaderMaterial.new()
	rain_material.shader = preload("res://shaders/torr_story_rain.gdshader")
	rain.material = rain_material
	stage.add_child(rain)
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(0,0,0,0), Color(0,0,0,.86)])
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(.5,0)
	texture.fill_to = Vector2(.5,1)
	var background = TextureRect.new()
	background.texture = texture
	background.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	background.offset_top = -110
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(background)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font", UiArt.body_font())
	caption.add_theme_color_override("font_color", Color("eee1c5"))
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(caption)
	narrator_font = FontVariation.new()
	narrator_font.base_font = UiArt.BODY_FONT
	narrator_font.variation_opentype = {2003265652:550.0}
	narrator_font.variation_transform = Transform2D(Vector2(1,0), Vector2(-.12,1), Vector2.ZERO)
	speaker_label = Label.new()
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_label.add_theme_font_override("font", UiArt.heading_font())
	speaker_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	speaker_label.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(speaker_label)
	skip = Button.new()
	skip.text = "Hold to skip · Esc / Space"
	skip.add_theme_font_override("font", UiArt.body_font())
	skip.add_theme_font_size_override("font_size", 16)
	skip.add_theme_color_override("font_color", Color("eee1c5"))
	for state in ["normal", "hover", "pressed", "focus"]:
		skip.add_theme_stylebox_override(state, UiArt.button_style(state))
	skip.button_down.connect(func(): pointer_skip = true)
	skip.button_up.connect(func(): pointer_skip = false)
	add_child(skip)
	meter = ProgressBar.new()
	meter.max_value = 1.2
	meter.show_percentage = false
	add_child(meter)
	voice = make_audio("voice.ogg", "Voice")
	effects = make_audio("effects.ogg", "SFX")
	resized.connect(layout)
	layout()
	if not external_clock:
		voice.play()
		effects.play()
	update_frame()

func make_audio(file: String, bus: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = load(AUDIO + file)
	player.bus = bus
	player.volume_db = 0.0 if sound_enabled else -80.0
	add_child(player)
	return player

func layout():
	if stage == null: return
	stage.size = Vector2(minf(size.x, size.y * 16.0 / 9.0), minf(size.y, size.x * 9.0 / 16.0))
	stage.position = (size - stage.size) * .5
	for page in pages: page.size = stage.size
	rain.size = stage.size
	rain.material.set_shader_parameter("aspect", 16.0 / 9.0)
	caption.size = Vector2(stage.size.x * .9, maxf(60, stage.size.y * .13))
	caption.position = Vector2(stage.size.x * .05, stage.size.y - caption.size.y - 12)
	caption.add_theme_font_size_override("font_size", maxi(17, roundi(stage.size.y / 30)))
	speaker_label.position = caption.position + Vector2(0, 4)
	speaker_label.size = Vector2(caption.size.x, 28)
	speaker_label.add_theme_font_size_override("font_size", maxi(13, roundi(stage.size.y / 47)))
	skip.size = Vector2(minf(310, size.x - 24), 48)
	skip.position = Vector2(size.x - skip.size.x - 12, 12)
	meter.position = skip.position + Vector2(0, 50)
	meter.size = Vector2(skip.size.x, 3)

func _input(event):
	if event is InputEventKey and event.keycode in [KEY_ESCAPE, KEY_SPACE] and not event.echo:
		key_skip = event.pressed
		get_viewport().set_input_as_handled()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		key_skip = false
		pointer_skip = false
		held = 0.0

func _process(dt):
	if finished: return
	if not external_clock:
		if effects.playing:
			clock = maxf(clock, effects.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
		else: clock += dt
		held = held + dt if key_skip or pointer_skip else 0.0
		if held >= 1.2 or clock >= END:
			finish()
			return
	update_frame()

func update_frame():
	var index = frame_at(clock)
	var blend = smoothstep(0, BLENDS[index], clock - CUES[index]) if BLENDS[index] > 0 else 1.0
	for i in pages.size():
		pages[i].visible = i == index or (i == index - 1 and blend < 1.0)
		pages[i].modulate.a = blend if i == index else 1.0
	stage.modulate.a = smoothstep(0, .85, clock) * (1.0 - smoothstep(22.25, END, clock))
	rain.material.set_shader_parameter("clock", clock)
	caption.text = ""
	for line in WORDS:
		if clock >= line[0] and clock < line[1]:
			caption.text = line[2]
			if current_speaker != line[3]:
				current_speaker = line[3]
				speaker_label.text = current_speaker
				var is_narrator = current_speaker == "NARRATOR"
				caption.add_theme_font_override("font", narrator_font if is_narrator else UiArt.body_font())
				caption.add_theme_color_override("font_color", Color("e2e8ed") if is_narrator else Color("f1e2c4"))
				speaker_label.add_theme_color_override("font_color", Color("bdcbd6") if is_narrator else Color("dcb76d"))
	speaker_label.visible = not caption.text.is_empty()
	# Flight ends on the same timeline cue as the authored grip pose and chime.
	hammer.visible = clock >= 19.45 and clock < CATCH_AT
	if hammer.visible:
		var phase = clampf((clock - 19.45) / (CATCH_AT - 19.45), 0, 1)
		hammer.size = Vector2(stage.size.x * .167, stage.size.y * .51)
		hammer.pivot_offset = hammer.size * .5
		hammer.rotation = lerpf(-.9, 0.0, phase)
		hammer.position = Vector2(lerpf(-.2, .437, phase) * stage.size.x, lerpf(.23, .414, phase) * stage.size.y) - hammer.size * .5
	skip.visible = not external_clock
	meter.visible = not external_clock and held > 0
	meter.value = held

func finish():
	if finished: return
	finished = true
	voice.stop()
	effects.stop()
	set_process(false)
	completed.emit()
	queue_free()
