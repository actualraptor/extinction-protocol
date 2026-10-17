shader_type canvas_item;
void fragment(){
	COLOR=texture(TEXTURE,UV);
	COLOR.a*=smoothstep(0.0,0.15,UV.x)*(1.0-smoothstep(0.87,1.0,UV.y));
}
