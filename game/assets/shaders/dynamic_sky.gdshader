shader_type sky;

uniform vec4 zenith_color : source_color = vec4(0.22, 0.48, 0.72, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.7, 0.82, 0.88, 1.0);
uniform vec4 cloud_color : source_color = vec4(0.94, 0.95, 0.93, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.83, 0.55, 1.0);
uniform sampler2D cloud_panorama : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_direction = vec3(0.0, 0.7, -0.7);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.56;
uniform float cloud_light = 1.0;
uniform float star_visibility : hint_range(0.0, 1.0) = 0.0;
uniform float sun_visibility : hint_range(0.0, 1.0) = 1.0;
uniform float moon_visibility : hint_range(0.0, 1.0) = 0.0;
uniform float lightning_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shooting_star_from = vec3(-0.65, 0.68, -0.34);
uniform vec3 shooting_star_to = vec3(-0.28, 0.34, -0.9);
uniform float shooting_star_progress : hint_range(0.0, 1.0) = 0.0;
uniform float shooting_star_visibility : hint_range(0.0, 1.0) = 0.0;


float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}


vec3 sample_cloud_panorama_seamless(vec2 panorama_uv) {
	float wrapped_u = fract(panorama_uv.x);
	float safe_u = clamp(wrapped_u, 0.0005, 0.9995);
	// Use an explicit mip here: the longitude derivative jumps from 1 back to
	// 0 at the equirectangular wrap, and implicit derivatives can otherwise
	// select the coarsest mip for exactly one vertical pixel.
	vec3 primary = textureLod(
		cloud_panorama,
		vec2(safe_u, panorama_uv.y),
		0.75
	).rgb;
	float seam_distance = min(wrapped_u, 1.0 - wrapped_u);
	const float seam_width = 0.055;
	if (seam_distance < seam_width) {
		float opposite_u = clamp(1.0 - wrapped_u, 0.0005, 0.9995);
		vec3 opposite = textureLod(
			cloud_panorama,
			vec2(opposite_u, panorama_uv.y),
			0.75
		).rgb;
		float seam_blend = (
			1.0 - smoothstep(0.0, seam_width, seam_distance)
		) * 0.5;
		primary = mix(primary, opposite, seam_blend);
	}
	return primary;
}


void sky() {
	vec3 direction = normalize(EYEDIR);
	float sky_height = clamp(direction.y * 0.72 + 0.28, 0.0, 1.0);
	vec3 sky_color = mix(
		horizon_color.rgb,
		zenith_color.rgb,
		pow(sky_height, 0.72)
	);

	float horizon_haze = exp(-abs(direction.y) * 9.0);
	vec3 haze_color = mix(horizon_color.rgb, cloud_color.rgb, 0.14);
	sky_color = mix(sky_color, haze_color, horizon_haze * 0.27);

	// The CC0 panorama supplies only cloud structure. Tint, exposure, sun,
	// moon, and stars remain fully driven by the game's continuous clock.
	vec2 panorama_uv = vec2(
		atan(direction.z, direction.x) / 6.2831853 + 0.5,
		acos(clamp(direction.y, -1.0, 1.0)) / 3.14159265
	);
	panorama_uv.x = fract(panorama_uv.x + TIME * 0.00008);
	vec3 panorama_cloud = sample_cloud_panorama_seamless(panorama_uv);
	float panorama_luma = dot(
		panorama_cloud,
		vec3(0.299, 0.587, 0.114)
	);
	float panorama_chroma = (
		max(panorama_cloud.r, max(panorama_cloud.g, panorama_cloud.b))
		- min(panorama_cloud.r, min(panorama_cloud.g, panorama_cloud.b))
	);
	float cloud_whiteness = panorama_luma - panorama_chroma * 0.48;
	float density_edge = mix(0.58, 0.29, cloud_coverage);
	float clouds = smoothstep(
		density_edge,
		density_edge + 0.17,
		cloud_whiteness
	);
	clouds *= smoothstep(-0.045, 0.1, direction.y);

	float cloud_depth = smoothstep(
		density_edge - 0.06,
		density_edge + 0.34,
		cloud_whiteness
	);
	float cloud_top_light = smoothstep(-0.04, 0.58, direction.y);
	vec3 shaded_cloud = cloud_color.rgb * mix(
		0.46,
		cloud_light,
		cloud_depth * 0.72 + cloud_top_light * 0.28
	);
	float sun_alignment = dot(direction, normalize(sun_direction));
	float sun_nearness = pow(max(sun_alignment, 0.0), 7.0);
	float silver_edge = smoothstep(0.06, 0.3, clouds);
	silver_edge *= 1.0 - smoothstep(0.68, 0.96, clouds);
	shaded_cloud += sun_color.rgb * sun_nearness * silver_edge * 0.3;
	sky_color = mix(sky_color, shaded_cloud, clouds * 0.86);

	vec2 spherical_uv = vec2(
		panorama_uv.x,
		asin(clamp(direction.y, -1.0, 1.0)) / 3.14159265 + 0.5
	);
	vec2 star_grid = spherical_uv * vec2(1100.0, 550.0);
	float star_seed = hash21(floor(star_grid));
	float star_core = smoothstep(0.9962, 0.9998, star_seed);
	float star_twinkle = 0.78 + sin(star_seed * 93.0 + TIME * 0.65) * 0.22;
	float stars = star_core * star_twinkle * star_visibility;
	stars *= smoothstep(0.015, 0.2, direction.y);
	stars *= 1.0 - clouds * 0.97;
	vec3 star_temperature = mix(
		vec3(0.64, 0.76, 1.0),
		vec3(1.0, 0.88, 0.66),
		hash21(floor(star_grid) + 31.7)
	);
	sky_color += star_temperature * stars * 1.7;

	// One continuous great-circle streak. It is dormant nearly all the time;
	// the time-of-day controller briefly drives it during rare clear nights.
	float shooting_tail_progress = max(shooting_star_progress - 0.2, 0.0);
	vec3 shooting_head = normalize(
		mix(shooting_star_from, shooting_star_to, shooting_star_progress)
	);
	vec3 shooting_tail = normalize(
		mix(shooting_star_from, shooting_star_to, shooting_tail_progress)
	);
	vec3 shooting_chord = shooting_head - shooting_tail;
	float shooting_chord_length = max(dot(shooting_chord, shooting_chord), 0.000001);
	float shooting_line_position = clamp(
		dot(direction - shooting_tail, shooting_chord) / shooting_chord_length,
		0.0,
		1.0
	);
	vec3 shooting_nearest = normalize(
		shooting_tail + shooting_chord * shooting_line_position
	);
	float shooting_alignment = dot(direction, shooting_nearest);
	float shooting_core = smoothstep(0.99991, 0.999985, shooting_alignment);
	float shooting_glow = smoothstep(0.99925, 0.99992, shooting_alignment);
	float shooting_head_flare = pow(max(dot(direction, shooting_head), 0.0), 2400.0);
	float shooting_tail_fade = mix(0.08, 1.0, shooting_line_position);
	float shooting_cloud_transmission = 1.0 - clouds * 0.94;
	vec3 shooting_color = vec3(0.72, 0.84, 1.0);
	sky_color += shooting_color * shooting_star_visibility * shooting_cloud_transmission * (
		shooting_core * shooting_tail_fade * 3.2
		+ shooting_glow * shooting_tail_fade * 0.34
		+ shooting_head_flare * 2.1
	);

	float sun_transmission = 1.0 - clouds * 0.8;
	float sun_disk = smoothstep(0.99935, 0.99982, sun_alignment) * sun_visibility;
	float sun_glow = pow(max(sun_alignment, 0.0), 120.0) * sun_visibility;
	float sun_haze = pow(max(sun_alignment, 0.0), 11.0) * sun_visibility;
	sky_color += sun_color.rgb * (
		sun_disk * 3.8
		+ sun_glow * 0.38
		+ sun_haze * 0.075
	) * sun_transmission;

	vec3 moon_direction = normalize(-sun_direction + vec3(0.16, 0.12, -0.08));
	float moon_alignment = dot(direction, moon_direction);
	float moon_disk = smoothstep(0.9989, 0.99945, moon_alignment) * moon_visibility;
	float moon_glow = pow(max(moon_alignment, 0.0), 90.0) * moon_visibility;
	sky_color += vec3(0.68, 0.77, 0.94) * (
		moon_disk * 1.9 + moon_glow * 0.18
	) * (1.0 - clouds * 0.84);
	sky_color += vec3(0.68, 0.79, 1.0) * lightning_flash * (
		0.07 + clouds * 0.19
	);

	COLOR = sky_color;
}
