// Developed by EminGT
// Modified by Haider
#ifndef VOXELIZATION_GLSL_INCLUDED
#define VOXELIZATION_GLSL_INCLUDED

// ========================================================================
// LIGHT VOXELIZATION
// ========================================================================
#ifndef INCLUDE_VOXELIZATION
    #define INCLUDE_VOXELIZATION

    #if COLORED_LIGHTING_INTERNAL == 0
        const ivec3 voxelVolumeSize = ivec3(16, 8, 16); // Default size when colored lighting is disabled
    #elif COLORED_LIGHTING_INTERNAL <= 512
        const ivec3 voxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, COLORED_LIGHTING_INTERNAL * 0.5, COLORED_LIGHTING_INTERNAL);
    #else
        const ivec3 voxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 512 * 0.5, COLORED_LIGHTING_INTERNAL);
    #endif

    #if COLORED_LIGHTING_INTERNAL > 0
        float effectiveACTdistance = min(float(COLORED_LIGHTING_INTERNAL), shadowDistance * 2.0);
    #else
        float effectiveACTdistance = shadowDistance * 2.0; // Default distance when colored lighting is disabled
    #endif

    vec3 transform(mat4 m, vec3 pos) {
        return mat3(m) * pos + m[3].xyz;
    }

    vec3 SceneToVoxel(vec3 scenePos) {
        return scenePos + cameraPositionBestFract + (0.5 * vec3(voxelVolumeSize));
    }

    bool CheckInsideVoxelVolume(vec3 voxelPos) {
        #ifndef SHADOW
            voxelPos -= voxelVolumeSize / 2;
            voxelPos += sign(voxelPos) * 0.95;
            voxelPos += voxelVolumeSize / 2;
        #endif
        voxelPos /= vec3(voxelVolumeSize);
        return clamp01(voxelPos) == voxelPos;
    }

    uint GetVoxelVolume(ivec3 pos) {
        return texelFetch(voxel_sampler, pos, 0).x;
    }

    vec4 GetLightVolume(vec3 pos) {
        vec4 lightVolume;

        #if defined COMPOSITE1 || defined DEFERRED1
            #undef ACT_CORNER_LEAK_FIX
        #endif

        #ifdef ACT_CORNER_LEAK_FIX
            float minMult = 1.5;
            ivec3 posTX = ivec3(pos * voxelVolumeSize);

            ivec3[6] adjacentOffsets = ivec3[](
                ivec3( 1, 0, 0),
                ivec3(-1, 0, 0),
                ivec3( 0, 1, 0),
                ivec3( 0,-1, 0),
                ivec3( 0, 0, 1),
                ivec3( 0, 0,-1)
            );

            int adjacentCount = 0;
            for (int i = 0; i < 6; i++) {
                int voxel = int(GetVoxelVolume(posTX + adjacentOffsets[i]));
                if (voxel == 1 || voxel >= 200) adjacentCount++;
            }

            if (int(GetVoxelVolume(posTX)) >= 200) adjacentCount = 6;
        #endif

        if (int(framemod2) == 0) {
            lightVolume = texture(floodfill_sampler_copy, pos);
            #ifdef ACT_CORNER_LEAK_FIX
                if (adjacentCount >= 3) {
                    vec4 lightVolumeTX = texelFetch(floodfill_sampler_copy, posTX, 0);
                    if (dot(lightVolumeTX, lightVolumeTX) > 0.01)
                    lightVolume.rgb = min(lightVolume.rgb, lightVolumeTX.rgb * minMult);
                }
            #endif
        } else {
            lightVolume = texture(floodfill_sampler, pos);
            #ifdef ACT_CORNER_LEAK_FIX
                if (adjacentCount >= 3) {
                    vec4 lightVolumeTX = texelFetch(floodfill_sampler, posTX, 0);
                    if (dot(lightVolumeTX, lightVolumeTX) > 0.01)
                    lightVolume.rgb = min(lightVolume.rgb, lightVolumeTX.rgb * minMult);
                }
            #endif
        }

        return lightVolume;
    }

    int GetVoxelIDs(int mat) {
        /* These return IDs must be consistent across the following files:
        "lightVoxelization.glsl", "blocklightColors.glsl", "item.properties"
        The order of if-checks or block IDs don't matter. The returning IDs matter. */

        #define ALWAYS_DO_IPBR_LIGHTS

        #if defined IPBR || defined ALWAYS_DO_IPBR_LIGHTS
            #define DO_IPBR_LIGHTS
        #endif

        if (mat < 10604) {
            if (mat < 10396) {
                if (mat < 10300) {
                    if (mat < 10228) {
                        if (mat < 10076) {
                            if (mat == 10056) return  14; // Lava Cauldron
                            if (mat == 10068) return  13; // Lava
                            if (mat == 10072) return   5; // Fire
                        } else {
                            if (mat == 10076) return  27; // Soul Fire
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10216) return  62; // Crimson Stem, Crimson Hyphae
                            if (mat == 10224) return  63; // Warped Stem, Warped Hyphae
                            #endif
                        }
                    } else {
                        if (mat < 10276) {
                            if (mat == 10228) return 255; // Bedrock
                            #if defined GLOWING_ORE_ANCIENTDEBRIS && defined DO_IPBR_LIGHTS
                            if (mat == 10252) return  52; // Ancient Debris
                            #endif
                            #if defined GLOWING_ORE_IRON && defined DO_IPBR_LIGHTS
                            if (mat == 10272) return  43; // Iron Ore
                            #endif
                        } else {
                            #if defined GLOWING_ORE_IRON && defined DO_IPBR_LIGHTS
                            if (mat == 10276) return  43; // Deepslate Iron Ore
                            #endif
                            #if defined GLOWING_ORE_COPPER && defined DO_IPBR_LIGHTS
                            if (mat == 10284) return  45; // Copper Ore
                            if (mat == 10288) return  45; // Deepslate Copper Ore
                            #endif
                        }
                    }
                } else {
                    if (mat < 10340) {
                        if (mat < 10320) {
                            #if defined GLOWING_ORE_GOLD && defined DO_IPBR_LIGHTS
                            if (mat == 10300) return  44; // Gold Ore
                            if (mat == 10304) return  44; // Deepslate Gold Ore
                            #endif
                            #if defined GLOWING_ORE_NETHERGOLD && defined DO_IPBR_LIGHTS
                            if (mat == 10308) return  50; // Nether Gold Ore
                            #endif
                        } else {
                            #if defined GLOWING_ORE_DIAMOND && defined DO_IPBR_LIGHTS
                            if (mat == 10320) return  48; // Diamond Ore
                            if (mat == 10324) return  48; // Deepslate Diamond Ore
                            #endif
                            if (mat == 10332) return  36; // Amethyst Cluster, Amethyst Buds
                        }
                    } else {
                        if (mat < 10356) {
                            #if defined GLOWING_ORE_EMERALD && defined DO_IPBR_LIGHTS
                            if (mat == 10340) return  47; // Emerald Ore
                            if (mat == 10344) return  47; // Deepslate Emerald Ore
                            #endif
                            #if defined EMISSIVE_LAPIS_BLOCK && defined DO_IPBR_LIGHTS
                            if (mat == 10352) return  42; // Lapis Block
                            #endif
                        } else {
                            #if defined GLOWING_ORE_LAPIS && defined DO_IPBR_LIGHTS
                            if (mat == 10356) return  46; // Lapis Ore
                            if (mat == 10360) return  46; // Deepslate Lapis Ore
                            #endif
                            #if defined GLOWING_ORE_NETHERQUARTZ && defined DO_IPBR_LIGHTS
                            if (mat == 10368) return  49; // Nether Quartz Ore
                            #endif
                        }
                    }
                }
            } else {
                if (mat < 10516) {
                    if (mat < 10476) {
                        if (mat < 10448) {
                            if (mat == 10396) return  11; // Jack o'Lantern
                            if (mat == 10404) return   6; // Sea Pickle:Waterlogged
                            if (mat == 10412) return  10; // Glowstone
                        } else {
                            if (mat == 10448) return  18; // Sea Lantern
                            if (mat == 10452) return  37; // Magma Block
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10456) return  60; // Command Block
                            #endif
                        }
                    } else {
                        if (mat < 10500) {
                            if (mat == 10476) return  26; // Crying Obsidian
                            #if defined GLOWING_ORE_GILDEDBLACKSTONE && defined DO_IPBR_LIGHTS
                            if (mat == 10484) return  51; // Gilded Blackstone
                            #endif
                            if (mat == 10496) return   2; // Torch
                        } else {
                            if (mat == 10500) return   3; // End Rod
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10508) return  39; // Chorus Flower:Alive
                            if (mat == 10512) return  39; // Chorus Flower:Dead
                            #endif
                        }
                    }
                } else {
                    if (mat < 10564) {
                        if (mat < 10548) {
                            if (mat == 10516) return  21; // Furnace:Lit
                            if (mat == 10528) return  28; // Soul Torch
                            if (mat == 10544) return  34; // Glow Lichen
                        } else {
                            if (mat == 10548) return  33; // Enchanting Table
                            if (mat == 10556) return  58; // End Portal Frame:Active
                            if (mat == 10560) return  12; // Lantern
                        }
                    } else {
                        if (mat < 10580) {
                            if (mat == 10564) return  29; // Soul Lantern
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10572) return  38; // Dragon Egg
                            #endif
                            if (mat == 10576) return  22; // Smoker:Lit
                        } else {
                            if (mat == 10580) return  23; // Blast Furnace:Lit
                            if (mat == 10592) return  17; // Respawn Anchor:Lit
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10596) return  66; // Redstone Wire:Lit
                            #endif
                        }
                    }
                }
            }
        } else {
            if (mat < 10788) {
                if (mat < 10656) {
                    if (mat < 10632) {
                        if (mat < 10616) {
                            if (mat == 10604) return  35; // Redstone Torch
                            #if defined EMISSIVE_REDSTONE_BLOCK && defined DO_IPBR_LIGHTS
                            if (mat == 10608) return  41; // Redstone Block
                            #endif
                            #if defined GLOWING_ORE_REDSTONE && defined DO_IPBR_LIGHTS
                            if (mat == 10612) return  32; // Redstone Ore:Unlit
                            #endif
                        } else {
                            if (mat == 10616) return  31; // Redstone Ore:Lit
                            #if defined GLOWING_ORE_REDSTONE && defined DO_IPBR_LIGHTS
                            if (mat == 10620) return  32; // Deepslate Redstone Ore:Unlit
                            #endif
                            if (mat == 10624) return  31; // Deepslate Redstone Ore:Lit
                        }
                    } else {
                        if (mat < 10646) {
                            if (mat == 10632) return  20; // Cave Vines:With Glow Berries
                            if (mat == 10640) return  16; // Redstone Lamp:Lit
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10644) return  67; // Repeater:Lit, Comparator:Lit
                            #endif
                        } else {
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10646) return  66; // Comparator:Unlit:Subtract
                            #endif
                            if (mat == 10648) return  19; // Shroomlight
                            if (mat == 10652) return  15; // Campfire:Lit
                        }
                    }
                } else {
                    if (mat < 10704) {
                        if (mat < 10688) {
                            if (mat == 10656) return  30; // Soul Campfire:Lit
                            if (mat == 10680) return   7; // Ochre Froglight
                            if (mat == 10684) return   8; // Verdant Froglight
                        } else {
                            if (mat == 10688) return   9; // Pearlescent Froglight
                            if (mat == 10696) return  57; // Sculk, Sculk Catalyst
                            if (mat == 10698) return  57; // Sculk Vein, Sculk Sensor:Unlit
                            if (mat == 10700) return  57; // Sculk Shrieker
                        }
                    } else {
                        if (mat < 10776) {
                            if (mat == 10704) return  57; // Sculk Sensor:Lit
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10708) return  53; // Spawner
                            if (mat == 10736) return  64; // Structure Block, Jigsaw Block, Test Block, Test Instance Block
                            #endif
                        } else {
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10776) return  61; // Warped Fungus, Crimson Fungus
                            if (mat == 10780) return  61; // Potted Warped Fungus, Potted Crimson Fungus
                            #endif
                            if (mat == 10784) return  36; // Calibrated Sculk Sensor:Unlit
                        }
                    }
                }
            } else {
                if (mat < 10980) {
                    if (mat < 10876) {
                        if (mat < 10856) {
                            if (mat == 10788) return  36; // Calibrated Sculk Sensor:Lit
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10836) return  40; // Brewing Stand
                            #endif
                            if (mat == 10852) return  55; // Copper Bulb:BrighterOnes:Lit
                        } else {
                            if (mat == 10856) return  56; // Copper Bulb:DimmerOnes:Lit
                            if (mat == 10868) return  54; // Trial Spawner:NotOminous:Active, Vault:NotOminous:Active
                            if (mat == 10872) return  68; // Vault:Inactive
                        }
                    } else {
                        if (mat < 10948) {
                            if (mat == 10876) return  69; // Trial Spawner:Ominous:Active, Vault:Ominous:Active
                            #ifdef DO_IPBR_LIGHTS
                            if (mat == 10884) return  65; // Weeping Vines Plant
                            #endif
                            #ifndef COLORED_CANDLE_LIGHT
                            if (mat >= 10900 && mat <= 10922) return 24; // Standard Candles:Lit
                            #else
                            if (mat == 10900) return  24; // Standard Candles:Lit
                            if (mat == 10902) return  70; // Red Candles:Lit
                            if (mat == 10904) return  71; // Orange Candles:Lit
                            if (mat == 10906) return  72; // Yellow Candles:Lit
                            if (mat == 10908) return  73; // Lime Candles:Lit
                            if (mat == 10910) return  74; // Green Candles:Lit
                            if (mat == 10912) return  75; // Cyan Candles:Lit
                            if (mat == 10914) return  76; // Light Blue Candles:Lit
                            if (mat == 10916) return  77; // Blue Candles:Lit
                            if (mat == 10918) return  78; // Purple Candles:Lit
                            if (mat == 10920) return  79; // Magenta Candles:Lit
                            if (mat == 10922) return  80; // Pink Candles:Lit
                            #endif
                        } else {
                            if (mat == 10948) return  82; // Creaking Heart: Active
                            if (mat == 10972) return  83; // Firefly Bush
                            if (mat == 10976) return  81; // Open Eyeblossom
                        }
                    }
                } else {
                    if (mat < 31000) {
                        if (mat < 30012) {
                            if (mat == 10980) return  81; // Potted Open Eyeblossom
                            if (abs(mat - 10986) <= 2) return 84; // Copper Torch, Copper Lantern
                            if (mat == 30008) return 254; // Tinted Glass
                        } else {
                            if (mat == 30012) return 213; // Slime Block
                            if (mat == 30016) return 201; // Honey Block
                            if (mat == 30020) return  25; // Nether Portal
                        }
                    } else {
                        if (mat < 32008) {
                            if (mat >= 31000 && mat < 32000) return 200 + (mat - 31000) / 2; // Stained Glass+
                            if (mat == 32004) return 216; // Ice
                        } else {
                            if (mat == 32008) return 217; // Glass
                            if (mat == 32012) return 218; // Glass Pane
                            if (mat == 32016) return   4; // Beacon
                        }
                    }
                }
            }
        }

        return 1; // Standard Block
    }

    #if defined SHADOW && defined VERTEX_SHADER
        void UpdateVoxelMap(int mat) {
            if (mat == 32000 // Water
                || mat < 30000 && mat % 2 == 1 // Non-solid terrain
                || mat < 10000 // Block entities or unknown blocks that we treat as non-solid
            ) return;

            vec3 modelPos = gl_Vertex.xyz + at_midBlock.xyz / 64.0;
            vec3 viewPos = transform(gl_ModelViewMatrix, modelPos);
            vec3 scenePos = transform(shadowModelViewInverse, viewPos);
            vec3 voxelPos = SceneToVoxel(scenePos);

            //#define OPTIMIZATION_ACT_HALF_RATE_VOXELS
            #ifdef OPTIMIZATION_ACT_HALF_RATE_VOXELS
                if (int(framemod2) == 0) {
                    if (scenePos.z > 0.0) return;
                } else {
                    if (scenePos.z < 0.0) return;
                }
            #endif

            bool isEligible = any(equal(ivec4(renderStage), ivec4(
                MC_RENDER_STAGE_TERRAIN_SOLID,
                MC_RENDER_STAGE_TERRAIN_TRANSLUCENT,
                MC_RENDER_STAGE_TERRAIN_CUTOUT,
                MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED)));

            if (isEligible && CheckInsideVoxelVolume(voxelPos)) {
                int voxelData = GetVoxelIDs(mat);
                
                imageStore(voxel_img, ivec3(voxelPos), uvec4(voxelData, 0u, 0u, 0u));
            }
        }
    #endif
#endif

// ========================================================================
// PUDDLE VOXELIZATION
// ========================================================================
const ivec3 puddle_voxelVolumeSize = ivec3(128);

vec3 TransformMat(mat4 m, vec3 pos) {
    return mat3(m) * pos + m[3].xyz;
}

vec3 SceneToPuddleVoxel(vec3 scenePos) {
    return scenePos + fract(cameraPosition) + (0.5 * vec3(puddle_voxelVolumeSize));
}

bool CheckInsidePuddleVoxelVolume(vec3 voxelPos) {
    #ifndef SHADOW
        voxelPos -= puddle_voxelVolumeSize / 2;
        voxelPos += sign(voxelPos) * 0.95;
        voxelPos += puddle_voxelVolumeSize / 2;
    #endif
    voxelPos /= vec3(puddle_voxelVolumeSize);
    return clamp01(voxelPos) == voxelPos;
}

#if defined SHADOW && defined VERTEX_SHADER
    void UpdatePuddleVoxelMap(int mat) {
        if (renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) return;
        if (mat == 32000) return; // Water

        vec3 model_pos = gl_Vertex.xyz + at_midBlock.xyz / 64.0;
        vec3 view_pos  = TransformMat(gl_ModelViewMatrix, model_pos);
        vec3 scenePos = TransformMat(shadowModelViewInverse, view_pos);
        vec3 voxelPos = SceneToPuddleVoxel(scenePos);

        if (CheckInsidePuddleVoxelVolume(voxelPos))
            if (scenePos.y >= -3.5)
            imageStore(puddle_img, ivec2(voxelPos.xz), uvec4(10u, 0u, 0u, 0u));
    }
#endif

// ========================================================================
// REFLECTION VOXELIZATION DATA
// ========================================================================
#extension GL_ARB_shader_storage_buffer_object : enable

// Structs
struct vec6 {
    vec3 a;
    vec3 b;
};

struct faceData {
    vec3 textureBounds;
    vec3 glColor;
    vec2 lightmap;
};

struct blockData {
    vec4[6] packedFaceData;
};

#if defined SHADOW && defined VERTEX_SHADER || defined CLEAR_SSBO
layout(std430, binding = 0) buffer blockDataSSBO {
    blockData data[];
};  
#else
layout(std430, binding = 0) readonly buffer blockDataSSBO {
    blockData data[];
};  
#endif

int getSSBOIndex(ivec3 voxelPos) {
    return voxelPos.x + voxelPos.y * sceneVoxelVolumeSize.x + voxelPos.z * sceneVoxelVolumeSize.x * sceneVoxelVolumeSize.y;
}

int getFaceIndex(vec3 normal) {
    return int(2.0 * abs(normal.y) + 4.0 * abs(normal.z) + (normal.x + normal.y + normal.z) * 0.5 + 0.5);
}

// the packing / unpacking assumes normalized floats
float pack2x16(float a, float b) {
    a = clamp(a, 0.0, 0.99);
    b = clamp(b, 0.0, 0.99);
    uint low = uint(a * 65535.0);
    uint high = uint(b * 65535.0);
    return (low | (high << 16)) / 4294967295.0;
}

vec3 pack2x16(vec3 a, vec3 b) {
    a = clamp(a, 0.0, 0.99);
    b = clamp(b, 0.0, 0.99);
    uvec3 low = uvec3(a * 65535.0);
    uvec3 high = uvec3(b * 65535.0);
    return (low | (high << 16)) / 4294967295.0;
}

vec2 unpack2x16(float packed) {
    uint packedInt = uint(packed * 4294967295.0);
    uint low = packedInt & 65535u;
    uint high = (packedInt >> 16) & 65535u;
    return vec2(float(low) / 65535.0, float(high) / 65535.0);
}

vec6 unpack2x16(vec3 packed) {
    vec6 result;
    uvec3 packedInt = uvec3(packed * 4294967295.0);
    uvec3 low = packedInt & 65535u;
    uvec3 high = (packedInt >> 16) & 65535u;
    result.a = vec3(low) / 65535.0;
    result.b = vec3(high) / 65535.0;
    return result;
}

faceData unpackFaceData(vec4 packed) {
    faceData result;
    vec6 unpacked = unpack2x16(packed.rgb);
    result.textureBounds = unpacked.a;
    result.glColor = unpacked.b;
    result.lightmap = unpack2x16(packed.a);
    return result;
}

vec4 packFaceData(faceData face) {
    vec4 result;
    result.rgb = pack2x16(face.textureBounds, face.glColor);
    result.a = pack2x16(face.lightmap.x, face.lightmap.y);
    return result;
}

// ========================================================================
// REFLECTION VOXELIZATION
// ========================================================================
#if COLORED_LIGHTING == 0
    const ivec3 sceneVoxelVolumeSize = ivec3(16, 64, 16); // Default size when colored lighting is disabled
#elif COLORED_LIGHTING < 512
    const ivec3 sceneVoxelVolumeSize = ivec3(COLORED_LIGHTING_INTERNAL, 64, COLORED_LIGHTING_INTERNAL);
#else
    const ivec3 sceneVoxelVolumeSize = ivec3(512, 64, 512);
#endif

vec3 playerToSceneVoxel(vec3 playerPos) {
    return playerPos + cameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

vec3 playerToPreviousSceneVoxel(vec3 previousPlayerPos) {
    return previousPlayerPos + previousCameraPositionBestFract + 0.5 * vec3(sceneVoxelVolumeSize);
}

bool CheckInsideSceneVoxelVolume(vec3 voxelPos) {
    #ifndef SHADOW
        voxelPos -= 0.5 * sceneVoxelVolumeSize;
        voxelPos += sign(voxelPos) * 0.95;
        voxelPos += 0.5 * sceneVoxelVolumeSize;
    #endif
    voxelPos /= vec3(sceneVoxelVolumeSize);
    return clamp01(voxelPos) == voxelPos;
}

#if defined SHADOW && defined VERTEX_SHADER
    void UpdateSceneVoxelMap(int mat, vec3 normal, vec3 position) {
        ivec3 eligibleStages = ivec3(
            MC_RENDER_STAGE_TERRAIN_SOLID,
            MC_RENDER_STAGE_TERRAIN_CUTOUT,
            MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED
        );

        if (!any(equal(ivec3(renderStage), eligibleStages))) return;

        vec3 viewPos  = mat3(gl_ModelViewMatrix) * (gl_Vertex.xyz + at_midBlock.xyz / 64.0) + gl_ModelViewMatrix[3].xyz;
        vec3 scenePos = mat3(shadowModelViewInverse) * viewPos + shadowModelViewInverse[3].xyz;
        vec3 voxelPos = playerToSceneVoxel(scenePos);

        if (CheckInsideSceneVoxelVolume(voxelPos)) {
            bool doSolidBlockCheck = true;
            bool storeToAllFaces = false;
            bool storeToAllFacesExceptTop = false;
            uint matM = mat > 10 ? uint(mat) : 1u;
            vec2 textureRad = abs(texCoord - mc_midTexCoord.xy);
            vec2 origin = mc_midTexCoord.xy - textureRad;

            if (mat == 10132) { // Grass Block Regular
                if (texture2D(tex, mc_midTexCoord.xy).a < 0.5) return; // Grass Block Side Overlay
                doSolidBlockCheck = false;
                storeToAllFacesExceptTop = true;
            } else if (mat == 10004) { // Wheat
                doSolidBlockCheck = false;
                storeToAllFaces = true;
            } else if (mat == 10040) { // Glass
                doSolidBlockCheck = false;
            }

            if (doSolidBlockCheck) {
                ivec3 blockPos = ivec3(floor(voxelPos));
                int index = getSSBOIndex(blockPos);
                if (index >= 0 && index < data.length() && data[index].packedFaceData[0].x > 0.0) return;
            }

            ivec3 blockPos = ivec3(floor(voxelPos));
            int index = getSSBOIndex(blockPos);
            
            if (index >= 0 && index < data.length()) {
                faceData face;
                face.textureBounds = vec3(origin, textureRad.x + textureRad.y);
                face.glColor = glColor.rgb;
                face.lightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
                
                int faceIndex = getFaceIndex(normal);
                
                if (storeToAllFaces) {
                    for (int i = 0; i < 6; i++) {
                        data[index].packedFaceData[i] = packFaceData(face);
                    }
                } else if (storeToAllFacesExceptTop) {
                    for (int i = 0; i < 6; i++) {
                        if (i != 2) { // Skip top face
                            data[index].packedFaceData[i] = packFaceData(face);
                        }
                    }
                } else {
                    data[index].packedFaceData[faceIndex] = packFaceData(face);
                }
            }
        }
    }
#endif

// Reflection Voxel Data Section

#ifdef REFLECTION_VOXEL_DATA
    layout(std430) restrict buffer voxelReflectionDataSSBO {
        uint voxelReflectionData[];
    };

    #define REFLECTION_VOXEL_SIZE 64

    ivec3 DecodeVoxelPos(uint voxelDataCompressed) {
        int x = int((voxelDataCompressed >>  0u) & 255u) - 127;
        int y = int((voxelDataCompressed >>  8u) & 255u) - 127;
        int z = int((voxelDataCompressed >> 16u) & 255u) - 127;

        return ivec3(x, y, z);
    }

    vec3 DecodeVoxelNormal(uint voxelDataCompressed) {
        uint encodedNormal = (voxelDataCompressed >> 24u) & 255u;

        vec3 normal;
        switch (encodedNormal) {
            case 1u:  normal = vec3( 1, 0, 0); break;
            case 2u:  normal = vec3(-1, 0, 0); break;
            case 3u:  normal = vec3(0,  1, 0); break;
            case 4u:  normal = vec3(0, -1, 0); break;
            case 5u:  normal = vec3(0, 0,  1); break;
            case 6u:  normal = vec3(0, 0, -1); break;
            default:  normal = vec3(0, 1, 0); break;
        }

        return normal;
    }

    uint EncodeVoxelData(ivec3 relativePos, vec3 normal) {
        uint encodedPos = (uint(relativePos.x + 127) & 255u) << 0u
                        | (uint(relativePos.y + 127) & 255u) << 8u
                        | (uint(relativePos.z + 127) & 255u) << 16u;

        uint encodedNormal = 0u;
        vec3 absNormal = abs(normal);
        if (absNormal.x > absNormal.y && absNormal.x > absNormal.z) {
            encodedNormal = normal.x > 0.0 ? 1u : 2u;
        } else if (absNormal.y > absNormal.z) {
            encodedNormal = normal.y > 0.0 ? 3u : 4u;
        } else {
            encodedNormal = normal.z > 0.0 ? 5u : 6u;
        }

        return encodedPos | (encodedNormal << 24u);
    }
#endif

#endif // VOXELIZATION_GLSL_INCLUDED