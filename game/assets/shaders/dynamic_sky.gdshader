shader_type sky;

uniform vec4 zenith_color : source_color = vec4(0.22, 0.48, 0.72, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.7, 0.82, 0.88, 1.0);
uniform vec4 cloud_color : source_color = vec4(0.94, 0.95, 0.93, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.83, 0.55, 1.0);
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

	// Celestial longitude keeps clouds and stars continuous around the rider.
	vec2 panorama_uv = vec2(
		atan(direction.z, direction.x) / 6.2831853 + 0.5,
		acos(clamp(direction.y, -1.0, 1.0)) / 3.14159265
	);
	panorama_uv.x = fract(panorama_uv.x + TIME * 0.00008);
	// A small family of overlapping ellipses creates sculpted cloud silhouettes.
	// Longitude wraps at twelve cells, so there is no panorama seam.
	vec2 cloud_uv = vec2(panorama_uv.x * 12.0, direction.y * 6.5);
	cloud_uv.x += TIME * 0.0015;
	float clouds = 0.0;
	float cloud_depth = 0.0;
	for (int layer = 0; layer < 2; layer++) {
		vec2 p = cloud_uv + vec2(float(layer) * 4.7, -float(layer) * 1.05);
		float cell = floor(p.x);
		float seed = hash21(vec2(mod(cell, 12.0), float(layer)));
		vec2 q = vec2(fract(p.x) - 0.5, p.y - 0.85 - seed * 0.35);
		q /= mix(0.65, 1.0, seed);
		float a = length((q - vec2(-0.2, 0.0)) / vec2(0.23, 0.16));
		float b = length((q - vec2(0.0, 0.1)) / vec2(0.25, 0.28));
		float c = length((q - vec2(0.23, 0.015)) / vec2(0.22, 0.18));
		float d = min(a, min(b, c));
		float mask = (1.0 - smoothstep(0.90, 1.02, d)) * step(seed, cloud_coverage + 0.08);
		clouds = max(clouds, mask);
		cloud_depth = max(cloud_depth, mask * smoothstep(-0.16, 0.27, q.y));
	}
	clouds *= smoothstep(0.03, 0.15, direction.y);
	vec3 shaded_cloud = mix(cloud_color.rgb * vec3(0.62, 0.75, 0.87), cloud_color.rgb * 1.38, cloud_depth);
	float sun_alignment = dot(direction, normalize(sun_direction));
	sky_color = mix(sky_color, shaded_cloud, clouds * 0.96);

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
