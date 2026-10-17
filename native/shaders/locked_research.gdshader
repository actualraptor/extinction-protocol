shader_type canvas_item;
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float brightness = max(source.r, max(source.g, source.b));
    // Icon atlases contain dark backplates: expose the emblem, not its square.
    COLOR = vec4(vec3(0.0), source.a * smoothstep(0.10, 0.22, brightness));
}
