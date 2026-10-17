shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec2 atlas_grid = vec2(4.0, 2.0);
uniform float intensity = 0.85;
varying vec4 vertex_tint;
#include "res://shaders/spell_glow_common.gdshaderinc"
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = spell_glow_color(tex, UV, atlas_grid, vertex_tint, intensity);
	if (textureSize(TEXTURE,0).x<=1) COLOR = vertex_tint;
}
