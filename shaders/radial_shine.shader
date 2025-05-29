shader_type canvas_item;

uniform float shine_num        = 8.0;
uniform float rotation_speed   = 3.0;
uniform float light_magnitude  = 2.0;

uniform float filter_distence  : hint_range(0,1) = 1.0;
uniform float filter_magnitude : hint_range(0,1) = 1.0;
uniform float filter_minv      : hint_range(0,1) = 0.75;
uniform float cut_inner_radius : hint_range(0,1) = 0.1;

uniform vec4    color          : source_color = vec4(1,1,1,1);
uniform sampler2D NOISE        : source_color;
uniform sampler2D NOISE2       : source_color;  // você pode usar NOISE2 se quiser variações
uniform vec2   NOISE_speed     = vec2(0,0);
uniform float  NOISE_magnitude : hint_range(0,1) = 0.0;

void vertex() {
    // nada aqui
}

void fragment() {
    // 1) pega a cor original da sprite
    vec4 base = texture(TEXTURE, UV);
    if (base.a < 0.01) {
        // totalmente transparente na textura: nada a fazer
        COLOR = base;
        return;
    }

    // 2) calcula o brilho radial (igual ao seu)
    float ang = atan((UV.x - 0.5) / (UV.y - 0.5));
    vec2 pos = vec2(
        fract(UV.x + NOISE_speed.x * TIME),
        fract(UV.y + NOISE_speed.y * TIME)
    );
    vec4 mixa = smoothstep(0.0, 1.0, texture(NOISE, pos).rgba);
    vec4 raw_shine = color * vec4(abs(sin(ang * shine_num * 0.5 + TIME * rotation_speed))) * (1.0 - NOISE_magnitude)
                   + NOISE_magnitude * mixa;

    float alpha = ((1.0 - filter_distence * 0.5)
                   - distance(UV, vec2(0.5)) * filter_magnitude)
                   * light_magnitude;

    bool in_ring = distance(UV, vec2(0.5)) <= 0.5
                && distance(UV, vec2(0.5)) >= cut_inner_radius
                && (raw_shine.r >= filter_minv
                    || raw_shine.g >= filter_minv
                    || raw_shine.b >= filter_minv);

    vec4 shine = vec4(raw_shine.rgb,
                      in_ring ? alpha : 0.0);

    // 3) mistura a textura + brilho
    COLOR = base + shine;
}
