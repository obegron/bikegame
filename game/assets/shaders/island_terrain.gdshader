shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 grass_color : source_color = vec4(0.44, 0.56, 0.35, 1.0);
uniform vec4 heather_color : source_color = vec4(0.39, 0.45, 0.32, 1.0);
uniform vec4 sand_color : source_color = vec4(0.79, 0.72, 0.55, 1.0);
uniform vec4 wet_sand_color : source_color = vec4(0.53, 0.49, 0.4, 1.0);
uniform vec4 cliff_color : source_color = vec4(0.33, 0.35, 0.31, 1.0);
uniform vec4 cliff_highlight : source_color = vec4(0.45, 0.46, 0.42, 1.0);
uniform float water_level = -0.65;
uniform sampler2D macro_noise_texture : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float cliff_near_scale = 0.2;
uniform float cliff_far_scale = 0.052;
uniform float detail_near_distance = 55.0;
uniform float detail_far_distance = 185.0;

varying vec3 terrain_world_position;
varying vec3 terrain_world_normal;
varying vec4 terrain_control;


vec2 rotate_terrain_uv(vec2 value, float sine_value, float cosine_value) {
	return mat2(vec2(cosine_value, -sine_value), vec2(sine_value, cosine_value)) * value;
}


vec3 triplanar_color(sampler2D source, vec3 position, vec3 normal, float scale) {
	vec3 weights = pow(abs(normal), vec3(5.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	vec3 x_projection = texture(source, position.zy * scale).rgb;
	vec3 y_projection = texture(source, position.xz * scale).rgb;
	vec3 z_projection = texture(source, position.xy * scale).rgb;
	return x_projection * weights.x + y_projection * weights.y + z_projection * weights.z;
}


float triplanar_value(sampler2D source, vec3 position, vec3 normal, float scale) {
	vec3 weights = pow(abs(normal), vec3(5.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	float x_projection = texture(source, position.zy * scale).r;
	float y_projection = texture(source, position.xz * scale).r;
	float z_projection = texture(source, position.xy * scale).r;
	return dot(vec3(x_projection, y_projection, z_projection), weights);
}


void vertex() {
	terrain_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	terrain_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	terrain_control = COLOR;
}


void fragment() {
	vec2 world_uv = terrain_world_position.xz;
	vec2 rotated_uv = rotate_terrain_uv(world_uv, 0.819152, 0.573576);
	float broad_detail = texture(macro_noise_texture, world_uv * 0.0027 + vec2(0.17, 0.63)).r;
	float regional_detail = texture(
		macro_noise_texture,
		rotated_uv * 0.0061 + vec2(0.71, 0.24)
	).r;
	float fine_detail = texture(
		macro_noise_texture,
		world_uv * 0.047 + vec2(0.42, 0.11)
	).r;
	vec3 world_normal = normalize(terrain_world_normal);
	float slope = 1.0 - clamp(world_normal.y, 0.0, 1.0);
	float cliff_edge_noise = (regional_detail - 0.5) * 0.065;
	float cliff_mask = smoothstep(0.105 + cliff_edge_noise, 0.34 + cliff_edge_noise, slope);
	float shore_height = terrain_world_position.y - water_level;
	float sand_mask = (
		(1.0 - smoothstep(0.55, 2.05, shore_height))
		* (1.0 - smoothstep(0.28, 0.52, slope))
		* terrain_control.r
	);
	float wet_mask = 1.0 - smoothstep(0.08, 0.72, shore_height);
	float heather_mask = clamp(
		terrain_control.g * 0.74
		+ (regional_detail - 0.48) * 0.34
		+ smoothstep(2.2, 6.8, terrain_world_position.y) * 0.18,
		0.0,
		1.0
	);

	vec3 grass = mix(grass_color.rgb, heather_color.rgb, heather_mask);
	vec3 regional_tint = mix(
		vec3(0.93, 0.965, 0.91),
		vec3(1.045, 1.015, 0.955),
		terrain_control.b
	);
	grass *= regional_tint;
	grass *= mix(0.88, 1.1, broad_detail) * mix(0.955, 1.045, fine_detail);
	vec3 sand = mix(sand_color.rgb, wet_sand_color.rgb, wet_mask);
	sand *= mix(0.91, 1.08, regional_detail) * mix(0.965, 1.035, fine_detail);

	vec3 cliff = mix(cliff_color.rgb, cliff_highlight.rgb, broad_detail * 0.52);
	float cliff_roughness = 0.9;
	// Terrain3D similarly avoids material lookups when their blend weight is
	// zero. The projected PBR samples are paid only on visible cliff pixels.
	if (cliff_mask > 0.001) {
		float camera_distance = distance(terrain_world_position, CAMERA_POSITION_WORLD);
		float far_mix = smoothstep(detail_near_distance, detail_far_distance, camera_distance);
		vec3 cliff_near = triplanar_color(
			cliff_albedo_texture,
			terrain_world_position,
			world_normal,
			cliff_near_scale
		);
		vec3 cliff_far = triplanar_color(
			cliff_albedo_texture,
			terrain_world_position,
			world_normal,
			cliff_far_scale
		);
		vec3 cliff_surface = mix(cliff_near, cliff_far, far_mix);
		float cliff_tone = dot(cliff_surface, vec3(0.299, 0.587, 0.114));
		vec3 cliff_chroma = cliff_surface / max(cliff_tone, 0.08);
		cliff *= mix(vec3(1.0), cliff_chroma, 0.64);
		cliff *= mix(0.8, 1.2, cliff_tone) * mix(0.92, 1.08, regional_detail);
		float cliff_roughness_near = triplanar_value(
			cliff_roughness_texture,
			terrain_world_position,
			world_normal,
			cliff_near_scale
		);
		float cliff_roughness_far = triplanar_value(
			cliff_roughness_texture,
			terrain_world_position,
			world_normal,
			cliff_far_scale
		);
		cliff_roughness = mix(cliff_roughness_near, cliff_roughness_far, far_mix);
	}

	ALBEDO = mix(grass, sand, sand_mask);
	ALBEDO = mix(ALBEDO, cliff, cliff_mask);
	float ground_roughness = mix(0.97, 0.73, wet_mask * sand_mask);
	ROUGHNESS = mix(ground_roughness, mix(0.68, 0.98, cliff_roughness), cliff_mask);
	METALLIC = 0.0;
	SPECULAR = mix(0.22, 0.34, wet_mask * sand_mask);
}
