
shader_type canvas_item;

uniform float top_left_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float top_right_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float bottom_left_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float bottom_right_radius : hint_range(0.0, 1.0, 0.005) = 0.05;

uniform float antialiasing : hint_range(0.0, 4.0, 0.1) = 1.0;


float rounded_box(vec2 p, vec2 half_size, vec4 radii) {
    float radius;

    if (p.x < 0.0) {
        radius = p.y < 0.0 ? radii.x : radii.w;
    } else {
        radius = p.y < 0.0 ? radii.y : radii.z;
    }

    vec2 q = abs(p) - half_size + radius;

    return length(max(q, vec2(0.0)))
        + min(max(q.x, q.y), 0.0)
        - radius;
}


void fragment() {
    // Read the texture without modifying its RGB values.
    vec4 color = texture(TEXTURE, UV);

    // Screen-space pixel dimensions.
    vec2 pixel_size = fwidth(UV);

    vec2 p = (UV - vec2(0.5)) / pixel_size;
    vec2 half_size = vec2(0.5) / pixel_size;

    // Convert radius fractions into pixel dimensions.
    float max_radius = min(half_size.x, half_size.y);

    vec4 radii = vec4(
        top_left_radius,
        top_right_radius,
        bottom_right_radius,
        bottom_left_radius
    ) * max_radius;

    // Rounded rectangle distance.
    float distance = rounded_box(p, half_size, radii);

    // Antialiasing.
    float aa = max(fwidth(distance) * antialiasing, 0.0001);

    float mask = 1.0 - smoothstep(-aa, aa, distance);

    // Only modify transparency.
    color.a *= mask;

    COLOR = color;
}
