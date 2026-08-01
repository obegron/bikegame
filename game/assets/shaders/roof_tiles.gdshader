shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.6, 0.28, 0.18, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 tiled_uv = UV * vec2(2.0, 2.0);
	vec3 texture_color = texture(albedo_texture, tiled_uv).rgb;
	float texture_tone = dot(texture_color, vec3(0.299, 0.587, 0.114));
	vec2 tile_grid = UV * vec2(16.0, 20.0);
	float row = floor(tile_grid.y);
	tile_grid.x += mod(row, 2.0) * 0.5;
	vec2 within = fract(tile_grid);
	float horizontal_seam = 1.0 - smoothstep(0.025, 0.08, min(within.y, 1.0 - within.y));
	float vertical_seam = 1.0 - smoothstep(0.018, 0.055, min(within.x, 1.0 - within.x));
	float tile_variation = hash21(floor(tile_grid)) - 0.5;
	vec3 tile = base_color.rgb * mix(0.72, texture_tone * 1.55, 0.62);
	tile *= 0.95 + tile_variation * 0.1;
	float seam = max(horizontal_seam, vertical_seam * 0.68);
	ALBEDO = mix(tile, base_color.rgb * 0.55, seam);
	NORMAL_MAP = texture(normal_texture, tiled_uv).rgb;
	NORMAL_MAP_DEPTH = 0.72;
	ROUGHNESS = mix(0.68, 0.96, texture(roughness_texture, tiled_uv).r);
	SPECULAR = 0.32;
}
