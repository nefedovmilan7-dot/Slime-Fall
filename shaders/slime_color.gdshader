shader_type canvas_item;

uniform vec3 from_colors[6];
uniform vec3 to_colors[6];

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	for (int i = 0; i < 6; i++) {
		if (distance(tex.rgb, from_colors[i]) < 0.02) {
			COLOR.rgb = to_colors[i];
			break;
		}
	}
}