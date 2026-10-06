extends Control
signal completed
var player: VideoStreamPlayer
var busy = false
var camera_material: ShaderMaterial
const PAGE_CUES=[0.0,20.43,44.91,67.95,77.43,103.02,118.08,124.44,127.02,149.67,177.75,181.65,194.34]
var closing=false

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	player = VideoStreamPlayer.new()
	player.bus="Cinematic"
	var stream = VideoStreamTheora.new()
	stream.file = "res://payload/018.ogv"
	player.stream = stream
	player.expand = true
	player.volume_db=-6.0
	camera_material=ShaderMaterial.new()
	var camera_shader=Shader.new()
	camera_shader.code="shader_type canvas_item; uniform float zoom=1.0; void fragment(){ COLOR=texture(TEXTURE,(UV-vec2(0.5))/zoom+vec2(0.5)); }"
	camera_material.shader=camera_shader
	player.material=camera_material
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player)
	resized.connect(layout)
	player.finished.connect(finish)
	layout()
	player.play()
	var skip = Button.new()
	skip.text = "Hold to skip"
	skip.position = Vector2(24,24)
	skip.button_down.connect(func():busy=true)
	skip.button_up.connect(func():busy=false)
	add_child(skip)

var hold = 0.0
func _process(dt):
	var clock=player.stream_position
	var index=0
	while index<PAGE_CUES.size()-2 and clock>=PAGE_CUES[index+1]:index+=1
	var progress=clampf((clock-PAGE_CUES[index])/(PAGE_CUES[index+1]-PAGE_CUES[index]),0,1)
	# A tiny breathing push returns smoothly during page dissolves, with no camera jump.
	camera_material.set_shader_parameter("zoom",1.012+sin(progress*PI)*.025)
	hold = hold+dt if busy else 0.0
	if hold >= 1.5: finish()

func layout():
	if not is_instance_valid(player): return
	var w = minf(size.x,size.y*16.0/9.0)
	player.size = Vector2(w,w*9.0/16.0)
	player.position = (size-player.size)/2

func finish():
	if closing:return
	closing=true
	set_process(false)
	player.stop()
	completed.emit()
	queue_free()
