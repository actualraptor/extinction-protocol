shader_type canvas_item;
render_mode unshaded;
varying vec2 frame;
varying vec4 tint;
varying float iced;
uniform bool custom_regions = false;
uniform vec4 regions[9];
void vertex() {
	frame = INSTANCE_CUSTOM.xy;
	tint = COLOR;
	iced = 1.0-INSTANCE_CUSTOM.w;
	VERTEX.y += sin(TIME*9.0+INSTANCE_CUSTOM.z)*0.025*INSTANCE_CUSTOM.w;
}
void fragment() {
	// QuadMesh V runs upward in canvas coordinates. Flip inside the cell,
	// before adding its atlas row, so every species stays upright.
	vec2 uv = vec2(UV.x,1.0-UV.y);
	if (custom_regions) {
		vec4 r = regions[int(frame.x+frame.y*3.0)];
		COLOR = texture(TEXTURE,r.xy+uv*r.zw)*tint;
	} else COLOR = texture(TEXTURE,(uv+frame)/3.0)*tint;
	if (iced>0.5) {
		float facets = pow(abs(sin(uv.x*8.0+uv.y*5.0)*cos(uv.y*11.0)),10.0);
		float light = dot(COLOR.rgb,vec3(0.3,0.5,0.2));
		COLOR.rgb = mix(COLOR.rgb,vec3(0.18,0.56,0.82)*(0.45+light*0.65)+vec3(facets*0.25),0.8);
	}
}
