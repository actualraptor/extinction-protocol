shader_type canvas_item;
uniform float fraction : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float lit = step(UV.x, fraction) * step(0.00001, fraction);
 vec3 empty = vec3(.022, .014, .018) + source.rgb * .045;
 vec3 filled = source.rgb * tint.rgb;
 float leading_edge = (1.0 - smoothstep(0.0, .004, abs(UV.x-fraction))) * step(.001, fraction) * (1.0-step(.999, fraction));
 COLOR = vec4(mix(empty, filled, lit) + vec3(.22,.025,.012)*leading_edge, source.a*tint.a);
}
