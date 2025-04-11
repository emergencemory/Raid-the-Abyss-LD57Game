shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4( 0.0, 0.0, 1.0, 0.4);
uniform float outline_thickness : hint_range( 1.0, 5.0 ) = 1.0;

float is_filled( float value ) {
	return max( 0.0, sign(value) );
}

float has_solid_neighbor( sampler2D texture_sample, vec2 uv_coord, vec2 pixel_size ) {
	vec2 offset = outline_thickness * pixel_size;
	float sum_alpha = texture( texture_sample, uv_coord + vec2( 1.0, 0.0 ) * offset ).a +
	texture( texture_sample, uv_coord + vec2( 0.0, 1.0 ) * offset ).a +
	texture( texture_sample, uv_coord + vec2( -1.0, 0.0 ) * offset ).a +
	texture( texture_sample, uv_coord + vec2( 0.0, -1.0 ) * offset ).a;
	return is_filled( sum_alpha );
}
void fragment() {
	//skip if filled
	if( COLOR.a == 0.0 ) {
		float outline_mask = has_solid_neighbor( TEXTURE, UV, TEXTURE_PIXEL_SIZE );
		if( outline_mask > 0.0 ) {
			COLOR = outline_color;
		}
	}
}



