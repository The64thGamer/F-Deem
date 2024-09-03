shader_type canvas_item;

uniform sampler2D overlay: source_color;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float alpha : hint_range(0, 1);

void fragment() {
	vec4 overlay_sample = texture(overlay, UV);
	vec4 screen_sample = texture(screen_texture, SCREEN_UV);
	
	COLOR.rgb = screen_sample.rgb * overlay_sample.rgb;
	COLOR.a = alpha;
}