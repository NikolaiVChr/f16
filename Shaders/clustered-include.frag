#version 120

uniform sampler3D fg_Clusters;
uniform sampler2D fg_ClusteredIndices;
uniform sampler2D fg_ClusteredPointLights;
uniform sampler2D fg_ClusteredSpotLights;

uniform int fg_ClusteredMaxPointLights;
uniform int fg_ClusteredMaxSpotLights;
uniform int fg_ClusteredMaxLightIndices;
uniform int fg_ClusteredTileSize;
uniform int fg_ClusteredDepthSlices;
uniform float fg_ClusteredSliceScale;
uniform float fg_ClusteredSliceBias;
uniform int fg_ClusteredHorizontalTiles;
uniform int fg_ClusteredVerticalTiles;

const bool DEBUG = false;

struct PointLight {
    vec4 position;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    vec4 attenuation;
};

struct SpotLight {
    vec4 position;
    vec4 direction;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    vec4 attenuation;
    float cos_cutoff;
    float exponent;
};


PointLight unpackPointLight(int index)
{
    PointLight light;
    float v = (float(index) + 0.5) / float(fg_ClusteredMaxPointLights);
    light.position    = texture2D(fg_ClusteredPointLights, vec2(0.1, v));
    light.ambient     = texture2D(fg_ClusteredPointLights, vec2(0.3, v));
    light.diffuse     = texture2D(fg_ClusteredPointLights, vec2(0.5, v));
    light.specular    = texture2D(fg_ClusteredPointLights, vec2(0.7, v));
    light.attenuation = texture2D(fg_ClusteredPointLights, vec2(0.9, v));
    return light;
}

SpotLight unpackSpotLight(int index)
{
    SpotLight light;
    float v = (float(index) + 0.5) / float(fg_ClusteredMaxSpotLights);
    light.position    = texture2D(fg_ClusteredSpotLights, vec2(0.0714, v));
    light.direction   = texture2D(fg_ClusteredSpotLights, vec2(0.2143, v));
    light.ambient     = texture2D(fg_ClusteredSpotLights, vec2(0.3571, v));
    light.diffuse     = texture2D(fg_ClusteredSpotLights, vec2(0.5,    v));
    light.specular    = texture2D(fg_ClusteredSpotLights, vec2(0.6429, v));
    light.attenuation = texture2D(fg_ClusteredSpotLights, vec2(0.7857, v));
    vec2 remainder    = texture2D(fg_ClusteredSpotLights, vec2(0.9286, v)).xy;
    light.cos_cutoff  = remainder.x;
    light.exponent    = remainder.y;
    return light;
}

int getIndex(int counter)
{
    vec2 coords = vec2(mod(float(counter), float(fg_ClusteredMaxLightIndices)) + 0.5,
                       float(counter / fg_ClusteredMaxLightIndices) + 0.5);
    // Normalize
    coords /= vec2(fg_ClusteredMaxLightIndices);
    return int(texture2D(fg_ClusteredIndices, coords).r);
}

// @param p Fragment position in view space.
// @param n Fragment normal in view space.
// @param texel The diffuse (or albedo) color of the surface. It's usually just
//              the one on texture unit 0.
// @return The total color contribution of every light affecting the fragment.
//         This result should be added to the fragment color before applying
//         any haze, fog or post-processing.
vec3 getClusteredLightsContribution(vec3 p, vec3 n, vec3 texel)
{
    int slice = int(max(log2(-p.z) * fg_ClusteredSliceScale
                        + fg_ClusteredSliceBias, 0.0));
    vec3 clusterCoords = vec3(floor(gl_FragCoord.xy / fg_ClusteredTileSize),
                              slice) + vec3(0.5); // Pixel center
    // Normalize
    clusterCoords /= vec3(fg_ClusteredHorizontalTiles,
                          fg_ClusteredVerticalTiles,
                          fg_ClusteredDepthSlices);

    vec3 cluster = texture3D(fg_Clusters, clusterCoords).rgb;
    int lightIndex = int(cluster.r);
    int pointCount = int(cluster.g);
    int spotCount  = int(cluster.b);

    if (DEBUG) {
        vec2 margin = step(1.0, mod(gl_FragCoord.xy, vec2(fg_ClusteredTileSize)));
        return mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0),
                   float(pointCount) / 5.0) * margin.x * margin.y;
    }

    vec3 color = vec3(0.0);

    for (int i = 0; i < pointCount; ++i) {
        int index = getIndex(lightIndex++);
        PointLight light = unpackPointLight(index);

        float range = light.attenuation.w;
        vec3 toLight = light.position.xyz - p;
        // Ignore fragments outside the light volume
        if (dot(toLight, toLight) > (range * range))
            continue;

        float d = length(toLight);
        float att = 1.0 / (light.attenuation.x             // constant
                           + light.attenuation.y * d       // linear
                           + light.attenuation.z * d * d); // quadratic
        vec3 lightDir = normalize(toLight);
        float NdotL = max(dot(n, lightDir), 0.0);

        vec3 Iamb  = light.ambient.rgb;
        vec3 Idiff = gl_FrontMaterial.diffuse.rgb * light.diffuse.rgb * NdotL;
        vec3 Ispec = vec3(0.0);

        if (NdotL > 0.0) {
            vec3 halfVector = normalize(lightDir + normalize(-p));
            float NdotHV = max(dot(n, halfVector), 0.0);
            Ispec = gl_FrontMaterial.specular.rgb
                * light.specular.rgb
                * pow(NdotHV, gl_FrontMaterial.shininess);
        }

        color += ((Iamb + Idiff) * texel + Ispec) * att;
    }

    for (int i = 0; i < spotCount; ++i) {
        int index = getIndex(lightIndex++);
        SpotLight light = unpackSpotLight(index);

        vec3 toLight = light.position.xyz - p;

        float d = length(toLight);
        float att = 1.0 / (light.attenuation.x             // constant
                           + light.attenuation.y * d       // linear
                           + light.attenuation.z * d * d); // quadratic

        vec3 lightDir = normalize(toLight);

        float spotDot = dot(-lightDir, light.direction.xyz);
        if (spotDot < light.cos_cutoff)
            continue;

        att *= pow(spotDot, light.exponent);

        float NdotL = max(dot(n, lightDir), 0.0);

        vec3 Iamb  = light.ambient.rgb;
        vec3 Idiff = gl_FrontMaterial.diffuse.rgb * light.diffuse.rgb * NdotL;
        vec3 Ispec = vec3(0.0);

        if (NdotL > 0.0) {
            vec3 halfVector = normalize(lightDir + normalize(-p));
            float NdotHV = max(dot(n, halfVector), 0.0);
            Ispec = gl_FrontMaterial.specular.rgb
                * light.specular.rgb
                * pow(NdotHV, gl_FrontMaterial.shininess);
        }

        color += ((Iamb + Idiff) * texel + Ispec) * att;
    }

    return clamp(color, 0.0, 1.0);
}
