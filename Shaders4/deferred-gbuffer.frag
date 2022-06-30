#version 120
#extension GL_EXT_gpu_shader4 : enable
// -*- mode: C; -*-
// Licence: GPL v2
// Author: Frederic Bouvier.
//

varying vec3 ecNormal;
varying float alpha;
uniform int materialID;
uniform sampler2D texture;

void encode_gbuffer(vec3 normal, vec3 color, int mId, float specular, float shininess, float emission, float depth);

void main() {
    vec4 texel = texture2D(texture, gl_TexCoord[0].st);
    if (texel.a * alpha < 0.1)
        discard;
    float specular = dot( gl_FrontMaterial.specular.rgb, vec3( 0.3, 0.59, 0.11 ) );
    float shininess = gl_FrontMaterial.shininess;
    float emission = dot( gl_FrontLightModelProduct.sceneColor.rgb, vec3( 0.3, 0.59, 0.11 ) );

    vec3 normal2 = normalize( (2.0 * gl_Color.a - 1.0) * ecNormal );
    encode_gbuffer(normal2, gl_Color.rgb * texel.rgb, materialID, specular, shininess, emission, gl_FragCoord.z);
}
