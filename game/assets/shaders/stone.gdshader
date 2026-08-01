shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.48, 0.44, 0.38, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(41.73, 289.11))) * 43758.5453);
}

void fragment() {
	vec2 tiled_uv = UV * vec2(2.1, 2.1);
	vec3 texture_color = texture(albedo_texture, tiled_uv).rgb;
	float texture_tone = dot(texture_color, vec3(0.299, 0.587, 0.114));
	vec2 block_grid = UV * vec2(9.0, 13.0);
	float row = floor(block_grid.y);
	block_grid.x += mod(row, 2.0) * 0.5;
	vec2 within = fract(block_grid);
	float edge = min(min(within.x, 1.0 - within.x), min(within.y, 1.0 - within.y));
	float mortar = 1.0 - smoothstep(0.035, 0.075, edge);
	float block_variation = hash21(floor(block_grid)) - 0.5;
	vec3 stone = base_color.rgb * mix(0.72, texture_tone * 1.55, 0.68);
	stone *= 0.95 + block_variation * 0.11;
	ALBEDO = mix(stone, base_color.rgb * 0.58, mortar * 0.78);
	NORMAL_MAP = texture(normal_texture, tiled_uv).rgb;
	NORMAL_MAP_DEPTH = 0.62;
	ROUGHNESS = mix(0.78, 1.0, texture(roughness_texture, tiled_uv).r);
	SPECULAR = 0.18;
}
