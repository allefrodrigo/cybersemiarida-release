shader_type canvas_item;

uniform vec2 dimensions = vec2(1152.0, 648.0); // Resolução do ColorRect em pixels

uniform float rows = 20.0;
uniform float columns = 5.0;
uniform float vertical_scroll : hint_range(-1.0, 1.0, 0.01) = 0.5;
uniform float horizontal_scroll : hint_range(-1.0, 1.0, 0.01) = 0.1;
uniform float size_min : hint_range(0.1, 1.0, 0.1) = 0.3;
uniform float size_max : hint_range(0.1, 1.0, 0.1) = 0.7;
uniform float wave_min : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float wave_max : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float wave_speed : hint_range(0.0, 2.0, 0.1) = 0.5;
uniform float wave_rotation : hint_range(-1.0, 1.0, 0.1) = 1.0;

uniform vec4 far_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 near_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform sampler2D particle_texture : source_color, filter_nearest_mipmap;

float greater_than(float x, float y) {
    return max(sign(x - y), 0.0);
}

void fragment() {
    float time = 10000.0 + TIME;

    float row_rn = fract(sin(floor((UV.y - vertical_scroll * time) * rows)));
    float column_rn = fract(sin(floor((UV.x + row_rn - horizontal_scroll * time) * columns)));
    float wave = sin(wave_speed * time + column_rn * 90.0);
    vec2 uv = (vec2(fract((UV.x + row_rn - horizontal_scroll * time + (wave * (wave_min + (wave_max - wave_min) * column_rn) / columns / 2.0)) * columns), fract((UV.y - vertical_scroll * time) * rows)) * 2.0 - 1.0) * vec2(dimensions.x / dimensions.y * rows / columns, 1.0);
    float size = size_min + (size_max - size_min) * column_rn;
    vec4 color = mix(far_color, near_color, column_rn);

    float a = ((column_rn + wave) * wave_rotation) * PI;
    uv *= mat2(vec2(sin(a), -cos(a)), vec2(cos(a), sin(a)));

    // Render particles using the 'particle_texture':
    vec4 particle_texture_pixel = texture(particle_texture, (uv / size + 1.0) / 2.0) * color;

    // Set only the particle texture as the color, with its alpha
    COLOR = vec4(particle_texture_pixel.rgb, particle_texture_pixel.a);
}
