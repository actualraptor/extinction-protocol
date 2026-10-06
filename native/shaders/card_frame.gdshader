shader_type canvas_item;
uniform vec2 frame_size=vec2(380.0,650.0);
varying vec2 local_uv;
void vertex(){local_uv=VERTEX/frame_size;}
void fragment(){
 vec4 ink=texture(TEXTURE,UV)*COLOR;
 float edge=min(min(local_uv.x,1.0-local_uv.x),min(local_uv.y,1.0-local_uv.y));
 ink.a*=smoothstep(0.0,0.025,edge);
 COLOR=ink;
}
