shader_type canvas_item;

uniform sampler2D noise : source_color, repeat_enable;

void fragment() {
	float time_value = fract(TIME*.1);
	vec4 color_value = texture(noise, vec2(time_value,UV.x))  ;
	COLOR = color_value ;//mix(color, timed_value, noise_value);
}
