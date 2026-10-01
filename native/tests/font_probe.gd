extends SceneTree
func _initialize():
 var art=preload("res://scripts/ui_art.gd")
 print(art.BODY_FONT.get_supported_variation_list())
 print(art.TITLE_FONT.get_supported_variation_list())
 quit()
