shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec2 atlas_grid = vec2(4.0, 2.0);
uniform float intensity = 0.85;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 cell = fract(UV * atlas_grid);
	vec2 border = smoothstep(vec2(0.0), vec2(0.065), cell) * smoothstep(vec2(0.0), vec2(0.065), vec2(1.0)-cell);
	float edge = border.x * border.y;
	COLOR = vec4(tex.rgb * vertex_tint.rgb * intensity, tex.a * vertex_tint.a * edge);
	if (textureSize(TEXTURE,0).x<=1) COLOR = vertex_tint;
}
