#version 120

uniform sampler2DShadow shadow_tex;

uniform bool shadows_enabled;
uniform int sun_atlas_size;

varying vec4 lightSpacePos[4];

const float DEPTH_BIAS = 2.0;
const float BAND_SIZE = 0.1;
const vec2 BAND_BOTTOM_LEFT = vec2(BAND_SIZE);
const vec2 BAND_TOP_RIGHT   = vec2(1.0 - BAND_SIZE);

// Ideally these should be passed as an uniform, but we don't support uniform
// arrays yet
const vec2 uv_shifts[4] = vec2[4](
    vec2(0.0, 0.0), vec2(0.5, 0.0),
    vec2(0.0, 0.5), vec2(0.5, 0.5));
const vec2 uv_factor = vec2(0.5, 0.5);


float sampleOffset(vec4 pos, vec2 offset, vec2 invTexelSize)
{
    return shadow2DProj(
        shadow_tex, vec4(
            pos.xy + offset * invTexelSize * pos.w,
            pos.z - DEPTH_BIAS * invTexelSize.x,
            pos.w)).r;
}

// OptimizedPCF from https://github.com/TheRealMJP/Shadows
// Original by Ignacio Castaño for The Witness
// Released under The MIT License
float sampleOptimizedPCF(vec4 pos)
{
    vec2 invTexelSize = vec2(1.0 / float(sun_atlas_size));

    vec2 uv = pos.xy * sun_atlas_size;
    vec2 base_uv = floor(uv + 0.5);
    float s = (uv.x + 0.5 - base_uv.x);
    float t = (uv.y + 0.5 - base_uv.y);
    base_uv -= vec2(0.5);
    base_uv *= invTexelSize;
    pos.xy = base_uv.xy;

    float sum = 0.0;

    float uw0 = (4.0 - 3.0 * s);
    float uw1 = 7.0;
    float uw2 = (1.0 + 3.0 * s);

    float u0 = (3.0 - 2.0 * s) / uw0 - 2.0;
    float u1 = (3.0 + s) / uw1;
    float u2 = s / uw2 + 2.0;

    float vw0 = (4.0 - 3.0 * t);
    float vw1 = 7.0;
    float vw2 = (1.0 + 3.0 * t);

    float v0 = (3.0 - 2.0 * t) / vw0 - 2.0;
    float v1 = (3.0 + t) / vw1;
    float v2 = t / vw2 + 2.0;

    sum += uw0 * vw0 * sampleOffset(pos, vec2(u0, v0), invTexelSize);
    sum += uw1 * vw0 * sampleOffset(pos, vec2(u1, v0), invTexelSize);
    sum += uw2 * vw0 * sampleOffset(pos, vec2(u2, v0), invTexelSize);

    sum += uw0 * vw1 * sampleOffset(pos, vec2(u0, v1), invTexelSize);
    sum += uw1 * vw1 * sampleOffset(pos, vec2(u1, v1), invTexelSize);
    sum += uw2 * vw1 * sampleOffset(pos, vec2(u2, v1), invTexelSize);

    sum += uw0 * vw2 * sampleOffset(pos, vec2(u0, v2), invTexelSize);
    sum += uw1 * vw2 * sampleOffset(pos, vec2(u1, v2), invTexelSize);
    sum += uw2 * vw2 * sampleOffset(pos, vec2(u2, v2), invTexelSize);

    return sum / 144.0;
}

float sampleCascade(int n)
{
    vec4 pos = lightSpacePos[n];
    pos.xy *= uv_factor;
    pos.xy += uv_shifts[n];
    return sampleOptimizedPCF(pos);
}

float sampleAndBlendBand(int n1, int n2)
{
    vec2 s = smoothstep(vec2(0.0), BAND_BOTTOM_LEFT, lightSpacePos[n1].xy)
        - smoothstep(BAND_TOP_RIGHT, vec2(1.0), lightSpacePos[n1].xy);
    float blend = 1.0 - s.x * s.y;
    return mix(sampleCascade(n1), sampleCascade(n2), blend);
}

bool checkWithinBounds(vec2 coords, vec2 bottomLeft, vec2 topRight)
{
    vec2 r = step(bottomLeft, coords) - step(topRight, coords);
    return bool(r.x * r.y);
}

bool isInsideCascade(int n)
{
    return checkWithinBounds(lightSpacePos[n].xy, vec2(0.0), vec2(1.0)) &&
        ((lightSpacePos[n].z / lightSpacePos[n].w) <= 1.0);
}

bool isInsideBand(int n)
{
    return !checkWithinBounds(lightSpacePos[n].xy, BAND_BOTTOM_LEFT, BAND_TOP_RIGHT);
}

// Get a value between 0.0 and 1.0 where 0.0 means shadowed and 1.0 means lit
float getShadowing()
{
    float shadow = 1.0;
    if (shadows_enabled) {
        for (int i = 0; i < 4; ++i) {
            // Map-based cascade selection
            // We test if we are inside the cascade bounds to find the tightest
            // map that contains the fragment.
            if (isInsideCascade(i)) {
                if (isInsideBand(i) && ((i+1) < 4)) {
                    // Blend between cascades if the fragment is near the
                    // next cascade to avoid abrupt transitions.
                    shadow = clamp(sampleAndBlendBand(i, i+1), 0.0, 1.0);
                } else {
                    // We are far away from the borders of the cascade, so
                    // we skip the blending to avoid the performance cost
                    // of sampling the shadow map twice.
                    shadow = clamp(sampleCascade(i), 0.0, 1.0);
                }
                break;
            }
        }
    }
    return shadow;
}
