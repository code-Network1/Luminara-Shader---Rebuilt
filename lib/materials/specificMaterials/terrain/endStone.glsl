// Developed by EminGT
// Modified by Haider
float factor = pow2(pow2(color.r));
smoothnessG = factor * 0.65;
smoothnessD = smoothnessG * 0.6;

// Add subtle color and light variation to End Stone
vec2 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xz;
float noise1 = fract(sin(dot(worldPos.xy, vec2(12.9898, 78.233))) * 43758.5453);
float noise2 = fract(sin(dot(worldPos.yx, vec2(93.9898, 67.345))) * 28834.3759);
float noise3 = fract(sin(dot(worldPos.xy * 0.5, vec2(41.2648, 85.421))) * 19267.8462);

vec3 colorVariation = vec3(
    1.0 + (noise1 - 0.5) * 0.15,
    1.0 + (noise2 - 0.5) * 0.12, 
    1.0 + (noise3 - 0.5) * 0.18
);

color.rgb *= colorVariation;

// Add variable emission/glow to End Stone
float emissionStrength = (noise1 + noise2 + noise3) / 3.0;
emissionStrength = pow(emissionStrength, 2.0) * 0.25;
emission = max(emission, emissionStrength);

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif
