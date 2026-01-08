// Luminara Shader - Rebuilt
// Developed by EminGT
// Colors Library

// ========================================================================
// REQUIRED VARIABLES (if not already defined)
// ========================================================================

#ifndef COLORS_GLSL_INCLUDED
#define COLORS_GLSL_INCLUDED

// Helper functions for consistent calculations
float getSdotU() {
    #ifdef VERTEX_SHADER
        // In vertex shader, vectors might not be available yet
        return 0.0; // Will be calculated after vectors are set
    #else
        // For fragment shader, assume vectors are available as inputs
        return 0.0; // Will be overridden by local variables
    #endif
}

float getSdotU(vec3 sunVector, vec3 upVector) {
    return dot(sunVector, upVector);
}

float getSunFactor() {
    #ifdef VERTEX_SHADER
        return 0.0; // Will be calculated after vectors are set
    #elif defined(FRAGMENT_SHADER)
        float sdotU = getSdotU();
        return sdotU < 0.0 ? clamp(sdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(sdotU + 0.03125, 0.0, 0.0625) / 0.0625;
    #else
        return 0.0;
    #endif
}

float getSunFactor(vec3 sunVector, vec3 upVector) {
    float sdotU = getSdotU(sunVector, upVector);
    return sdotU < 0.0 ? clamp(sdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(sdotU + 0.03125, 0.0, 0.0625) / 0.0625;
}

float getSunVisibility() {
    #ifdef VERTEX_SHADER
        return 0.0; // Will be calculated after vectors are set
    #elif defined(FRAGMENT_SHADER)
        float sdotU = getSdotU();
        return clamp(sdotU + 0.0625, 0.0, 0.125) / 0.125;
    #else
        return 0.0;
    #endif
}

float getSunVisibility(vec3 sunVector, vec3 upVector) {
    float sdotU = getSdotU(sunVector, upVector);
    return clamp(sdotU + 0.0625, 0.0, 0.125) / 0.125;
}

float getSunVisibility2() {
    #ifdef VERTEX_SHADER
        return 0.0; // Will be calculated after vectors are set
    #elif defined(FRAGMENT_SHADER)
        float sunVis = getSunVisibility();
        return sunVis * sunVis;
    #else
        return 0.0;
    #endif
}

float getSunVisibility2(vec3 sunVector, vec3 upVector) {
    float sunVis = getSunVisibility(sunVector, upVector);
    return sunVis * sunVis;
}

float getRainFactor2() {
    return rainFactor * rainFactor;
}

float getNoonFactor() {
    float noonTemp = 1.0 - abs(abs(sunAngle - 0.5) - 0.25) * 4.0;
    return 1.0 - noonTemp * noonTemp;
}

float getInvNoonFactor() {
    return 1.0 - getNoonFactor();
}

float getInvNoonFactor2() {
    float invNoon = getInvNoonFactor();
    return invNoon * invNoon;
}

// Variables for fragment shader are defined later in the specific shader files

// For vertex shader: variables are declared in the specific shader files

// ========================================================================
// MOON PHASE INFLUENCE
// ========================================================================

#ifndef INCLUDE_MOON_PHASE_INF
    #define INCLUDE_MOON_PHASE_INF

    #ifdef OVERWORLD
        float moonPhaseInfluence = mix(
            1.0,
            moonPhase == 0 ? MOON_PHASE_FULL : moonPhase != 4 ? MOON_PHASE_PARTIAL : MOON_PHASE_DARK,
            1.0 - getSunVisibility2()
        );
    #else
        float moonPhaseInfluence = 1.0;
    #endif
#endif

// ========================================================================
// SKY COLORS
// ========================================================================

#ifndef INCLUDE_SKY_COLORS
    #define INCLUDE_SKY_COLORS

    #ifdef OVERWORLD
        vec3 skyColorSqrt = sqrt(skyColor);
        // Doing these things because vanilla skyColor gets to 0 during a thunderstorm
        float invRainStrength2 = (1.0 - rainStrength) * (1.0 - rainStrength);
        vec3 skyColorM = mix(max(skyColorSqrt, vec3(0.63, 0.67, 0.73)), skyColorSqrt, invRainStrength2);
        vec3 skyColorM2 = mix(max(skyColor, getSunFactor() * vec3(0.265, 0.295, 0.35)), skyColor, invRainStrength2);

        #ifdef SPECIAL_BIOME_WEATHER
            vec3 nmscSnowM = inSnowy * vec3(-0.1, 0.3, 0.6);
            vec3 nmscDryM = inDry * vec3(-0.1, -0.2, -0.3);
            vec3 ndscSnowM = inSnowy * vec3(-0.25, -0.01, 0.25);
            vec3 ndscDryM = inDry * vec3(-0.05, -0.09, -0.1);
        #else
            vec3 nmscSnowM = vec3(0.0), nmscDryM = vec3(0.0), ndscSnowM = vec3(0.0), ndscDryM = vec3(0.0);
        #endif
        #if RAIN_STYLE == 2
            vec3 nmscRainMP = vec3(-0.15, 0.025, 0.1);
            vec3 ndscRainMP = vec3(-0.125, -0.005, 0.125);
            #ifdef SPECIAL_BIOME_WEATHER
                vec3 nmscRainM = inRainy * ndscRainMP;
                vec3 ndscRainM = inRainy * ndscRainMP;
            #else
                vec3 nmscRainM = ndscRainMP;
                vec3 ndscRainM = ndscRainMP;
            #endif
        #else
            vec3 nmscRainM = vec3(0.0), ndscRainM = vec3(0.0);
        #endif
        vec3 nuscWeatherM = vec3(0.1, 0.0, 0.1);
        vec3 nmscWeatherM = vec3(-0.1, -0.4, -0.6) + vec3(0.0, 0.06, 0.12) * noonFactor;
        vec3 ndscWeatherM = vec3(-0.15, -0.3, -0.42) + vec3(0.0, 0.02, 0.08) * noonFactor;

        vec3 noonUpSkyColor     = pow(skyColorM, vec3(2.9)) * (vec3(0.85, 0.92, 0.81) + rainFactor * nuscWeatherM);
        vec3 noonMiddleSkyColor = pow(skyColorM, vec3(1.5)) * (vec3(1.35) + rainFactor * (nmscWeatherM + nmscRainM + nmscSnowM + nmscDryM))
                                + noonUpSkyColor * 0.65;
        vec3 noonDownSkyColor   = skyColorM * (vec3(0.9) + rainFactor * (ndscWeatherM + ndscRainM + ndscSnowM + ndscDryM))
                                + noonUpSkyColor * 0.25;

        vec3 sunsetUpSkyColor     = skyColorM2 * (vec3(0.72, 0.522, 0.47) + vec3(0.1, 0.2, 0.35) * rainFactor2);
        vec3 sunsetMiddleSkyColor = skyColorM2 * (vec3(1.8, 1.3, 1.2) + vec3(0.15, 0.25, -0.05) * rainFactor2);
        vec3 sunsetDownSkyColorP  = vec3(1.45, 0.86, 0.5) - vec3(0.8, 0.3, 0.0) * rainFactor;
        vec3 sunsetDownSkyColor   = sunsetDownSkyColorP * 0.5 + 0.25 * sunsetMiddleSkyColor;

        vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2);
        vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2);
        vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor, invNoonFactor2);

        vec3 nightColFactor      = 0.9 * vec3(0.05, 0.12, 0.35) * (1.0 - 0.5 * rainFactor) + skyColor;
        vec3 nightUpSkyColor     = pow(nightColFactor, vec3(0.85)) * 0.55;
        vec3 nightMiddleSkyColor = sqrt(nightUpSkyColor) * 0.75;
        vec3 nightDownSkyColor   = nightMiddleSkyColor * vec3(0.70, 0.85, 1.15);
    #endif
    
    // Fallback definitions for non-overworld dimensions
    #if !defined OVERWORLD
        vec3 dayMiddleSkyColor = vec3(0.3, 0.5, 0.8);
        vec3 nightMiddleSkyColor = vec3(0.05, 0.1, 0.15);
    #endif

#endif //INCLUDE_SKY_COLORS

// ========================================================================
// LIGHT AND AMBIENT COLORS
// ========================================================================

#ifndef INCLUDE_LIGHT_AND_AMBIENT_COLORS
    #define INCLUDE_LIGHT_AND_AMBIENT_COLORS

    #if defined OVERWORLD
        #ifndef COMPOSITE1
            vec3 noonClearLightColor = vec3(0.65, 0.55, 0.375) * 2.05; //ground and cloud color
        #else
            vec3 noonClearLightColor = vec3(0.4, 0.75, 1.3); //light shaft color
        #endif
        vec3 noonClearAmbientColor = pow(skyColor, vec3(0.75)) * 0.85;

        #ifndef COMPOSITE1
            vec3 sunsetClearLightColor = pow(vec3(0.64, 0.45, 0.3), vec3(1.5 + invNoonFactor)) * 5.0; //ground and cloud color
        #else
            vec3 sunsetClearLightColor = pow(vec3(0.62, 0.39, 0.24), vec3(1.5 + invNoonFactor)) * 6.8; //light shaft color
        #endif
        vec3 sunsetClearAmbientColor   = noonClearAmbientColor * vec3(1.21, 0.92, 0.76) * 0.95;

        #if !defined COMPOSITE1 && !defined DEFERRED1
            vec3 nightClearLightColor = 0.9 * vec3(0.15, 0.14, 0.20) * (0.4 + vsBrightness * 0.4); //ground color
        #elif defined DEFERRED1
            vec3 nightClearLightColor = 0.9 * vec3(0.11, 0.14, 0.20); //cloud color
        #else
            vec3 nightClearLightColor = vec3(0.08, 0.12, 0.23); //light shaft color
        #endif
        vec3 nightClearAmbientColor   = 0.9 * vec3(0.09, 0.12, 0.17) * (1.55 + vsBrightness * 0.77);

        #ifdef SPECIAL_BIOME_WEATHER
            vec3 drlcSnowM = inSnowy * vec3(-0.06, 0.0, 0.04);
            vec3 drlcDryM = inDry * vec3(0.01, -0.035, -0.06);
        #else
            vec3 drlcSnowM = vec3(0.0), drlcDryM = vec3(0.0);
        #endif
        #if RAIN_STYLE == 2
            vec3 drlcRainMP = vec3(-0.03, 0.0, 0.02);
            #ifdef SPECIAL_BIOME_WEATHER
                vec3 drlcRainM = inRainy * drlcRainMP;
            #else
                vec3 drlcRainM = drlcRainMP;
            #endif
        #else
            vec3 drlcRainM = vec3(0.0);
        #endif
        vec3 dayRainLightColor   = vec3(0.21, 0.16, 0.13) * 0.85 + noonFactor * vec3(0.0, 0.02, 0.06)
                                + rainFactor * (drlcRainM + drlcSnowM + drlcDryM);
        vec3 dayRainAmbientColor = vec3(0.2, 0.2, 0.25) * (1.8 + 0.5 * vsBrightness);

        vec3 nightRainLightColor   = vec3(0.03, 0.035, 0.05) * (0.5 + 0.5 * vsBrightness);
        vec3 nightRainAmbientColor = vec3(0.16, 0.20, 0.3) * (0.75 + 0.6 * vsBrightness);

        #ifndef COMPOSITE1
            float noonFactorDM = noonFactor; //ground and cloud factor
        #else
            float noonFactorDM = noonFactor * noonFactor; //light shaft factor
        #endif
        vec3 dayLightColor   = mix(sunsetClearLightColor, noonClearLightColor, noonFactorDM);
        vec3 dayAmbientColor = mix(sunsetClearAmbientColor, noonClearAmbientColor, noonFactorDM);

        vec3 clearLightColor   = mix(nightClearLightColor, dayLightColor, getSunVisibility2());
        vec3 clearAmbientColor = mix(nightClearAmbientColor, dayAmbientColor, getSunVisibility2());

        vec3 rainLightColor   = mix(nightRainLightColor, dayRainLightColor, getSunVisibility2()) * 2.5;
        vec3 rainAmbientColor = mix(nightRainAmbientColor, dayRainAmbientColor, getSunVisibility2());

        vec3 lightColor   = mix(clearLightColor, rainLightColor, rainFactor);
        vec3 ambientColor = mix(clearAmbientColor, rainAmbientColor, rainFactor);
    #elif defined NETHER
        vec3 lightColor   = vec3(0.0);
        vec3 ambientColor = (netherColor + 0.5 * lavaLightColor) * (0.9 + 0.45 * vsBrightness);
    #elif defined END
        vec3 endLightColor = vec3(0.68, 0.51, 1.07);
        vec3 endOrangeCol = vec3(1.0, 0.3, 0.0);
        float endLightBalancer = 0.2 * vsBrightness;
        vec3 lightColor    = endLightColor * (0.35 - endLightBalancer);
        vec3 ambientColor  = endLightColor * (0.2 + endLightBalancer);
    #endif

#endif //INCLUDE_LIGHT_AND_AMBIENT_COLORS

// ========================================================================
// COLOR MULTIPLIERS
// ========================================================================

#ifndef INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS
    #define INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS

    vec3 GetLightColorMult() {
        vec3 lightColorMult;

        #ifdef OVERWORLD
            vec3 morningLightMult = vec3(LIGHT_MORNING_R, LIGHT_MORNING_G, LIGHT_MORNING_B) * LIGHT_MORNING_I;
            vec3 noonLightMult = vec3(LIGHT_NOON_R, LIGHT_NOON_G, LIGHT_NOON_B) * LIGHT_NOON_I;
            vec3 nightLightMult = vec3(LIGHT_NIGHT_R, LIGHT_NIGHT_G, LIGHT_NIGHT_B) * LIGHT_NIGHT_I;
            vec3 rainLightMult = vec3(LIGHT_RAIN_R, LIGHT_RAIN_G, LIGHT_RAIN_B) * LIGHT_RAIN_I;

            lightColorMult = mix(noonLightMult, morningLightMult, invNoonFactor2);
            lightColorMult = mix(nightLightMult, lightColorMult, getSunVisibility2());
            lightColorMult = mix(lightColorMult, dot(lightColorMult, vec3(0.33333)) * rainLightMult, rainFactor);
        #elif defined NETHER
            vec3 netherLightMult = vec3(LIGHT_NETHER_R, LIGHT_NETHER_G, LIGHT_NETHER_B) * LIGHT_NETHER_I;

            lightColorMult = netherLightMult;
        #elif defined END
            vec3 endLightMult = vec3(LIGHT_END_R, LIGHT_END_G, LIGHT_END_B) * LIGHT_END_I;

            lightColorMult = endLightMult;
        #endif

        return lightColorMult;
    }

    vec3 GetAtmColorMult() {
        vec3 atmColorMult;

        #ifdef OVERWORLD
            vec3 morningAtmMult = vec3(ATM_MORNING_R, ATM_MORNING_G, ATM_MORNING_B) * ATM_MORNING_I;
            vec3 noonAtmMult = vec3(ATM_NOON_R, ATM_NOON_G, ATM_NOON_B) * ATM_NOON_I;
            vec3 nightAtmMult = vec3(ATM_NIGHT_R, ATM_NIGHT_G, ATM_NIGHT_B) * ATM_NIGHT_I;
            vec3 rainAtmMult = vec3(ATM_RAIN_R, ATM_RAIN_G, ATM_RAIN_B) * ATM_RAIN_I;

            atmColorMult = mix(noonAtmMult, morningAtmMult, invNoonFactor2);
            atmColorMult = mix(nightAtmMult, atmColorMult, getSunVisibility2());
            atmColorMult = mix(atmColorMult, dot(atmColorMult, vec3(0.33333)) * rainAtmMult, rainFactor);
        #elif defined NETHER
            vec3 netherAtmMult = vec3(ATM_NETHER_R, ATM_NETHER_G, ATM_NETHER_B) * ATM_NETHER_I;

            atmColorMult = netherAtmMult;
        #elif defined END
            vec3 endAtmMult = vec3(ATM_END_R, ATM_END_G, ATM_END_B) * ATM_END_I;

            atmColorMult = endAtmMult;
        #endif

        return atmColorMult;
    }

    vec3 lightColorMult;
    vec3 atmColorMult;
    vec3 sqrtAtmColorMult;

#endif //INCLUDE_LIGHT_AND_AMBIENT_MULTIPLIERS

// ========================================================================
// CLOUD COLORS
// ========================================================================

vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor, getSunFactor());
vec3 cloudAmbientColor = mix(ambientColor * (getSunVisibility2() * (0.55 + 0.17 * getNoonFactor()) + 0.35), cloudRainColor * 0.5, rainFactor);
vec3 cloudLightColor   = mix(
    lightColor * 1.3,
    cloudRainColor * 0.45,
    noonFactor * rainFactor
);

// ========================================================================
// BLOCKLIGHT COLORS
// ========================================================================

vec3 blocklightCol = vec3(0.1775, 0.104, 0.077) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B);

void AddSpecialLightDetail(inout vec3 light, vec3 albedo, float emission) {
	vec3 lightM = max(light, vec3(0.0));
	lightM /= (0.2 + 0.8 * GetLuminance(lightM));
	lightM *= (1.0 / (1.0 + emission)) * 0.22;
	light *= 0.9;
	light += pow2(lightM / (albedo + 0.1));
}

vec3 fireSpecialLightColor = vec3(2.25, 0.83, 0.27) * 3.7;
vec3 lavaSpecialLightColor = vec3(3.25, 0.9, 0.2) * 3.9;
vec3 netherPortalSpecialLightColor = vec3(1.8, 0.4, 2.2) * 0.8;
vec3 redstoneSpecialLightColor = vec3(4.0, 0.1, 0.1);
vec4 soulFireSpecialColor = vec4(vec3(0.3, 2.0, 2.2) * 1.0, 0.3);
float candleColorMult = 2.0;
float candleExtraLight = 0.004;

vec4 GetSpecialBlocklightColor(int mat) {
	/* Please note that these colors do not determine the intensity of the
	final light. Instead; higher values of color change how long the color
	will travel, and also how dominant it will be next to other colors.*/
	/* Additional feature: An alpha value bigger than 0 will make that
	block cast extra light regardless of the vanilla lightmap. Use this
	with caution though because our floodfill isn't as accurate as vanilla.*/

	if (mat < 50) {
		if (mat < 26) {
			if (mat < 14) {
				if (mat < 8) {
					if (mat < 5) {
						if (mat == 2) return vec4(fireSpecialLightColor, 0.0); // Torch
						#ifndef END
							if (mat == 3) return vec4(vec3(1.0, 1.0, 1.0) * 4.0, 0.0); // End Rod - This is the base for all lights. Total value 12
						#else
							if (mat == 3) return vec4(vec3(1.25, 0.5, 1.25) * 4.0, 0.0); // End Rod in the End dimension
						#endif
						if (mat == 4) return vec4(vec3(0.7, 1.5, 2.0) * 3.0, 0.0); // Beacon
					} else {
						if (mat == 5) return vec4(fireSpecialLightColor, 0.0); // Fire
						if (mat == 6) return vec4(vec3(0.7, 1.5, 1.5) * 1.7, 0.0); // Sea Pickle:Waterlogged
						if (mat == 7) return vec4(vec3(1.1, 0.85, 0.35) * 5.0, 0.0); // Ochre Froglight
					}
				} else {
					if (mat < 11) {
						if (mat == 8) return vec4(vec3(0.6, 1.3, 0.6) * 4.5, 0.0); // Verdant Froglight
						if (mat == 9) return vec4(vec3(1.1, 0.5, 0.9) * 4.5, 0.0); // Pearlescent Froglight
						if (mat == 10) return vec4(vec3(1.7, 0.9, 0.4) * 4.0, 0.0); // Glowstone
					} else {
						if (mat == 11) return vec4(fireSpecialLightColor, 0.0); // Jack o'Lantern
						if (mat == 12) return vec4(fireSpecialLightColor, 0.0); // Lantern
						if (mat == 13) return vec4(lavaSpecialLightColor, 0.8); // Lava
					}
				}
			} else {
				if (mat < 20) {
					if (mat < 17) {
						if (mat == 14) return vec4(lavaSpecialLightColor, 0.0); // Lava Cauldron
						if (mat == 15) return vec4(fireSpecialLightColor, 0.0); // Campfire:Lit
						if (mat == 16) return vec4(vec3(1.7, 0.9, 0.4) * 4.0, 0.0); // Redstone Lamp:Lit
					} else {
						if (mat == 17) return vec4(vec3(1.7, 0.9, 0.4) * 2.0, 0.0); // Respawn Anchor:Lit
						if (mat == 18) return vec4(vec3(1.0, 1.25, 1.5) * 3.4, 0.0); // Sea Lantern
						if (mat == 19) return vec4(vec3(3.0, 0.9, 0.2) * 3.0, 0.0); // Shroomlight
					}
				} else {
					if (mat < 23) {
						if (mat == 20) return vec4(vec3(2.3, 0.9, 0.2) * 3.4, 0.0); // Cave Vines:With Glow Berries
						if (mat == 21) return vec4(fireSpecialLightColor * 0.7, 0.0); // Furnace:Lit
						if (mat == 22) return vec4(fireSpecialLightColor * 0.7, 0.0); // Smoker:Lit
					} else {
						if (mat == 23) return vec4(fireSpecialLightColor * 0.7, 0.0); // Blast Furnace:Lit
						if (mat == 24) return vec4(fireSpecialLightColor * 0.25 * candleColorMult, candleExtraLight); // Standard Candles:Lit
						if (mat == 25) return vec4(netherPortalSpecialLightColor * 2.0, 0.4); // Nether Portal
					}
				}
			}
		} else {
			if (mat < 38) {
				if (mat < 32) {
					if (mat < 29) {
						if (mat == 26) return vec4(netherPortalSpecialLightColor, 0.0); // Crying Obsidian
						if (mat == 27) return soulFireSpecialColor; // Soul Fire
						if (mat == 28) return soulFireSpecialColor; // Soul Torch
					} else {
						if (mat == 29) return soulFireSpecialColor; // Soul Lantern
						if (mat == 30) return soulFireSpecialColor; // Soul Campfire:Lit
						if (mat == 31) return vec4(redstoneSpecialLightColor * 0.5, 0.1); // Redstone Ores:Lit
					}
				} else {
					if (mat < 35) {
						if (mat == 32) return vec4(redstoneSpecialLightColor * 0.3, 0.1) * GLOWING_ORE_MULT; // Redstone Ores:Unlit
						if (mat == 33) return vec4(vec3(1.4, 1.1, 0.5), 0.0); // Enchanting Table
						#if GLOWING_LICHEN > 0
							if (mat == 34) return vec4(vec3(0.8, 1.1, 1.1), 0.05); // Glow Lichen with IntegratedPBR
						#else
							if (mat == 34) return vec4(vec3(0.4, 0.55, 0.55), 0.0); // Glow Lichen vanilla
						#endif
					} else {
						if (mat == 35) return vec4(redstoneSpecialLightColor * 0.25, 0.0); // Redstone Torch
						if (mat == 36) return vec4(vec3(0.325, 0.15, 0.425) * 2.0, 0.05); // Amethyst Cluster, Amethyst Buds, Calibrated Sculk Sensor
						if (mat == 37) return vec4(vec3(1.0, 0.4, 0.5) * candleColorMult, candleExtraLight); // Pink Candles:Lit
					}
				}
			} else {
				if (mat < 44) {
					if (mat < 41) {
						if (mat == 38) return vec4(vec3(2.0, 0.4, 0.1) * candleColorMult, candleExtraLight); // Red Candles:Lit
						if (mat == 39) return vec4(vec3(2.0, 1.0, 0.4) * candleColorMult, candleExtraLight); // Orange Candles:Lit
						if (mat == 40) return vec4(vec3(2.0, 2.0, 0.4) * candleColorMult, candleExtraLight); // Yellow Candles:Lit
					} else {
						if (mat == 41) return vec4(vec3(0.4, 2.0, 0.4) * candleColorMult, candleExtraLight); // Lime Candles:Lit
						if (mat == 42) return vec4(vec3(0.4, 2.0, 0.4) * candleColorMult, candleExtraLight); // Green Candles:Lit
						if (mat == 43) return vec4(vec3(0.4, 2.0, 2.0) * candleColorMult, candleExtraLight); // Cyan Candles:Lit
					}
				} else {
					if (mat < 47) {
						if (mat == 44) return vec4(vec3(0.4, 1.0, 2.0) * candleColorMult, candleExtraLight); // Light Blue Candles:Lit
						if (mat == 45) return vec4(vec3(0.4, 0.4, 2.0) * candleColorMult, candleExtraLight); // Blue Candles:Lit
						if (mat == 46) return vec4(vec3(1.0, 0.4, 2.0) * candleColorMult, candleExtraLight); // Purple Candles:Lit
					} else {
						if (mat == 47) return vec4(vec3(2.0, 0.4, 2.0) * candleColorMult, candleExtraLight); // Magenta Candles:Lit
						if (mat == 48) return vec4(vec3(0.4, 0.4, 0.4) * candleColorMult, candleExtraLight); // Gray Candles:Lit
						if (mat == 49) return vec4(vec3(1.0, 1.0, 1.0) * candleColorMult, candleExtraLight); // Light Gray Candles:Lit
					}
				}
			}
		}
	} else {
		if (mat < 75) {
			if (mat < 63) {
				if (mat < 57) {
					if (mat < 54) {
						if (mat == 50) return vec4(vec3(1.0, 1.0, 1.0) * candleColorMult, candleExtraLight); // White Candles:Lit
						if (mat == 51) return vec4(vec3(0.2, 0.2, 0.2) * candleColorMult, candleExtraLight); // Black Candles:Lit
						if (mat == 52) return vec4(vec3(1.0, 0.5, 0.2) * candleColorMult, candleExtraLight); // Brown Candles:Lit
					} else {
						if (mat == 54) return vec4(vec3(1.0, 0.8, 0.4) * 6.0, 0.0); // Ancient Debris, Gilded Blackstone
						if (mat == 55) return vec4(vec3(1.0, 0.6, 0.4) * 0.6, 0.01); // Copper: Waxed, Oxidizing, Weathered, Exposed
						if (mat == 56) return vec4(vec3(0.3, 0.7, 0.3) * 6.0, 0.0); // Emerald Ore, Emerald Block
					}
				} else {
					if (mat < 60) {
						if (mat == 57) return vec4(vec3(0.1, 0.3, 0.7) * 6.0, 0.0); // Lapis Lazuli Ore, Lapis Lazuli Block, Diamond Ore, Diamond Block
						if (mat == 58) return vec4(vec3(0.7, 0.4, 0.1) * 6.0, 0.0); // Nether Gold Ore, Gold Ore, Gold Block
						if (mat == 59) return vec4(vec3(1.0, 1.0, 1.0) * 6.0, 0.0); // Iron Ore, Iron Block, Quartz Ore, Block of Quartz
					} else {
						if (mat == 60) return vec4(vec3(0.8, 0.4, 0.1) * 6.0, 0.0); // Copper Ore, Copper Block
						if (mat == 61) return vec4(vec3(0.1, 0.5, 0.2) * 6.0, 0.0); // Coal Ore, Coal Block
						if (mat == 62) return vec4(vec3(0.9, 0.2, 0.9) * 4.5, 0.0); // Purpur blocks
					}
				}
			} else {
				if (mat < 69) {
					if (mat < 66) {
						if (mat == 63) return vec4(vec3(0.5, 0.5, 0.9) * 3.5, 0.0); // End Stone blocks
						if (mat == 64) return vec4(vec3(0.7, 1.1, 0.6) * 1.5, 0.05); // Sculk blocks
						if (mat == 65) return vec4(vec3(0.7, 1.1, 0.6) * 3.0, 0.2); // Sculk Sensor
					} else {
						if (mat == 66) return vec4(vec3(0.7, 1.1, 0.6) * 4.5, 0.3); // Sculk Shrieker
						if (mat == 67) return vec4(vec3(0.7, 1.1, 0.6) * 6.0, 0.4); // Sculk Catalyst
						if (mat == 68) return vec4(vec3(2.5, 0.7, 0.2) * 5.0, 0.0); // Ochre Froglight Large
					}
				} else {
					if (mat < 72) {
						if (mat == 69) return vec4(vec3(0.4, 2.0, 0.4) * 4.5, 0.0); // Verdant Froglight Large
						if (mat == 70) return vec4(vec3(2.0, 0.4, 1.6) * 4.5, 0.0); // Pearlescent Froglight Large
						if (mat == 71) return vec4(vec3(2.25, 0.83, 0.27) * 2.4, 0.0); // Campfire:Unlit
					} else {
						if (mat == 72) return vec4(vec3(0.3, 2.0, 2.2) * 0.6, 0.0); // Soul Campfire:Unlit
						if (mat == 73) return vec4(vec3(0.3, 2.0, 2.2) * 3.0, 0.0); // Soul Torch Large, Soul Lantern Large
						if (mat == 74) return vec4(vec3(2.25, 0.83, 0.27) * 4.8, 0.0); // Torch Large, Lantern Large
					}
				}
			}
		} else {
			if (mat < 87) {
				if (mat < 81) {
					if (mat < 78) {
						if (mat == 75) return vec4(vec3(1.1, 0.85, 0.35) * 6.5, 0.0); // Ochre Froglight Huge
						if (mat == 76) return vec4(vec3(0.6, 1.3, 0.6) * 5.8, 0.0); // Verdant Froglight Huge
						if (mat == 77) return vec4(vec3(1.1, 0.5, 0.9) * 5.8, 0.0); // Pearlescent Froglight Huge
					} else {
						if (mat == 78) return vec4(vec3(2.8, 1.1, 0.2) * 0.05, 0.0); // Closed Eyeblossom
						if (mat == 79) return vec4(vec3(2.8, 1.1, 0.2) * 0.1, 0.005); // Open Eyeblossom Small
						if (mat == 80) return vec4(vec3(2.8, 1.1, 0.2) * 0.08, 0.01); // Open Eyeblossom Medium
					}
				} else {
					if (mat < 84) {
						if (mat == 81) return vec4(vec3(2.8, 1.1, 0.2) * 0.125, 0.0125); // Open Eyeblossom
						if (mat == 82) return vec4(vec3(2.8, 1.1, 0.2) * 0.3, 0.05); // Creaking Heart: Active
						if (mat == 83) return vec4(vec3(1.6, 1.6, 0.7) * 0.3, 0.05); // Firefly Bush
					} else {
						if (mat == 84) return vec4(vec3(0.85, 1.3, 1.0) * 3.9, 0.0); // Copper Torch, Copper Lantern
						if (mat == 85) return vec4(0.0);
						if (mat == 86) return vec4(0.0);
					}
				}
			} else {
				if (mat < 94) {
					if (mat < 91) {
						if (mat == 87) return vec4(0.0);
						if (mat == 88) return vec4(0.0);
						if (mat == 89) return vec4(0.0);
					} else {
						if (mat == 90) return vec4(0.0);
						if (mat == 91) return vec4(0.0);
						if (mat == 92) return vec4(0.0);
					}
				} else {
					if (mat < 97) {
						if (mat == 93) return vec4(0.0);
						if (mat == 94) return vec4(0.0);
						if (mat == 95) return vec4(0.0);
					} else {
						if (mat == 96) return vec4(0.0);
						if (mat == 97) return vec4(0.0);
					}
				}
			}
		}
	}

	return vec4(blocklightCol * 20.0, 0.0);
}

vec3[] specialTintColor = vec3[](
	// 200: White
	vec3(1.0),
	// 201: Orange
	vec3(1.0, 0.3, 0.1),
	// 202: Magenta
	vec3(1.0, 0.1, 1.0),
	// 203: Light Blue
	vec3(0.5, 0.65, 1.0),
	// 204: Yellow
	vec3(1.0, 1.0, 0.1),
	// 205: Lime
	vec3(0.1, 1.0, 0.1),
	// 206: Pink
	vec3(1.0, 0.4, 1.0),
	// 207: Gray
	vec3(1.0),
	// 208: Light Gray
	vec3(1.0),
	// 209: Cyan
	vec3(0.3, 0.8, 1.0),
	// 210: Purple
	vec3(0.7, 0.3, 1.0),
	// 211: Blue
	vec3(0.1, 0.15, 1.0),
	// 212: Brown
	vec3(1.0, 0.75, 0.5),
	// 213: Green
	vec3(0.3, 1.0, 0.3),
	// 214: Red
	vec3(1.0, 0.1, 0.1),
	// 215: Black
	vec3(1.0),
	// 216: Ice
	vec3(0.5, 0.65, 1.0),
	// 217: Glass
	vec3(1.0),
	// 218: Glass Pane
	vec3(1.0),
	// 219++
	vec3(0.0)
);

#endif // COLORS_GLSL_INCLUDED
