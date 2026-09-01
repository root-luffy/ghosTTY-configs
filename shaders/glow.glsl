// Subtle neon bloom — makes bright text/colors glow without hurting readability.
// Ghostty passes the rendered terminal in iChannel0 (Shadertoy-style).
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 base = texture(iChannel0, uv);

    vec2 px = 1.0 / iResolution.xy;
    vec4 sum = vec4(0.0);
    // 5x5 weighted sample, biased toward bright pixels -> only bright neon glows.
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 off = vec2(float(x), float(y)) * px * 1.5;
            vec4 s = texture(iChannel0, uv + off);
            float bright = max(max(s.r, s.g), s.b);
            sum += s * bright;
        }
    }
    vec4 bloom = sum / 25.0;

    // 0.28 = subtle. Raise toward 0.6 for a heavier glow, lower to 0.0 to disable.
    fragColor = base + bloom * 0.28;
}
