shader_type canvas_item;
render_mode blend_add, unshaded;

uniform int   shine_num       = 12;    // quantas “pintas” no anel
uniform float rotation_speed  = 2.0;   // velocidade de giro
uniform float inner_radius    = 0.3;   // raio interno do anel (0..0.5)
uniform float outer_radius    = 0.5;   // raio externo do anel (0..0.5)
uniform float light_magnitude = 0.8;   // força do brilho
uniform vec4  color           : source_color = vec4(1,1,1,1);

void vertex() {
    // nada
}

void fragment() {
    // UV em 0..1 no quad de 128×128
    vec2  c = UV - vec2(0.5);
    float d = length(c);

    // só desenha se estiver dentro do anel
    if (d < inner_radius || d > outer_radius) {
        discard;
    }

    // calcula ângulo e fator de “pinta”
    float ang = atan2(c.y, c.x);
    float f   = abs(sin(ang * float(shine_num) + TIME * rotation_speed));

    // fade radial (fica mais fraco na borda externa)
    float fade = 1.0 - (d - inner_radius) / (outer_radius - inner_radius);

    // cor + alpha
    COLOR = vec4(color.rgb * f, f * fade * light_magnitude);
}
