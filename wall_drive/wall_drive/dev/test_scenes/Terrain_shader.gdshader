shader_type spatial;

render_mode unshaded;

uniform sampler2D texture_flat : hint_albedo;
uniform sampler2D texture_slight : hint_albedo;
uniform sampler2D texture_steep : hint_albedo;

uniform float slope_flat = 0.95;   // cosine of angle for flat areas (0 = vertical, 1 = horizontal)
uniform float slope_slight = 0.7;  // cosine of angle for slightly sloped areas
uniform float slope_steep = 0.3;   // cosine of angle for steep areas

uniform float uv_scale = 1.0;      // UV tiling for all textures

void fragment() {
    // Calculate slope based on the normal and up vector
    float slope = dot(NORMAL, vec3(0.0, 1.0, 0.0)); // 1 = horizontal, 0 = vertical

    // Sample textures
    vec2 uv = UV * uv_scale;
    vec4 tex_flat = texture(texture_flat, uv);
    vec4 tex_slight = texture(texture_slight, uv);
    vec4 tex_steep = texture(texture_steep, uv);

    // Blend textures based on slope
    float blend_flat = smoothstep(slope_slight, slope_flat, slope);
    float blend_slight = smoothstep(slope_steep, slope_slight, slope) - blend_flat;
    float blend_steep = 1.0 - (blend_flat + blend_slight);

    vec4 final_color = tex_flat * blend_flat + tex_slight * blend_slight + tex_steep * blend_steep;

    ALBEDO = final_color.rgb;
}
