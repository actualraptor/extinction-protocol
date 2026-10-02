shader_type canvas_item;
render_mode unshaded;
uniform sampler2D ground_tex : filter_linear;
uniform vec2 world_origin;
uniform vec2 viewport_size = vec2(1440.0,900.0);
uniform vec4 atlas_region = vec4(0.0,0.0,1.0,1.0);
uniform vec4 ground_color : source_color = vec4(0.08,0.16,0.17,1.0);
uniform int region_count = 0;
uniform vec4 regions[16];
uniform vec4 region_colors[16];
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec3 patch(vec2 p,vec2 anchor) {
 float h=hash(anchor);
 vec2 local=p*0.0018+vec2(h,hash(anchor+13.7))*7.0;
 // Mirrored sampling remains continuous even when source edges do not tile.
 vec2 uv=abs(fract(local*0.5)*2.0-1.0);
 uv=mix(vec2(0.015),vec2(0.985),uv);
 return texture(ground_tex,atlas_region.xy+uv*atlas_region.zw).rgb;
}
void fragment() {
 vec2 p=world_origin+UV*viewport_size;
 vec2 q=p/1050.0; vec2 cell=floor(q); vec2 f=fract(q); f=f*f*(3.0-2.0*f);
 vec3 grain=mix(mix(patch(p,cell),patch(p,cell+vec2(1,0)),f.x),mix(patch(p,cell+vec2(0,1)),patch(p,cell+vec2(1,1)),f.x),f.y);
 vec3 tint=ground_color.rgb;
 for(int i=0;i<16;i++) {
  if(i>=region_count) break;
  float weight=1.0-smoothstep(regions[i].z*0.5,regions[i].z*1.35,length(p-regions[i].xy));
  tint=mix(tint,region_colors[i].rgb,weight*0.48);
 }
 float broad=noise(p/3600.0)*0.12+noise(p/820.0)*0.065;
 COLOR=vec4(grain*0.37+tint*(0.55+broad),1.0);
}
