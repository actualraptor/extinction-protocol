shader_type canvas_item;
render_mode unshaded;
varying float iced;
varying vec4 tint;
void vertex() {
	iced = UV.x < 0.0 ? 1.0 : 0.0;
	if (iced>0.5) UV.x=-UV.x-1.0;
	tint = COLOR;
}
void fragment() {
	vec2 uv = fract(UV*vec2(6.0,19.0));
	COLOR = texture(TEXTURE,UV)*tint;
	if (iced>0.5) {
		float facets=pow(abs(sin(uv.x*8.0+uv.y*5.0)*cos(uv.y*11.0)),10.0);
		float light=dot(COLOR.rgb,vec3(0.3,0.5,0.2));
		COLOR.rgb=mix(COLOR.rgb,vec3(0.18,0.56,0.82)*(0.45+light*0.65)+vec3(facets*0.25),0.8);
	}
}
