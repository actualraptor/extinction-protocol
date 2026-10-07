extends RefCounted
const LOGO=preload("res://assets/branding/extinction-protocol-logo.png")
static func logo(height=180.0):
	var image=TextureRect.new()
	image.texture=LOGO
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size=Vector2(0,height)
	image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return image
