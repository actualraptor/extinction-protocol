shader_type canvas_item;
uniform vec4 aperture=vec4(.12,.29,.88,.66);
void fragment() {
 vec4 pixel=texture(TEXTURE,UV);
 // The authored black aperture is a cutout; retain metal crossing its edge.
 float opening=step(aperture.x,UV.x)*step(UV.x,aperture.z)*step(aperture.y,UV.y)*step(UV.y,aperture.w);
 float black=1.0-smoothstep(.035,.11,max(pixel.r,max(pixel.g,pixel.b)));
 COLOR=vec4(pixel.rgb,pixel.a*(1.0-opening*black));
}
