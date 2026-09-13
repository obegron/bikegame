shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// A lightweight interpretation of spectral wave cascades: five analytical
// directional bands provide broad swell, cross chop, and fine wind texture.
// Fine bands fade with distance, avoiding shimmer while keeping the horizon
// calm. The analytical derivatives cost fewer trigonometric evaluations than
// sampling the old height function repeatedly to estimate a normal.
uniform vec4 shallow_color : source_color = vec4(0.19, 0.55, 0.68, 1.0);
uniform vec4 deep_color : source_color = vec4(0.035, 0.19, 0.28, 1.0);
uniform vec4 foam_color : source_color = vec4(0.78, 0.86, 0.82, 1.0);
uniform vec4 sky_zenith_color : source_color = vec4(0.22, 0.48, 0.72, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.66, 0.78, 0.82, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.82, 0.56, 1.0);
uniform vec3 sun_direction = vec3(0.0, 0.72, -0.7);
uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform float wave_height = 0.085;
uniform float wave_speed = 0.72;
uniform float normal_strength : hint_range(0.5, 3.0) = 1.3;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.46;

varying vec3 wave_world_position;
varying vec3 wave_world_normal;
varying float wave_crest;
varying float wave_slope;


vec3 directional_wave(
	vec2 point,
	vec2 direction,
	float frequency,
	float amplitude,
	float speed,
	float phase
) {
	float angle = dot(point, direction) * frequency - TIME * speed + phase;
	float sine_wave = sin(angle);
	float derivative = cos(angle) * amplitude * frequency;
	return vec3(
		sine_wave * amplitude,
		derivative * direction.x,
		derivative * direction.y
	);
}


void vertex() {
	vec3 initial_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 point = initial_world_position.xz;
	float camera_distance = length(point - CAMERA_POSITION_WORLD.xz);
	float medium_detail = 1.0 - smoothstep(145.0, 390.0, camera_distance);
	float fine_detail = 1.0 - smoothstep(70.0, 245.0, camera_distance);

	vec3 wave = vec3(0.0);
	wave += directional_wave(
		point,
		normalize(vec2(0.82, 0.57)),
		0.082,
		0.42,
		wave_speed * 0.56,
		0.2
	);
	wave += directional_wave(
		point,
		normalize(vec2(0.62, 0.78)),
		0.145,
		0.27,
		wave_speed * 0.78,
		2.1
	);
	wave += directional_wave(
		point,
		normalize(vec2(0.92, 0.39)),
		0.265,
		0.17 * medium_detail,
		wave_speed * 1.08,
		4.3
	);
	wave += directional_wave(
		point,
		normalize(vec2(-0.36, 0.93)),
		0.48,
		0.09 * fine_detail,
		wave_speed * 1.43,
		1.35
	);
	wave += directional_wave(
		point,
		normalize(vec2(0.74, -0.67)),
		0.76,
		0.05 * fine_detail,
		wave_speed * 1.82,
		5.4
	);

	VERTEX.y += wave.x * wave_height;
	vec3 local_normal = normalize(vec3(
		-wave.y * wave_height * normal_strength,
		1.0,
		-wave.z * wave_height * normal_strength
	));
	NORMAL = local_normal;
	wave_world_position = initial_world_position + vec3(0.0, wave.x * wave_height, 0.0);
	wave_world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	wave_crest = wave.x;
	wave_slope = length(wave.yz) * wave_height;
}


void fragment() {
	vec3 world_normal = normalize(wave_world_normal);
	vec3 view_direction = normalize(CAMERA_POSITION_WORLD - wave_world_position);
	float facing = clamp(dot(world_normal, view_direction), 0.0, 1.0);
	float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);

	float crest_tint = smoothstep(-0.72, 0.82, wave_crest);
	float depth_mix = clamp(0.3 + crest_tint * 0.24 + facing * 0.08, 0.0, 1.0);
	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, depth_mix);

	vec3 reflected_direction = reflect(-view_direction, world_normal);
	float reflected_height = clamp(reflected_direction.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 sky_reflection = mix(
		sky_horizon_color.rgb,
		sky_zenith_color.rgb,
		pow(reflected_height, 0.68)
	);
	sky_reflection = mix(sky_reflection, deep_color.rgb, 0.14);
	sky_reflection *= mix(0.5, 0.64, daylight);

	float foam_ribbon = 0.5 + 0.5 * sin(
		dot(wave_world_position.xz, normalize(vec2(-0.57, 0.82))) * 0.82
		- TIME * wave_speed * 0.9
	);
	float steep_crest = smoothstep(0.48, 0.88, wave_crest);
	steep_crest *= smoothstep(0.012, 0.075, wave_slope);
	float foam = steep_crest * mix(0.34, 1.0, foam_ribbon) * foam_strength;

	vec3 reflected_sun = reflect(-normalize(sun_direction), world_normal);
	float sun_glint = pow(
		max(dot(reflected_sun, view_direction), 0.0),
		mix(110.0, 250.0, 1.0 - foam)
	);
	sun_glint *= daylight * (1.0 - foam);

	float reflection_amount = mix(0.08, 0.35, fresnel);
	vec3 final_color = mix(water_color, sky_reflection, reflection_amount);
	final_color = mix(final_color, foam_color.rgb, foam);
	final_color += sun_color.rgb * sun_glint * 0.025;
	final_color *= 0.94;

	ALBEDO = final_color;
	ROUGHNESS = mix(0.38, 0.68, foam);
	METALLIC = 0.08;
	SPECULAR = 0.55;
	EMISSION = sky_reflection * fresnel * 0.006;
	ALPHA = 1.0;
}
