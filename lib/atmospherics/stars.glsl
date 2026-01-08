// Developed by EminGT

#include "/lib/colors.glsl"

float GetStarNoise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

vec2 GetStarCoord(vec3 viewPos, float sphereness) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);
    vec3 starCoord = wpos / (wpos.y + length(wpos.xz) * sphereness);
    starCoord.x += 0.006 * syncedTime;
    return starCoord.xz;
}

// Twinkling effect
float GetStarTwinkle(vec2 pos, float time) {
    float noise = GetStarNoise(pos * 10.0);
    float twinkle = sin(time * 2.0 + noise * 6.28318) * 0.3 + 0.7;
    return twinkle;
}

// Get star color based on temperature
vec3 GetStarColor(float temperature) {
    if (temperature > 0.85) return vec3(0.6, 0.7, 1.0);      // Blue-white
    else if (temperature > 0.6) return vec3(1.0, 1.0, 1.0);  // White
    else if (temperature > 0.35) return vec3(1.0, 0.95, 0.75); // Yellow
    else return vec3(1.0, 0.8, 0.5);                         // Orange
}

vec3 GetStars(vec2 starCoord, float VdotU, float VdotS) {
    #if NIGHT_STAR_AMOUNT == 0
        return vec3(0.0, 0.0, 0.0);
    #endif
    if (VdotU < 0.0) return vec3(0.0);

    starCoord *= 0.2;
    float starFactor = 1024.0;
    vec2 gridPos = floor(starCoord * starFactor) / starFactor;

    // Base star generation (same as original)
    float star = 1.0;
    star *= GetStarNoise(gridPos.xy);
    star *= GetStarNoise(gridPos.xy + 0.1);
    star *= GetStarNoise(gridPos.xy + 0.23);

    #if NIGHT_STAR_AMOUNT == 1
        star -= 0.82;
        star *= 2.0;
    #elif NIGHT_STAR_AMOUNT == 2
        star -= 0.7;
    #elif NIGHT_STAR_AMOUNT == 3
        star -= 0.62;
        star *= 0.75;
    #elif NIGHT_STAR_AMOUNT == 4
        star -= 0.52;
        star *= 0.55;
    #endif
    star = max0(star);
    star *= star;

    // Add star enhancements
    float starSize = GetStarNoise(gridPos + 0.5);
    float starTemp = GetStarNoise(gridPos + 0.7);
    
    // Enhanced brightness for larger stars
    star *= mix(1.0, 1.5, starSize);
    
    // Twinkling
    float twinkle = GetStarTwinkle(gridPos, frameTimeCounter);
    star *= twinkle;
    
    // Cross/spike pattern for bright stars
    if (star > 0.5) {
        vec2 localUV = fract(starCoord * starFactor) - 0.5;
        float crossPattern = 0.0;
        
        // Horizontal and vertical spikes
        crossPattern += exp(-abs(localUV.x) * 200.0) * exp(-abs(localUV.y) * 20.0);
        crossPattern += exp(-abs(localUV.y) * 200.0) * exp(-abs(localUV.x) * 20.0);
        
        star += crossPattern * star * 0.3;
    }
    
    // Get star color
    vec3 starColor = GetStarColor(starTemp);
    
    // Environmental factors (same as original)
    star *= min1(VdotU * 3.0) * max0(1.0 - pow(abs(VdotS) * 1.002, 100.0));
    star *= invRainFactor * pow2(pow2(invNoonFactor2)) * (1.0 - 0.5 * sunVisibility);

    return 45.0 * star * starColor;
}
