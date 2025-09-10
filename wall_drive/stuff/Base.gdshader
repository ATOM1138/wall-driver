shader_type spatial;   // Works on 3D objects (use "canvas_item" for 2D)

// Ensure opaque rendering with correct depth
render_mode blend_premul_alpha, depth_draw_always, cull_back;

//--------------------------------
// Material properties (exposed in GUI)
//--------------------------------
uniform sampler2D base_tex;                       // Base texture
uniform bool use_nearest = false;                  // Toggle for nearest filtering
uniform vec4 base_color : source_color = vec4(1.0);

uniform sampler2D emission_tex;                   // Emission texture
uniform float emission_strength : hint_range(-1.0, 10.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(1.0);

uniform sampler2D noise_tex;                      // Noise texture
uniform float shading_strength : hint_range(0.0, 1.0) = 0.9;

// Wiggle controls
uniform float jitter_amount : hint_range(0.0, 0.10) = 5.0;
uniform float jitter_speed = 5;//: hint_range(0.0, 10) = 5.0;
uniform float jitter_scale : hint_range(0.0, 0.10) = 5.0;


// Shimmer controls
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shimmer_speed    : hint_range(0.0, 5.0) = 1.0;
uniform float shimmer_freq     : hint_range(0.0, 5.0) = 1.0;
uniform float shimmer_offset   : hint_range(-1.0, 5.0) = 0.0;
uniform vec4 shimmer_color : source_color = vec4(1.0);

void vertex() {
    if (jitter_amount > 0.0) {
        vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

        // Use a pseudo-random function
        // `dot` and `fract` are used to create a pseudo-random number based on the vertex's world position and time
        float jitter_seed = dot(world_vertex.xyz, vec3(12.9898, 78.233, 45.164)) * jitter_scale;
        float jitter_rand = fract(sin(jitter_seed + TIME * (jitter_speed*0.001)) * 43758.5453);

        // Scale the random number by the jitter amount and apply it to the vertex
        VERTEX.y += (jitter_rand * 2.0 - 1.0) * jitter_amount;
    }
}


//--------------------------------
// Fragment function (color output)
//--------------------------------
//--------------------------------
// Fragment function (color output)
//--------------------------------
void fragment() {
    // Handle texture filtering
    vec4 albedo_tex;
    if (use_nearest) {
        vec2 tex_size = vec2(textureSize(base_tex, 0));
        albedo_tex = texture(base_tex, floor(UV * tex_size) / tex_size);
    } else {
        albedo_tex = texture(base_tex, UV);
    }

    // Apply base color tint
    albedo_tex *= base_color;
    vec3 final_color = albedo_tex.rgb * shading_strength;

    // Emission
    vec3 emissive = texture(emission_tex, UV).rgb * emission_color.rgb * emission_strength;

    // Shimmer
    float shimmer = 0.0;
    if (shimmer_strength > 0.0) {
        float wave = sin(UV.x * shimmer_freq + TIME * shimmer_speed + shimmer_offset);
        shimmer = max(0.0, wave) * shimmer_strength;
    }
    vec3 shimmer_col = shimmer * shimmer_color.rgb;

    // Bayer Dithering Logic
    const mat4 dither_matrix = mat4(
        vec4(0.0,  8.0,  2.0, 10.0),
        vec4(12.0, 4.0, 14.0,  6.0),
        vec4(3.0, 11.0,  1.0,  9.0),
        vec4(15.0, 7.0, 13.0,  5.0)
    );

    // Calculate screen-space coordinates
    vec2 screen_uv = FRAGCOORD.xy;

    // Scale down the screen UV to create larger dither 'pixels'
    vec2 dither_coord = floor(screen_uv / dither_scale);

    // Use the modulo operator to get coordinates within the 4x4 matrix
    vec2 matrix_coord = mod(dither_coord, 4.0);

    // Get the dither threshold value (between 0.0 and 1.0)
    float dither_val = dither_matrix[int(matrix_coord.x)][int(matrix_coord.y)] / 16.0;

    // Apply the dither effect
    final_color = floor(final_color * 255.0 + dither_val) / 255.0;

    // Apply baked lightmap
    vec3 baked_light = texture(lightmap_texture, LIGHTMAP_UV).rgb;
    final_color *= baked_light;

    // Combine
    ALBEDO = final_color + shimmer_col;
    EMISSION = emissive;
    ALPHA = 1.0; // Force fully opaque
}
