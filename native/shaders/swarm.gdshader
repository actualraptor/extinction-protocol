shader_type canvas_item;
render_mode unshaded;
uniform float animation_clock=0.0;
varying vec2 frame;
varying vec4 tint;
varying float iced;
void vertex() {
	frame = INSTANCE_CUSTOM.xy;
	tint = COLOR;
	iced = 1.0-INSTANCE_CUSTOM.w;
	VERTEX.y += sin(animation_clock*9.0+INSTANCE_CUSTOM.z)*0.025*INSTANCE_CUSTOM.w;
}
void fragment() {
	// QuadMesh V runs upward in canvas coordinates. Flip inside the cell,
	// before adding its atlas row, so every species stays upright.
	vec2 uv = vec2(UV.x,1.0-UV.y);
	COLOR = texture(TEXTURE,(uv+vec2(frame.y,frame.x))/vec2(6.0,19.0))*tint;
	if (iced>0.5) {
		float facets = pow(abs(sin(uv.x*8.0+uv.y*5.0)*cos(uv.y*11.0)),10.0);
		float light = dot(COLOR.rgb,vec3(0.3,0.5,0.2));
		COLOR.rgb = mix(COLOR.rgb,vec3(0.18,0.56,0.82)*(0.45+light*0.65)+vec3(facets*0.25),0.8);
	}
}
