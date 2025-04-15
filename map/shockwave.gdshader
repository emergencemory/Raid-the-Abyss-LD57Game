shader_type canvas_item;

uniform float force;
uniform float size;
uniform float thickness;
uniform vec2 center;



uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment(){
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 scaledUV = (SCREEN_UV - vec2(0.5, 0.0) ) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
	float mask = (1.0 - smoothstep(size-0.1, size, length(scaledUV - center))) * smoothstep(size-thickness-0.1, size-thickness, length(scaledUV - center));
	vec2 disp = normalize(SCREEN_UV - center) * force;// * mask;
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - disp);
	//COLOR.rgb;

}