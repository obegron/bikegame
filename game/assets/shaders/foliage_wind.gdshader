shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.38, 0.57, 0.28, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.48, 0.67, 0.34, 1.0);
uniform float detail_mix : hint_range(0.0, 1.0) = 0.18;
uniform float wind_strength : hint_range(0.0, 0.2) = 0.06;
uniform float wind_height : hint_range(0.1, 3.0) = 0.8;
uniform float wind_speed : hint_range(0.0, 4.0) = 1.15;

varying float instance_variation;
varying vec3 foliage_pattern_position;


float foliage_hash(vec3 value) {
	vec3 cell = floor(value);
	return fract(sin(dot(cell, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}


void vertex() {
	float phase = INSTANCE_CUSTOM.r * 6.283185;
	float gust_scale = mix(0.72, 1.0, INSTANCE_CUSTOM.b);
	float height_weight = smoothstep(0.02, wind_height, max(VERTEX.y, 0.0));
	float world_phase = MODEL_MATRIX[3].x * 0.075 + MODEL_MATRIX[3].z * 0.051;
	float broad_gust = sin(TIME * wind_speed + phase + world_phase);
	float fine_gust = sin(TIME * wind_speed * 1.73 + phase * 1.9 + VERTEX.y * 2.2);
	float sway = (broad_gust * 0.72 + fine_gust * 0.28) * wind_strength * gust_scale;
	VERTEX.x += sway * height_weight;
	VERTEX.z += sway * 0.38 * height_weight;
	instance_variation = INSTANCE_CUSTOM.g;
	foliage_pattern_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec3 cool_tint = vec3(0.84, 0.94, 0.87);
	vec3 warm_tint = vec3(1.06, 1.01, 0.82);
	vec3 tint = mix(cool_tint, warm_tint, instance_variation);
	float dapple = smoothstep(
		0.28,
		0.82,
		foliage_hash(foliage_pattern_position * 1.55)
	);
	vec3 detailed_color = mix(base_color.rgb, secondary_color.rgb, instance_variation * detail_mix);
	ALBEDO = detailed_color * tint;
	ROUGHNESS = 0.58;
	METALLIC = 0.0;
}
