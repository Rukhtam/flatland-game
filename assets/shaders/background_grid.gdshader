shader_type canvas_item;

// Grid background shader for Flatland
// Creates a subtle grid pattern that reinforces the geometric aesthetic

uniform vec4 background_color : source_color = vec4(0.051, 0.067, 0.090, 1.0);
uniform vec4 grid_color : source_color = vec4(0.122, 0.161, 0.216, 1.0);
uniform float grid_size : hint_range(10.0, 200.0) = 50.0;
uniform float line_thickness : hint_range(0.5, 5.0) = 1.0;
uniform float camera_offset_x = 0.0;
uniform float camera_offset_y = 0.0;

void fragment() {
    // Calculate grid-aligned position with camera offset
    vec2 pos = FRAGCOORD.xy + vec2(camera_offset_x, camera_offset_y);

    // Calculate distance to nearest grid line
    vec2 grid_pos = mod(pos, grid_size);
    float dist_x = min(grid_pos.x, grid_size - grid_pos.x);
    float dist_y = min(grid_pos.y, grid_size - grid_pos.y);
    float dist = min(dist_x, dist_y);

    // Smooth edge for anti-aliasing
    float line = 1.0 - smoothstep(0.0, line_thickness, dist);

    // Mix background and grid colors
    COLOR = mix(background_color, grid_color, line);
}
