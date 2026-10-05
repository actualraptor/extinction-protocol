extends SceneTree

func _initialize():
	var theme = load("res://scripts/seasonal_theme.gd")
	var failures = 0
	for group in range(3):
		var regions = theme.regions_for(group)
		var texture = theme.texture_for(group)
		assert(regions.size() == (4 if group == 2 else 9))
		for region in regions:
			if region.size.x < 20 or region.size.y < 20 or not Rect2(Vector2.ZERO,texture.get_size()).encloses(region): failures += 1
		var image = texture.get_image()
		if image.get_pixel(0,0).a > 0.01: failures += 1
	for i in range(6):
		var art = theme.accessory(i)
		if not Rect2(Vector2.ZERO,theme.ACCESSORIES.get_size()).encloses(art.region): failures += 1
	var image = theme.ACCESSORIES.get_image()
	if image.get_pixel(0,0).a > 0.01: failures += 1
	for map in range(3):
		for depth in range(3):
			var stream = load("res://assets/audio/hollow_%s_%s.wav"%[map,depth])
			if stream == null or stream.get_length()<40 or not stream.stereo: failures += 1
	print("Seasonal assets: 22 creature frames, 6 accessory regions, 9 soundtrack loops / %s failures"%failures)
	quit(failures)
