shader_type spatial;
render_mode cull_back;

uniform sampler2D stone_texture : source_color, filter_linear_mipmap;
uniform sampler2D heat_texture : source_color, filter_linear_mipmap;
uniform float heat_energy = 1.2;
uniform float heat_response = 1.0;

void fragment() {
    vec3 stone = texture(stone_texture, UV).rgb;
    vec3 heat = texture(heat_texture, UV).rgb;
    // Keep the reconstructed recess mask, but prevent pale atlas highlights
    // from turning the creature's eyes into white lamps after tone mapping.
    float raw_strength = clamp(heat.r, 0.0, 1.0);
    float strength = pow(raw_strength, heat_response);
    vec3 amber = mix(vec3(1.0, 0.075, 0.003),
                     vec3(1.0, 0.30, 0.015), smoothstep(0.35, 1.0, strength));
    // The pale eye-center pixels are also present in the albedo atlas.
    // Restrict temperature correction to the hottest recesses; charcoal and
    // dim seams retain their original painted colour and surface lighting.
    float hot_recess = smoothstep(0.65, 0.95, raw_strength);
    ALBEDO = mix(stone, stone * vec3(1.0, 0.20, 0.025), hot_recess);
    ROUGHNESS = 0.93;
    METALLIC = 0.0;
    EMISSION = amber * strength * heat_energy;
}
