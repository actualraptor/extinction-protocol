extends Control
signal completed

const SHOTS = [0,1,2,3]
var identity="thorn"
const CAPTIONS=["POWER BENEATH\nTHE SILENCE", "DEATH GIVEN\nPURPOSE", "THE WILL\nTO COMMAND", "STAND WITHIN\nTHE CIRCLE"]
const CUES = [0.0,47.1,69.7,102.8]
const END = 124.0
const DISSOLVE = 1.8
var sound_enabled = true
var music_enabled = true
var clock = 0.0
var external_clock = false
var finished = false
var hold = 0.0
var skip_pressed = false
var keyboard_skip = false
var narration: AudioStreamPlayer
var score: AudioStreamPlayer
var stage: Control
var pages = []
var title: Label
const SEEN_FLAG="rite_07_seen"
var skip: Button
var meter: ProgressBar

static func available():
	if not FileAccess.file_exists("res://payload/rite/voice.dat"):return false
	for id in ["thorn","hunt","warden"]:
		for shot in SHOTS:
			if not FileAccess.file_exists("res://payload/dinosaurs/story-"+id+"-"+str(shot)+".dat"):return false
	return true
static func story_painting(id,shot):
	var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://payload/dinosaurs/story-"+id+"-"+str(shot)+".dat"))
	return ImageTexture.create_from_image(im)
static func audio_file(path,mp3):
	if mp3:
		var stream=AudioStreamMP3.new();stream.data=FileAccess.get_file_as_bytes(path);return stream
	return AudioStreamOggVorbis.load_from_buffer(FileAccess.get_file_as_bytes(path))
static func shot_at(at):
	var index = 0
	for i in range(CUES.size()):
		if at >= CUES[i]: index = i
	return index

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	stage = Control.new()
	stage.clip_contents=true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	for name in SHOTS:
		var painting = TextureRect.new()
		painting.texture=story_painting(identity,name)
		painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		painting.position=Vector2.ZERO
		painting.size=stage.size
		painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material = ShaderMaterial.new()
		material.shader = preload("res://shaders/storybook.gdshader")
		material.set_shader_parameter("scene", pages.size())
		material.set_shader_parameter("progressive_zoom",true)
		painting.material = material
		stage.add_child(painting)
		pages.append(painting)
	title = Label.new()
	title.text = CAPTIONS[0]
	title.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font())
	title.add_theme_font_size_override("font_size",42)
	title.add_theme_color_override("font_color",Color("eee1c5"))
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_y",3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(title)
	title.hide()
	skip = Button.new()
	skip.text = "Hold to skip / Esc / Space"
	skip.add_theme_font_size_override("font_size",15)
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip.button_down.connect(func():skip_pressed=true)
	skip.button_up.connect(func():skip_pressed=false)
	add_child(skip)
	meter = ProgressBar.new()
	meter.show_percentage = false
	meter.max_value = 1.2
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(meter)
	narration = AudioStreamPlayer.new()
	narration.bus="Voice"
	narration.stream = audio_file("res://payload/rite/voice.dat",true)
	narration.volume_db = -2 if sound_enabled else -80
	add_child(narration)
	score = AudioStreamPlayer.new()
	score.bus="Music"
	score.stream = audio_file("res://payload/rite/score.dat",false)
	score.volume_db = -80
	add_child(score)
	resized.connect(layout)
	layout()
	if not external_clock:
		narration.play()
		score.play()
	else:
		skip.hide()
		meter.hide()
	update_frame()

func layout():
	if stage == null: return
	stage.size = size
	stage.position = Vector2.ZERO
	title.position = Vector2(stage.size.x*.54,stage.size.y*.38)
	title.size = Vector2(stage.size.x*.4,180)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size",maxi(20,roundi(stage.size.x/38)))
	for painting in pages:
		painting.position=Vector2.ZERO;painting.size=stage.size
	skip.size = Vector2(240,34)
	skip.position = Vector2(size.x-264,size.y-58)
	meter.position = skip.position+Vector2(0,36)
	meter.size = Vector2(240,3)

func _input(event):
	if event is InputEventKey and event.keycode in [KEY_ESCAPE,KEY_SPACE] and not event.echo:
		keyboard_skip = event.pressed
		get_viewport().set_input_as_handled()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		skip_pressed = false
		keyboard_skip = false

func _process(dt):
	if finished: return
	if not external_clock:
		if narration.playing:
			clock = maxf(clock,narration.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
		else: clock += dt
	hold = hold+dt if skip_pressed or keyboard_skip else 0.0
	meter.value = hold
	meter.visible = hold>0
	skip.modulate.a = .7 if hold<=0 else 1
	update_frame()
	if hold >= 1.2 or clock >= END: finish()

func update_frame():
	var index = shot_at(clock)
	var mix_value = smoothstep(0,DISSOLVE,clock-CUES[index]) if index>0 else 1.0
	stage.modulate.a = smoothstep(0,1.8,clock)*(1-smoothstep(121,END,clock))
	for i in range(pages.size()):
		pages[i].visible = i == index or (index>0 and i==index-1 and mix_value<1)
		pages[i].modulate.a = mix_value if i==index else 1.0
		if pages[i].visible:
			var age = maxf(0,clock-CUES[i])
			pages[i].material.set_shader_parameter("clock",clock)
			pages[i].material.set_shader_parameter("age",age)
			pages[i].material.set_shader_parameter("page_duration",(CUES[i+1] if i+1<CUES.size() else END)-CUES[i])
	title.text=CAPTIONS[index]
	title.modulate.a=.9
	# The score yields to the voice, then resolves over the title after the last word.
	var level = lerpf(-18.0,-12.0,smoothstep(120,122,clock))
	score.volume_db = level if music_enabled else -80

func finish():
	if finished: return
	finished = true
	narration.stop()
	score.stop()
	set_process(false)
	completed.emit()
	queue_free()
