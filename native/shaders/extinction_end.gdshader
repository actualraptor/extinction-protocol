shader_type canvas_item;
render_mode unshaded;
uniform float elapsed = 0.0;
uniform vec2 origin = vec2(0.5);
uniform vec2 viewport_size = vec2(1440.0,900.0);
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=(UV-origin)*viewport_size/min(viewport_size.x,viewport_size.y);
 float r=length(p),t=max(0.0,elapsed-0.9);
 float n=noise(p*8.0-vec2(t*1.6,t*0.7));
 float front=t*1.8;
 float wave=exp(-abs(r-front)*18.0)*step(0.9,elapsed)*(1.0-smoothstep(1.8,2.8,t));
 float fire=(1.0-smoothstep(front-0.35,front+0.12,r+n*0.12))*step(0.9,elapsed);
 float fade=smoothstep(2.1,3.9,elapsed);
 float flash=exp(-pow((elapsed-1.04)*7.0,2.0))*0.38;
 vec3 flame=mix(vec3(0.33,0.04,0.008),vec3(1.0,0.47,0.06),n);
 vec3 col=mix(flame,vec3(1.0,0.85,0.48),clamp(wave+flash,0.0,1.0));
 float alpha=max(max(wave*0.78,fire*0.78),flash);
 col=mix(col,vec3(0.005,0.006,0.009),fade);
 alpha=mix(alpha,1.0,fade);
 COLOR=vec4(col,alpha);
}
