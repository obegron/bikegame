shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.8, 0.62, 0.42, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float age_strength : hint_range(0.0, 1.0) = 0.68;

varying vec3 facade_world_position;

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void vertex() {
	facade_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 tiled_uv = UV * vec2(2.15, 2.15);
	vec3 texture_color = texture(albedo_texture, tiled_uv).rgb;
	float texture_tone = dot(texture_color, vec3(0.299, 0.587, 0.114));
	vec2 grain_cell = floor(UV * vec2(90.0, 120.0));
	float grain = hash21(grain_cell) - 0.5;
	float broad_variation = sin(UV.x * 31.0 + sin(UV.y * 23.0)) * 0.018;
	float course_edge = min(fract(UV.y * 14.0), 1.0 - fract(UV.y * 14.0));
	float subtle_course = 1.0 - smoothstep(0.012, 0.04, course_edge);
	float rain_streak = smoothstep(
		0.55,
		0.9,
		hash21(vec2(floor(facade_world_position.x * 0.72), floor(UV.y * 7.0)))
	);
	rain_streak *= smoothstep(0.18, 0.92, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y));
	float patch = smoothstep(
		0.58,
		0.9,
		hash21(floor(facade_world_position.xz * 0.34 + UV * 5.0))
	);
	float lower_grime = (1.0 - smoothstep(0.0, 0.3, UV.y)) * (0.75 + patch * 0.25);
	vec3 color = base_color.rgb * mix(1.0, texture_tone * 1.45, 0.58);
	color *= 0.97 + grain * 0.07 + broad_variation;
	color *= 1.0 - subtle_course * 0.035;
	color *= 1.0 - rain_streak * age_strength * 0.09;
	color *= 1.0 - lower_grime * age_strength * 0.15;
	color = mix(color, color * vec3(0.88, 0.91, 0.82), patch * age_strength * 0.055);
	ALBEDO = color;
	NORMAL_MAP = texture(normal_texture, tiled_uv).rgb;
	NORMAL_MAP_DEPTH = 0.48;
	ROUGHNESS = mix(0.72, 0.97, texture(roughness_texture, tiled_uv).r);
	SPECULAR = 0.25;
}
