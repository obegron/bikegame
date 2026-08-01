shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.82;
uniform float normal_depth : hint_range(0.0, 1.0) = 0.52;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.68;

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

void fragment() {
	vec3 texture_color = texture(albedo_texture, UV).rgb;
	float texture_tone = dot(texture_color, vec3(0.299, 0.587, 0.114));
	vec3 texture_chroma = texture_color / max(texture_tone, 0.08);
	float tonal_detail = mix(1.0, 0.62 + texture_tone * 0.82, detail_strength);
	float broad_wear = (hash21(floor(UV / 3.0)) - 0.5) * 0.035;

	ALBEDO = base_color.rgb * mix(vec3(1.0), texture_chroma, detail_strength * 0.38);
	ALBEDO *= tonal_detail + broad_wear;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = normal_depth;
	ROUGHNESS = mix(roughness_floor, 1.0, texture(roughness_texture, UV).r);
	SPECULAR = 0.22;
}
