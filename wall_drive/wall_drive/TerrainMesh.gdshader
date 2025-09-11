shader_type spatial;

uniform sampler2D heightmap;
uniform sampler2D normalmap;
uniform float terrain_width;
uniform float terrain_depth;
uniform float terrain_height;

varying float height;

vec3 tri_normal(vec3 a, vec3 b, vec3 c) {
	vec3 side1 = b - a;
	vec3 side2 = c = a;
	return normalize(cross(side1, side2));
}

void vertex() {
	//height = textureLod(heightmap, vec2(-VERTEX.x, -VERTEX.z), 0).r * terrain_height;
	height = texelFetch(heightmap, ivec2(vec2(VERTEX.x + terrain_width / 2.0, VERTEX.z + terrain_depth / 2.0)), 0).r * terrain_height;
	VERTEX.y = height;
	COLOR = vec4(height / terrain_height);
	//vec3 a = VERTEX;
	//vec3 b = vec3(VERTEX.x - 1.0, texelFetch(heightmap, ivec2(vec2((VERTEX.x - 1.0) + terrain_width / 2.0, VERTEX.z + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z);
	//vec3 c = vec3(VERTEX.x , texelFetch(heightmap, ivec2(vec2(VERTEX.x + terrain_width / 2.0, (VERTEX.z - 1.0) + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z - 1.0);
	//vec3 side1 = b - a;
	//vec3 side2 = c = a;
	//NORMAL = normalize(cross(side1, side2));
	vec3 up = vec3(VERTEX.x, texelFetch(heightmap, ivec2(vec2(VERTEX.x + terrain_width / 2.0, (VERTEX.z - 1.0) + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z - 1.0);
	vec3 down = vec3(VERTEX.x, texelFetch(heightmap, ivec2(vec2(VERTEX.x + terrain_width / 2.0, (VERTEX.z + 1.0) + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z + 1.0);
	vec3 left = vec3(VERTEX.x - 1.0, texelFetch(heightmap, ivec2(vec2((VERTEX.x - 1.0) + terrain_width / 2.0, VERTEX.z + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z);
	vec3 right = vec3(VERTEX.x + 1.0, texelFetch(heightmap, ivec2(vec2((VERTEX.x + 1.0) + terrain_width / 2.0, VERTEX.z + terrain_depth / 2.0)), 0).r * terrain_height, VERTEX.z);
	NORMAL = normalize(tri_normal(VERTEX, up, right) + tri_normal(VERTEX, right, down) + tri_normal(VERTEX, down, left) + tri_normal(VERTEX, left, up));
	//NORMAL = texelFetch(normalmap, ivec2(vec2(VERTEX.x + terrain_width / 2.0, VERTEX.z + terrain_depth / 2.0)), 0).rgb;
	
	COLOR.rgb = NORMAL;
	//COLOR.rgb = VERTEX.xyz;
}

void fragment() {
	ALBEDO = vec3(height / terrain_height);
	ALBEDO = COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
