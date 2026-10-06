shader_type canvas_item;
void fragment(){
 vec4 pixel=texture(TEXTURE,UV);
 float edge=1.0-smoothstep(.47,.50,length(UV-vec2(.5)));
 COLOR.a*=edge;
}
