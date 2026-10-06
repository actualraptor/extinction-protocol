shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float age = 0.0;
uniform float page_duration = 17.0;
uniform int scene = 0;
uniform bool progressive_zoom = false;
float ellipse(vec2 p,vec2 center,vec2 radius){return 1.0-smoothstep(0.5,1.0,length((p-center)/radius));}
void fragment(){
	float travel = smoothstep(0.0,17.0,age);
	float zoom = 1.012+sin(clamp(age/page_duration,0.0,1.0)*3.14159265)*0.025;
	if(progressive_zoom) zoom = 1.012+clamp(age/page_duration,0.0,1.0)*0.035;
	vec2 q = (UV-vec2(0.5))/zoom+vec2(0.5);
	q.x += (scene%2==0?1.0:-1.0)*travel*0.009;
	vec3 base = texture(TEXTURE,q).rgb;
	float sky = 1.0-smoothstep(0.35,0.7,q.y);
	// Keep subjects intact: only the distant sky is displaced.
	float safe_sky = sky;
	if(scene==2) safe_sky *= smoothstep(0.66,0.8,q.x);
	if(scene==3) safe_sky *= smoothstep(0.76,0.86,q.x);
	if(scene==4) safe_sky *= 1.0-smoothstep(0.52,0.68,q.y);
	q.x += sin(q.y*17.0+clock*.31)*safe_sky*.0012;
	q.y += sin(q.x*13.0-clock*.23)*safe_sky*.0007;
	vec3 color = texture(TEXTURE,q).rgb;
	float blue = smoothstep(.12,.3,base.b-base.r)*smoothstep(.2,.6,base.b);
	float fire = smoothstep(.15,.4,base.r-base.b)*smoothstep(.25,.7,base.r);
	float flicker = sin(clock*2.1+q.y*15.0)*.025+sin(clock*3.7+q.x*21.0)*.015;
	color += vec3(.04,.11,.17)*blue*(.55+.45*sin(clock*1.5));
	color += vec3(.19,.075,.01)*fire*flicker*2.0;
	float mist = ellipse(q,vec2(.65,.79),vec2(.7,.23));
	float flow = .5+.5*sin(q.x*13.0-clock*.22+sin(q.y*10.0));
	color = mix(color,vec3(.32,.36,.38),mist*flow*.027);
	float vignette = smoothstep(.83,.3,length((UV-.5)*vec2(1.0,.7)));
	color *= .87+.13*vignette;
	// COLOR already contains the sampled texture. Multiplying RGB again would
	// square the painting's values and crush its midtones; retain only its alpha.
	COLOR = vec4(color,COLOR.a);
}
