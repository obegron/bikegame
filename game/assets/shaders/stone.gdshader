shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Painted toy finish: broad color and real highlights, without surface grit.
uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.35;
}
