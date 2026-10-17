extends SceneTree
const Story = preload("res://scripts/torr_story_player.gd")
var checks = 0
var failures = 0
var completions = 0
func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL / ", message)
func _initialize(): call_deferred("run")
func run():
	for bus in ["SFX", "Voice"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var story = Story.new()
	story.external_clock = true
	root.add_child(story)
	await process_frame
	check(not story.voice.playing and not story.effects.playing, "Capture clock is silent")
	check(story.voice.bus == "Voice" and story.effects.bus == "SFX", "Separate settings buses")
	for page in story.pages:
		check(page.texture != null, "Every individual pose imports")
	check(abs(story.voice.stream.get_length() - Story.END) < .05, "Voice stem duration")
	check(abs(story.effects.stream.get_length() - Story.END) < .05, "Effects stem duration")
	for size in [Vector2(3440,1440), Vector2(1280,720), Vector2(640,480)]:
		story.size = size
		story.layout()
		check(abs(story.stage.size.x / story.stage.size.y - 16.0/9.0) < .001, "No stretching on wide/small screens")
		check(story.stage.position.x >= 0 and story.stage.position.y >= 0, "Stage fits viewport")
	story.size = root.get_visible_rect().size
	story.layout()
	for at in [0.0, 1.5, 8.8, 12.8, 13.06, 13.6, 18.9, 19.7, 20.72, 20.78, 22.0]:
		story.clock = at
		story.update_frame()
		check(story.pages[Story.frame_at(at)].visible, "Active pose visible at " + str(at))
		check(story.hammer.visible == (at >= 19.45 and at < Story.CATCH_AT), "Hammer flight/catch boundary")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/torr-audio/story-" + str(at).replace(".","-") + ".png")
	story.clock = 5
	story.update_frame()
	check(story.caption.text.begins_with("Ancestor"), "Speech subtitle cue")
	check(story.speaker_label.text == "TORR" and story.caption.get_theme_font("font") != story.narrator_font, "Character has named upright dialogue")
	story.clock = 2
	story.update_frame()
	check(story.speaker_label.text == "NARRATOR" and story.caption.get_theme_font("font") == story.narrator_font, "Narrator has named italic narration")
	story.clock = 0
	story.update_frame()
	check(not story.speaker_label.visible and story.caption.text.is_empty(), "Speaker labels disappear between cues")
	story.key_skip = true
	story.held = 1.0
	story._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not story.key_skip and story.held == 0, "Focus loss cancels skip")
	story.completed.connect(func(): completions += 1)
	story.finish()
	story.finish()
	check(completions == 1 and not story.voice.playing and not story.effects.playing, "Completion emits once and stops all audio")
	await process_frame
	check(not is_instance_valid(story), "Scene cleanup")
	var skipped = Story.new()
	skipped.sound_enabled = false
	root.add_child(skipped)
	check(skipped.voice.volume_db <= -80 and skipped.effects.volume_db <= -80, "Sound-disabled playback stays muted")
	skipped.key_skip = true
	skipped._process(.4)
	check(not skipped.finished, "A short press does not skip")
	skipped.key_skip = false
	skipped._process(.1)
	check(skipped.held == 0, "Releasing resets hold progress")
	skipped.key_skip = true
	skipped._process(1.21)
	check(skipped.finished and not skipped.voice.playing and not skipped.effects.playing, "Held skip ends playback and both stems")
	await create_timer(.3).timeout
	print("TORR STORY / ", checks, " checks / ", failures, " failures")
	quit(1 if failures else 0)
