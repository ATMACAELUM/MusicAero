
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform vec4 glass_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.2;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.012;
uniform float distortion_scale : hint_range(1.0, 40.0) = 12.0;
uniform float animation_speed : hint_range(0.0, 5.0) = 0.5;

uniform float water_strength : hint_range(0.0, 30.0) = 5.0;
uniform float water_scale : hint_range(1.0, 60.0) = 18.0;
uniform float water_speed : hint_range(0.0, 5.0) = 1.0;
uniform float water_highlights : hint_range(0.0, 2.0) = 0.3;
uniform vec4 water_color : source_color = vec4(0.8, 0.95, 1.0, 1.0);

uniform float top_left_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float top_right_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float bottom_left_radius : hint_range(0.0, 1.0, 0.005) = 0.05;
uniform float bottom_right_radius : hint_range(0.0, 1.0, 0.005) = 0.05;

uniform float antialiasing : hint_range(0.0, 4.0, 0.1) = 1.0;

uniform float edge_width : hint_range(0.0, 0.1) = 0.015;
uniform float edge_strength : hint_range(0.0, 2.0) = 0.35;
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.2;
uniform vec4 edge_color : source_color = vec4(1.0);

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
    vec2 pixel_size = fwidth(UV);

    vec2 p = (UV - vec2(0.5)) / pixel_size;
    vec2 half_size = vec2(0.5) / pixel_size;

    float max_radius = min(half_size.x, half_size.y);

    vec4 radii = vec4(
        top_left_radius,
        top_right_radius,
        bottom_right_radius,
        bottom_left_radius
    ) * max_radius;

    float distance = rounded_box(p, half_size, radii);

    float aa = max(fwidth(distance) * antialiasing, 0.0001);
    float mask = 1.0 - smoothstep(-aa, aa, distance);

    float t = TIME * water_speed;

    vec2 wave_uv = UV * water_scale;

    float wave1 = sin(wave_uv.x + wave_uv.y * 0.7 - t);
    float wave2 = sin(wave_uv.y * 1.3 - wave_uv.x * 0.6 + t * 0.8);
    float wave3 = sin((wave_uv.x + wave_uv.y) * 1.8 + t * 0.6);

    float water = (wave1 + wave2 + wave3) / 3.0;

    vec2 water_direction = vec2(
        cos(wave_uv.x + wave_uv.y * 0.7 - t),
        cos(wave_uv.y * 1.3 - wave_uv.x * 0.6 + t * 0.8)
    );

    vec2 water_distortion = water_direction * water_strength;

    vec2 liquid_distortion = vec2(
        sin(UV.y * distortion_scale + t * animation_speed),
        cos(UV.x * distortion_scale - t * animation_speed)
    ) * distortion_strength;

    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 sample_uv = SCREEN_UV
        + liquid_distortion
        + water_distortion / screen_size;

    vec3 background = texture(screen_texture, sample_uv).rgb;

    vec3 glass = mix(background, glass_color.rgb, opacity);

    float shimmer = smoothstep(0.35, 0.95, water * 0.5 + 0.5);
    glass += water_color.rgb * shimmer * water_highlights * 0.12;

    float edge = 1.0 - smoothstep(
        0.0,
        edge_width,
        abs(distance) * min(pixel_size.x, pixel_size.y)
    );

    glass += edge_color.rgb * edge * edge_strength * 0.15;
    glass += edge_color.rgb * edge * highlight_strength * 0.1;

    COLOR = vec4(glass, opacity * mask);
}
