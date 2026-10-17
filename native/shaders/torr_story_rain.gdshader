shader_type canvas_item;
uniform float clock = 0.0;
uniform float aspect = 1.777778;
float hash(float value) { return fract(sin(value * 127.1) * 43758.5453); }
void fragment() {
	vec2 point = vec2(UV.x * aspect, UV.y);
	float streak = 0.0;
	for (int layer = 0; layer < 2; layer++) {
		float speed = 0.55 + float(layer) * 0.4;
		vec2 rain = vec2(point.x + point.y * 0.26, point.y - clock * speed);
		rain *= vec2(150.0 + float(layer)*65.0, 12.0);
		float column = floor(rain.x);
		float seed = hash(column + float(layer)*112.0);
		float line = 1.0 - smoothstep(0.025, 0.13, abs(fract(rain.x)-0.5));
		float drop = 1.0 - smoothstep(0.0, 0.52, fract(rain.y + seed*15.0));
		streak += line * drop * step(0.3, seed);
	}
	COLOR = vec4(0.69, 0.79, 0.87, min(0.10, streak * 0.06));
}
