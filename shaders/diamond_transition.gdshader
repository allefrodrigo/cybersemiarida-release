shader_type canvas_item;
render_mode unshaded, blend_mix;

// Vai de 0.0 → 1.0 para controlar a animação
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Tamanho de cada losango em pixels
uniform float diamond_pixel_size : hint_range(1.0, 200.0) = 20.0;
// Tamanho da viewport, embutido pelo Godot
uniform vec2 VIEWPORT_SIZE;

void fragment() {
    // SCREEN_UV varia de (0,0) no topo-esquerdo a (1,1) no baixo-direito
    vec2 uv = SCREEN_UV;
    // Converte para pixels reais
    vec2 px = uv * VIEWPORT_SIZE;

    // Cálculo da fração dentro de cada célula de losango
    float xf = fract(px.x / diamond_pixel_size);
    float yf = fract(px.y / diamond_pixel_size);
    float xd = abs(xf - 0.5);
    float yd = abs(yf - 0.5);

    // “Sweep” diagonalizado pela soma de uv.x+uv.y
    float sweep = uv.x + uv.y;

    // Descarte tudo que ainda NÃO atingiu o progresso
    if (xd + yd + sweep > progress * 4.0) {
        discard;
    }

    // Caso contrário, pinta de preto
    COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}
