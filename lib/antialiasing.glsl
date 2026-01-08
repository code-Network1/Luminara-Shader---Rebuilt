// Developed by EminGT
// Modified by Haider
// Luminara Shader - Rebuilt
// Antialiasing Library

// ========================================================================
// COMMON ARRAYS AND VARIABLES
// ========================================================================

// Neighbourhood offsets for sampling (used by both FXAA and TAA)
ivec2 neighbourhoodOffsets[8] = ivec2[8](
    ivec2( 1, 1),
    ivec2( 1,-1),
    ivec2(-1, 1),
    ivec2(-1,-1),
    ivec2( 1, 0),
    ivec2( 0, 1),
    ivec2(-1, 0),
    ivec2( 0,-1)
);

// ========================================================================
// JITTER FUNCTIONS (Available in all contexts)
// ========================================================================

// Jitter offset from Chocapic13
vec2 jitterOffsets[8] = vec2[8](
                        vec2( 0.125,-0.375),
                        vec2(-0.125, 0.375),
                        vec2( 0.625, 0.125),
                        vec2( 0.375,-0.625),
                        vec2(-0.625, 0.625),
                        vec2(-0.875,-0.125),
                        vec2( 0.375,-0.875),
                        vec2( 0.875, 0.875)
                        );

vec2 TAAJitter(vec2 coord, float w) {
    vec2 offset = jitterOffsets[int(framemod8)] * (w / vec2(viewWidth, viewHeight));
    #if TAA_MODE == 1
        offset *= 0.125;
    #endif
    return coord + offset;
}

// ========================================================================
// FXAA FUNCTIONS (Requires: texelCoord, GetLuminance, colortex3, texCoord)
// ========================================================================

#ifdef FXAA_FUNCTIONS_AVAILABLE

// neighbourhoodOffsets is now defined globally above

// Luminara Shader - Rebuilt
// FXAA 3.11
float quality[12] = float[12] (1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

void FXAA311(inout vec3 color) {
    float edgeThresholdMin = 0.03125;
    float edgeThresholdMax = 0.0625;
    float subpixelQuality = 0.75;
    int iterations = 12;

    vec2 view = 1.0 / vec2(viewWidth, viewHeight);

    float lumaCenter = GetLuminance(color);
    float lumaDown  = GetLuminance(texelFetch(colortex3, texelCoord + ivec2( 0, -1), 0).rgb);
    float lumaUp    = GetLuminance(texelFetch(colortex3, texelCoord + ivec2( 0,  1), 0).rgb);
    float lumaLeft  = GetLuminance(texelFetch(colortex3, texelCoord + ivec2(-1,  0), 0).rgb);
    float lumaRight = GetLuminance(texelFetch(colortex3, texelCoord + ivec2( 1,  0), 0).rgb);

    float lumaMin = min(lumaCenter, min(min(lumaDown, lumaUp), min(lumaLeft, lumaRight)));
    float lumaMax = max(lumaCenter, max(max(lumaDown, lumaUp), max(lumaLeft, lumaRight)));

    float lumaRange = lumaMax - lumaMin;

    if (lumaRange > max(edgeThresholdMin, lumaMax * edgeThresholdMax)) {
        float lumaDownLeft  = GetLuminance(texelFetch(colortex3, texelCoord + ivec2(-1, -1), 0).rgb);
        float lumaUpRight   = GetLuminance(texelFetch(colortex3, texelCoord + ivec2( 1,  1), 0).rgb);
        float lumaUpLeft    = GetLuminance(texelFetch(colortex3, texelCoord + ivec2(-1,  1), 0).rgb);
        float lumaDownRight = GetLuminance(texelFetch(colortex3, texelCoord + ivec2( 1, -1), 0).rgb);

        float lumaDownUp    = lumaDown + lumaUp;
        float lumaLeftRight = lumaLeft + lumaRight;

        float lumaLeftCorners  = lumaDownLeft  + lumaUpLeft;
        float lumaDownCorners  = lumaDownLeft  + lumaDownRight;
        float lumaRightCorners = lumaDownRight + lumaUpRight;
        float lumaUpCorners    = lumaUpRight   + lumaUpLeft;

        float edgeHorizontal = abs(-2.0 * lumaLeft   + lumaLeftCorners ) +
                               abs(-2.0 * lumaCenter + lumaDownUp      ) * 2.0 +
                               abs(-2.0 * lumaRight  + lumaRightCorners);
        float edgeVertical   = abs(-2.0 * lumaUp     + lumaUpCorners   ) +
                               abs(-2.0 * lumaCenter + lumaLeftRight   ) * 2.0 +
                               abs(-2.0 * lumaDown   + lumaDownCorners );

        bool isHorizontal = (edgeHorizontal >= edgeVertical);

        float luma1 = isHorizontal ? lumaDown : lumaLeft;
        float luma2 = isHorizontal ? lumaUp : lumaRight;
        float gradient1 = luma1 - lumaCenter;
        float gradient2 = luma2 - lumaCenter;

        bool is1Steepest = abs(gradient1) >= abs(gradient2);
        float gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));

        float stepLength = isHorizontal ? view.y : view.x;

        float lumaLocalAverage = 0.0;

        if (is1Steepest) {
            stepLength = - stepLength;
            lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
        } else {
            lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
        }

        vec2 currentUv = texCoord;
        if (isHorizontal) {
            currentUv.y += stepLength * 0.5;
        } else {
            currentUv.x += stepLength * 0.5;
        }

        vec2 offset = isHorizontal ? vec2(view.x, 0.0) : vec2(0.0, view.y);

        vec2 uv1 = currentUv - offset;
        vec2 uv2 = currentUv + offset;
        float lumaEnd1 = GetLuminance(texture2D(colortex3, uv1).rgb);
        float lumaEnd2 = GetLuminance(texture2D(colortex3, uv2).rgb);
        lumaEnd1 -= lumaLocalAverage;
        lumaEnd2 -= lumaLocalAverage;

        bool reached1 = abs(lumaEnd1) >= gradientScaled;
        bool reached2 = abs(lumaEnd2) >= gradientScaled;
        bool reachedBoth = reached1 && reached2;

        if (!reached1) {
            uv1 -= offset;
        }
        if (!reached2) {
            uv2 += offset;
        }

        if (!reachedBoth) {
            for (int i = 2; i < iterations; i++) {
                if (!reached1) {
                    lumaEnd1 = GetLuminance(texture2D(colortex3, uv1).rgb);
                    lumaEnd1 = lumaEnd1 - lumaLocalAverage;
                }
                if (!reached2) {
                    lumaEnd2 = GetLuminance(texture2D(colortex3, uv2).rgb);
                    lumaEnd2 = lumaEnd2 - lumaLocalAverage;
                }

                reached1 = abs(lumaEnd1) >= gradientScaled;
                reached2 = abs(lumaEnd2) >= gradientScaled;
                reachedBoth = reached1 && reached2;

                if (!reached1) {
                    uv1 -= offset * quality[i];
                }
                if (!reached2) {
                    uv2 += offset * quality[i];
                }

                if (reachedBoth) break;
            }
        }

        float distance1 = isHorizontal ? (texCoord.x - uv1.x) : (texCoord.y - uv1.y);
        float distance2 = isHorizontal ? (uv2.x - texCoord.x) : (uv2.y - texCoord.y);

        bool isDirection1 = distance1 < distance2;
        float distanceFinal = min(distance1, distance2);

        float edgeThickness = (distance1 + distance2);

        float pixelOffset = - distanceFinal / edgeThickness + 0.5;

        bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;

        bool correctVariation = ((isDirection1 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;

        float finalOffset = correctVariation ? pixelOffset : 0.0;

        float lumaAverage = (1.0 / 12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
        float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
        float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
        float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * subpixelQuality;

        finalOffset = max(finalOffset, subPixelOffsetFinal);

        // Compute the final UV coordinates.
        vec2 finalUv = texCoord;
        if (isHorizontal) {
            finalUv.y += finalOffset * stepLength;
        } else {
            finalUv.x += finalOffset * stepLength;
        }

        #if defined TAA && defined FXAA_TAA_INTERACTION && TAA_MODE == 1
            // Less FXAA when moving
            vec3 newColor = texture2D(colortex3, finalUv).rgb;
            float skipFactor = min1(
                20.0 * length(cameraPosition - previousCameraPosition)
                #ifdef TAA_MOVEMENT_IMPROVEMENT_FILTER
                    + 0.25 // Catmull-Rom sampling gives us headroom to still do a bit of fxaa
                #endif
            );

            float z0 = texelFetch(depthtex0, texelCoord, 0).r;
            float z1 = texelFetch(depthtex1, texelCoord, 0).r;
            bool edge = false;
            for (int i = 0; i < 8; i++) {
                ivec2 texelCoordM = texelCoord + neighbourhoodOffsets[i];

                float z0Check = texelFetch(depthtex0, texelCoordM, 0).r;
                float z1Check = texelFetch(depthtex1, texelCoordM, 0).r;
                if (max(abs(GetLinearDepth(z0Check) - GetLinearDepth(z0)), abs(GetLinearDepth(z1Check) - GetLinearDepth(z1))) > 0.09) {
                    edge = true;
                    break;
                }
            }
            if (edge) skipFactor = 0.0;

            if (dot(texelFetch(colortex2, texelCoord, 0).rgb, vec3(1.0)) < 0.01) skipFactor = 0.0;
            
            color = mix(newColor, color, skipFactor);
        #else
            color = texture2D(colortex3, finalUv).rgb;
        #endif
    }
}

#endif // FXAA_FUNCTIONS_AVAILABLE

// ========================================================================
// TAA FUNCTIONS (Requires: texelCoord, GetLinearDepth, various buffers)
// ========================================================================

#ifdef TAA_FUNCTIONS_AVAILABLE

#if TAA_MODE == 1
    float blendMinimum = 0.3;
    float blendVariable = 0.2;
    float blendConstant = 0.7;

    float regularEdge = 20.0;
    float extraEdgeMult = 3.0;
#elif TAA_MODE == 2
    float blendMinimum = 0.6;
    float blendVariable = 0.2;
    float blendConstant = 0.7;

    float regularEdge = 5.0;
    float extraEdgeMult = 3.0;
#endif

#ifdef TAA_MOVEMENT_IMPROVEMENT_FILTER
    //Catmull-Rom sampling from Filmic SMAA presentation
    vec3 textureCatmullRom(sampler2D colortex, vec2 texcoord, vec2 view) {
        vec2 position = texcoord * view;
        vec2 centerPosition = floor(position - 0.5) + 0.5;
        vec2 f = position - centerPosition;
        vec2 f2 = f * f;
        vec2 f3 = f * f2;

        float c = 0.7;
        vec2 w0 =        -c  * f3 +  2.0 * c         * f2 - c * f;
        vec2 w1 =  (2.0 - c) * f3 - (3.0 - c)        * f2         + 1.0;
        vec2 w2 = -(2.0 - c) * f3 + (3.0 -  2.0 * c) * f2 + c * f;
        vec2 w3 =         c  * f3 -                c * f2;

        vec2 w12 = w1 + w2;
        vec2 tc12 = (centerPosition + w2 / w12) / view;

        vec2 tc0 = (centerPosition - 1.0) / view;
        vec2 tc3 = (centerPosition + 2.0) / view;
        vec4 color = vec4(texture2DLod(colortex, vec2(tc12.x, tc0.y ), 0).rgb, 1.0) * (w12.x * w0.y ) +
                    vec4(texture2DLod(colortex, vec2(tc0.x,  tc12.y), 0).rgb, 1.0) * (w0.x  * w12.y) +
                    vec4(texture2DLod(colortex, vec2(tc12.x, tc12.y), 0).rgb, 1.0) * (w12.x * w12.y) +
                    vec4(texture2DLod(colortex, vec2(tc3.x,  tc12.y), 0).rgb, 1.0) * (w3.x  * w12.y) +
                    vec4(texture2DLod(colortex, vec2(tc12.x, tc3.y ), 0).rgb, 1.0) * (w12.x * w3.y );
        return color.rgb / color.a;
    }
#endif

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec4 viewPos1) {
    vec4 pos = gbufferModelViewInverse * viewPos1;
    vec4 previousPosition = pos + vec4(cameraPosition - previousCameraPosition, 0.0);
    previousPosition = gbufferPreviousModelView * previousPosition;
    previousPosition = gbufferPreviousProjection * previousPosition;
    return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

vec3 ClipAABB(vec3 q, vec3 aabb_min, vec3 aabb_max){
    vec3 p_clip = 0.5 * (aabb_max + aabb_min);
    vec3 e_clip = 0.5 * (aabb_max - aabb_min) + 0.00000001;

    vec3 v_clip = q - vec3(p_clip);
    vec3 v_unit = v_clip.xyz / e_clip;
    vec3 a_unit = abs(v_unit);
    float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

    if (ma_unit > 1.0)
        return vec3(p_clip) + v_clip / ma_unit;
    else
        return q;
}

// neighbourhoodOffsets is now defined globally above

void NeighbourhoodClamping(vec3 color, inout vec3 tempColor, float z0, float z1, inout float edge) {
    vec3 minclr = color;
    vec3 maxclr = minclr;

    int cc = 2;
    ivec2 texelCoordM1 = clamp(texelCoord, ivec2(cc), ivec2(viewWidth, viewHeight) - cc); // Fixes screen edges
    for (int i = 0; i < 8; i++) {
        ivec2 texelCoordM2 = texelCoordM1 + neighbourhoodOffsets[i];

        float z0Check = texelFetch(depthtex0, texelCoordM2, 0).r;
        float z1Check = texelFetch(depthtex1, texelCoordM2, 0).r;
        if (max(abs(GetLinearDepth(z0Check) - GetLinearDepth(z0)), abs(GetLinearDepth(z1Check) - GetLinearDepth(z1))) > 0.09) {
            edge = regularEdge;

            if (int(texelFetch(colortex6, texelCoordM2, 0).g * 255.1) == 253) // Reduced Edge TAA
                edge *= extraEdgeMult;
        }

        vec3 clr = texelFetch(colortex3, texelCoordM2, 0).rgb;
        minclr = min(minclr, clr); maxclr = max(maxclr, clr);
    }

    tempColor = ClipAABB(tempColor, minclr, maxclr);
}

void DoTAA(inout vec3 color, inout vec3 temp, float z1) {
    int materialMask = int(texelFetch(colortex6, texelCoord, 0).g * 255.1);

    vec4 screenPos1 = vec4(texCoord, z1, 1.0);
    vec4 viewPos1 = gbufferProjectionInverse * (screenPos1 * 2.0 - 1.0);
    viewPos1 /= viewPos1.w;

    #ifdef ENTITY_TAA_NOISY_CLOUD_FIX
        float cloudLinearDepth =  texture2D(colortex5, texCoord).a;
        float lViewPos1 = length(viewPos1);

        if (pow2(cloudLinearDepth) * renderDistance < min(lViewPos1, renderDistance)) {
            // Material in question is obstructed by the cloud volume
            materialMask = 0;
        }
    #endif

    if (
        abs(materialMask - 149.5) < 50.0 // Entity Reflection Handling (see common.glsl for details)
        || materialMask == 254 // No SSAO, No TAA
    ) { 
        return;
    }

    /*if (materialMask == 254) { // No SSAO, No TAA
        #ifndef CUSTOM_PBR
            if (z1 <= 0.56) return; // The edge pixel trick doesn't look nice on hand
        #endif
        int i = 0;
        while (i < 4) {
            int mms = int(texelFetch(colortex6, texelCoord + neighbourhoodOffsets[i], 0).g * 255.1);
            if (mms != materialMask) break;
            i++;
        } // Checking edge-pixels prevents flickering
        if (i == 4) return;
    }*/

    float z0 = texelFetch(depthtex0, texelCoord, 0).r;

    vec2 prvCoord = texCoord;
    if (z1 > 0.56) prvCoord = Reprojection(viewPos1);

    #ifndef TAA_MOVEMENT_IMPROVEMENT_FILTER
        vec3 tempColor = texture2D(colortex2, prvCoord).rgb;
    #else
        vec3 tempColor = textureCatmullRom(colortex2, prvCoord, vec2(viewWidth, viewHeight));
    #endif

    if (tempColor == vec3(0.0) || any(isnan(tempColor))) { // Fixes the first frame and nans
        temp = color;
        return;
    }

    float edge = 0.0;
    NeighbourhoodClamping(color, tempColor, z0, z1, edge);

    if (materialMask == 253) // Reduced Edge TAA
        edge *= extraEdgeMult;

    #ifdef DISTANT_HORIZONS
        if (z0 == 1.0) {
            blendMinimum = 0.75;
            blendVariable = 0.05;
            blendConstant = 0.9;
            edge = 1.0;
        }
    #endif

    vec2 velocity = (texCoord - prvCoord.xy) * vec2(viewWidth, viewHeight);
    float blendFactor = float(prvCoord.x > 0.0 && prvCoord.x < 1.0 &&
                              prvCoord.y > 0.0 && prvCoord.y < 1.0);
    float velocityFactor = dot(velocity, velocity) * 10.0;
    blendFactor *= max(exp(-velocityFactor) * blendVariable + blendConstant - length(cameraPosition - previousCameraPosition) * edge, blendMinimum);

    color = mix(color, tempColor, blendFactor);
    temp = color;

    //if (edge > 0.05) color.rgb = vec3(1.0, 0.0, 1.0);
}

#endif // TAA_FUNCTIONS_AVAILABLE
