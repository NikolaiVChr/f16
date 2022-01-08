// -*- mode: C; -*-
#version 120
// Licence: GPL v2
// Author: Frederic Bouvier.

uniform bool fg_DepthInColor;

vec2 normal_encode(vec3 n);
vec3 float_to_color(in float f);

// attachment 0:  normal.x  |  normal.y  |    0.0     |    1.0
// attachment 1: diffuse.r  | diffuse.g  | diffuse.b  | material Id
// attachment 2: specular.l | shininess  | emission.l |  unused
// attachment 3:     ---------- depth ------------    |  unused        (optional)
//
void encode_gbuffer(vec3 normal, vec3 color, int mId, float specular, float shininess, float emission, float depth)
{
    gl_FragData[0] = vec4( normal_encode(normal), 0.0, 1.0 );
    gl_FragData[1] = vec4( color, float( mId ) / 255.0 );
    gl_FragData[2] = vec4( specular, shininess / 128.0, emission, 1.0 );
    vec3 dcol = vec3(1.0, 1.0, 1.0);
    if (fg_DepthInColor)
        dcol = float_to_color(depth);
    gl_FragData[3] = vec4(dcol, 1.0);
}
