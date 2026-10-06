shader_type canvas_item;
render_mode blend_add;
uniform float strength = 0.0;
void fragment() {
	vec4 ink=texture(TEXTURE,UV);
	float light=max(ink.r,max(ink.g,ink.b));
	float mask=smoothstep(.20,.75,light)*ink.a;
	COLOR=vec4(ink.rgb*strength,mask*strength);
}
