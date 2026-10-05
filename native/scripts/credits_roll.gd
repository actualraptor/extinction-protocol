extends Control
signal completed
var roll: VBoxContainer
var closing=false
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black=ColorRect.new();black.color=Color("070c10");black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(black)
	var clip=Control.new();clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);clip.clip_contents=true;add_child(clip)
	roll=VBoxContainer.new();roll.position=Vector2(0,size.y);roll.size.x=size.x;roll.add_theme_constant_override("separation",32);clip.add_child(roll)
	for text in ["EXTINCTION PROTOCOL","A world out of time. A story made together.","CREATIVE DIRECTION · DESIGN · PRODUCTION","Gullberg","IMPLEMENTATION · ITERATION · TECHNICAL COLLABORATION","Codex · OpenAI","TOOLS & CREATIVE WORKFLOW","Godot Engine","OpenAI · ChatGPT · Codex · Image Generation","Grok · xAI","ElevenLabs · Voices & narration","GitHub · Source control & releases","INSPIRATION","Last Epoch · Illustrated cinematic storytelling","SPECIAL THANKS","Ehmiiz · Ongoing inspiration and testing","To Gullberg, for every idea, every test run,
and refusing to let good enough be the end.","To everyone who steps into the rift
and helps this world grow.","More contributors and credits to come.","THANK YOU FOR PLAYING"]:
		var line=Label.new();line.text=text;line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;line.add_theme_color_override("font_color",Color("e4d4b0"));line.add_theme_font_size_override("font_size",26);roll.add_child(line)
	var exit=Button.new();exit.text="Return";exit.position=Vector2(24,24);exit.pressed.connect(finish);add_child(exit)
func _process(dt):
	roll.position.y-=38*dt
	if roll.position.y+roll.size.y<0:finish()
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:finish();get_viewport().set_input_as_handled()
func finish():
	if closing:return
	closing=true;completed.emit();queue_free()
