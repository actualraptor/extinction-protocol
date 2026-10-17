vec4 spell_glow_color(vec4 glow_tex, vec2 glow_uv, vec2 glow_grid, vec4 glow_tint, float glow_intensity) {
	vec2 cell = fract(glow_uv * glow_grid);
	vec2 border = smoothstep(vec2(0.0), vec2(0.065), cell) * smoothstep(vec2(0.0), vec2(0.065), vec2(1.0)-cell);
	float edge = border.x * border.y;
	return vec4(glow_tex.rgb * glow_tint.rgb * glow_intensity, glow_tex.a * glow_tint.a * edge);
}
