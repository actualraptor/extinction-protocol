shader_type canvas_item;
uniform vec2 center;
uniform vec2 rect_origin;
uniform vec2 rect_size;
uniform vec2 world_offset;
uniform float elapsed;
uniform float clock;
uniform float boundary_radius = 1400.0;
uniform float boundary_weather = 1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.57+noise(p*2.03)*.28+noise(p*4.11)*.15;}
void fragment(){
	vec2 point=rect_origin+UV*rect_size;
	vec2 ground=point+world_offset;
	vec2 delta=point-center;
	float angle=atan(delta.y,delta.x);
	float radius=boundary_radius+(sin(angle*7.0+1.2)*18.0+sin(angle*13.0-.7)*11.0)*boundary_weather;
	float depth=length(delta)-radius;
	float overtime=clamp((elapsed-210.0)/8.0,0.0,1.0);
	// Far inside the safe area the smoke falloff is below one alpha byte.
	// Avoid evaluating twelve noise octaves where the effect is invisible.
	if(depth < -420.0 && overtime == 0.0){
		COLOR=vec4(0.0);
	}else{
	float grit=fbm(ground*.037);
	// Rising tongues have a coherent vertical flow, with smaller curls that
	// break their outline instead of blurring the whole advancing front.
	vec2 flow=vec2(ground.x*.062,ground.y*.045+clock*2.3);
	float curl=noise(flow*.51+vec2(clock*.16,0.0));
	float turbulent=fbm(flow+vec2(curl*2.2,0.0));
	float detail=noise(ground*.19+vec2(clock*.4,clock*4.5));
	float veil=fbm(vec2(ground.x*.018+clock*.11,ground.y*.014+clock*.25));
	float scorch=smoothstep(0.0,95.0,depth)*(.42+grit*.18);
	float lift=(turbulent-.32)*62.0;
	float lifted_depth=length(delta+vec2(0.0,lift))-radius;
	float heat=exp(-abs(lifted_depth-12.0)/24.0);
	float flames=smoothstep(.40,.72,turbulent+detail*.13+depth*.004)*heat;
	float base=exp(-abs(depth-9.0)/8.0)*(.55+detail*.45);
	flames=max(flames,base*.65);
	flames=max(flames,overtime*smoothstep(.44,.83,turbulent)*.75);
	float smoke=exp(-abs(depth-48.0)/85.0)*veil*.23;
	vec3 fire=mix(vec3(.72,.065,.004),vec3(1.0,.72,.20),smoothstep(.48,.83,turbulent+base*.30));
	float coals=smoothstep(.70,.91,grit)*smoothstep(12.0,65.0,depth);
	vec3 color=mix(vec3(.075,.048,.025),fire,clamp(flames*1.6,0.0,1.0));
	color=mix(color,vec3(.65,.11,.012),coals*.30);
	float alpha=clamp(scorch+smoke+flames*.80+overtime*.12,0.0,.91);
	COLOR=vec4(color,alpha);
	}
}
