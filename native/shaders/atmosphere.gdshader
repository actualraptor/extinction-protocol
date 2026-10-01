shader_type canvas_item;
render_mode unshaded;
uniform float danger = 0.0;
uniform float flash = 0.0;
uniform float frozen = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float vignette = smoothstep(0.35,1.35,length(p));
	float pulse = (0.5 + 0.5*sin(TIME*4.0))*danger;
	vec3 tint = mix(vec3(0.015,0.022,0.045),vec3(0.45,0.025,0.01),pulse);
	tint = mix(tint,vec3(0.08,0.4,0.65),frozen*0.75);
	COLOR = vec4(mix(tint,vec3(0.8,0.88,1.0),flash),clamp(vignette*0.55 + flash*0.35,0.0,0.75));
}
