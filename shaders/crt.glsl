// Optional retro CRT: gentle scanlines + vignette. Enable by pointing
// custom-shader at this file instead of glow.glsl. Tuned to stay readable.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    // Scanlines
    float scan = sin(uv.y * iResolution.y * 3.14159) * 0.04;
    color.rgb -= scan;

    // Vignette
    vec2 c = uv - 0.5;
    float vig = smoothstep(0.85, 0.35, dot(c, c) * 2.0);
    color.rgb *= mix(0.85, 1.0, vig);

    fragColor = color;
}
