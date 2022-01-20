#version 120

uniform bool shadows_enabled;

uniform mat4 fg_LightMatrix_csm0;
uniform mat4 fg_LightMatrix_csm1;
uniform mat4 fg_LightMatrix_csm2;
uniform mat4 fg_LightMatrix_csm3;

varying vec4 lightSpacePos[4];

const float NORMAL_OFFSET_SCALES[4] = float[4](0.0, 0.1, 0.3, 1.0);

void setupShadows(vec4 eyeSpacePos)
{
    if (!shadows_enabled)
        return;

    vec3 normal = gl_NormalMatrix * gl_Normal;

    vec3 toLight = normalize(gl_LightSource[0].position.xyz);
    float costheta = dot(normal, toLight);
    float slopeScale = clamp(1.0 - costheta, 0.0, 1.0);

    vec4 offsetPos[4];
    for (int i = 0; i < 4; i++) {
        float normalOffset = NORMAL_OFFSET_SCALES[i] * slopeScale;
        offsetPos[i] = eyeSpacePos + vec4(normal * normalOffset, 0.0);
    }

    vec4 offsetPosLightSpace[4];
    offsetPosLightSpace[0] = fg_LightMatrix_csm0 * offsetPos[0];
    offsetPosLightSpace[1] = fg_LightMatrix_csm1 * offsetPos[1];
    offsetPosLightSpace[2] = fg_LightMatrix_csm2 * offsetPos[2];
    offsetPosLightSpace[3] = fg_LightMatrix_csm3 * offsetPos[3];

    lightSpacePos[0] = fg_LightMatrix_csm0 * eyeSpacePos;
    lightSpacePos[1] = fg_LightMatrix_csm1 * eyeSpacePos;
    lightSpacePos[2] = fg_LightMatrix_csm2 * eyeSpacePos;
    lightSpacePos[3] = fg_LightMatrix_csm3 * eyeSpacePos;

    // Offset only in UV space
    for (int i = 0; i < 4; i++)
        lightSpacePos[i].xy = offsetPosLightSpace[i].xy;
}
