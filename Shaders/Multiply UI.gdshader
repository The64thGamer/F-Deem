shader_type canvas_item;

uniform sampler2D overlay: source_color, repeat_enable;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float alphaA : hint_range(0, 10);
uniform float alphaB : hint_range(0, 10);
uniform vec2 offset;

void fragment() {
	vec4 overlay_sample = texture(overlay, UV+offset);
	vec4 screen_sample = texture(screen_texture, SCREEN_UV);

	COLOR.rgb = screen_sample.rgb * clamp((overlay_sample.r+alphaA)*alphaB,0,1);
}