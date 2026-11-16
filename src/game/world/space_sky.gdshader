shader_type sky;
// Процедурное небо: звёзды двух слоёв + туманность. Цвета — из старого 2D StarField.

uniform vec3 base_color : source_color = vec3(0.008, 0.01, 0.022);
uniform vec3 nebula_color_a : source_color = vec3(0.35, 0.05, 0.55);
uniform vec3 nebula_color_b : source_color = vec3(0.05, 0.25, 0.55);
uniform float nebula_intensity = 0.35;
uniform float nebula_scale = 2.2;
uniform vec3 far_star_color : source_color = vec3(0.75, 0.6, 1.0);
uniform vec3 near_star_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float star_brightness = 2.5;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float value_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * value_noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float stars(vec3 dir, float scale, float threshold) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	float h = hash(cell);
	if (h < threshold) {
		return 0.0;
	}
	vec3 star_pos = vec3(hash(cell + 1.7), hash(cell + 3.1), hash(cell + 5.3)) * 0.6 + 0.2;
	float d = length(fract(p) - star_pos);
	float brightness = (h - threshold) / (1.0 - threshold);
	return smoothstep(0.16, 0.0, d) * (0.4 + 0.6 * brightness);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float n = fbm(d * nebula_scale);
	float tint = fbm(d * nebula_scale * 2.0 + 7.0);
	vec3 nebula = mix(nebula_color_a, nebula_color_b, tint) * smoothstep(0.42, 0.8, n) * nebula_intensity;

	vec3 col = base_color + nebula;
	col += far_star_color * stars(d, 260.0, 0.93) * star_brightness * 0.6;
	col += near_star_color * stars(d, 120.0, 0.965) * star_brightness;
	// Солнце: яркий ориентир, чтобы в петлях и бочках не терять «где верх»
	if (LIGHT0_ENABLED) {
		float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
		col += LIGHT0_COLOR * (smoothstep(0.9993, 0.9997, sd) * 6.0 + pow(sd, 300.0) * 0.8 + pow(sd, 10.0) * 0.05);
	}
	COLOR = col;
}
