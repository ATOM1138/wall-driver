shader_type spatial;

render_mode blend_premul_alpha, depth_draw_always, cull_back;

//--------------------------------
// Material properties (exposed in GUI)
//--------------------------------
uniform sampler2D base_tex;
uniform vec4 base_color : source_color = vec4(1.0);

// AO
uniform sampler2D ao_tex; // AO map
uniform float ao_strength : hint_range(0.0, 1.0) = 1.0;

// Dithering
uniform bool use_dither = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float max_range = 10.0;
uniform float min_range = 2.0;

// Lighting multiplier
uniform float light_strength : hint_range(0.0, 2.0) = 1.0;

//--------------------------------
// Simple Bayer 4x4 matrix for dithering
//--------------------------------
float dither_pattern(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    int index = x + y * 4;
    float threshold[16] = float[](0.0, 0.5, 0.125, 0.625,
                                  0.75, 0.25, 0.875, 0.375,
                                  0.1875, 0.6875, 0.0625, 0.5625,
                                  0.9375, 0.4375, 0.8125, 0.3125);
    return threshold[index];
}

//--------------------------------
// Fragment function (color output)
//--------------------------------
void fragment() {
    // Sample base
    vec4 albedo_tex = texture(base_tex, UV) * base_color;
    vec3 final_color = albedo_tex.rgb;

    // AO
    vec3 ao_col = texture(ao_tex, UV).rrr; // grayscale AO
    final_color *= mix(vec3(1.0), ao_col, ao_strength);

    // Lighting influence (simple multiplier)
    final_color *= light_strength;

    // Distance-based dithering (simulate FX zone)
    if (use_dither) {
        float dist = length(NODE_POSITION_WORLD - CAMERA_POSITION_WORLD);
        float lerp_amt = (1.0 - clamp((dist - min_range) / (max_range - min_range), 0.0, 1.0));
        float threshold = dither_pattern(FRAGCOORD.xy) - 0.5;
        final_color += (threshold * dither_strength * lerp_amt);
    }

    ALBEDO = final_color;
    ALPHA = 1.0;
}
