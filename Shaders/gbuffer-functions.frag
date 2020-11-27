// -*- mode: C; -*-
#version 120
// Licence: GPL v2
// Author: Frederic Bouvier.

uniform vec3 fg_Planes;
uniform bool fg_DepthInColor;

// normal compression functions from 
//   http://aras-p.info/texts/CompactNormalStorage.html#method04spheremap
vec2 normal_encode(vec3 n)
{
    float p = sqrt(n.z * 8.0 + 8.0);
    return n.xy / p + 0.5;
}

vec3 normal_decode(vec2 enc)
{
    vec2 fenc = enc * 4.0 - 2.0;
    float f = dot(fenc,fenc);
    float g = sqrt(1.0 - f / 4.0);
    vec3 n;
    n.xy = fenc * g;
    n.z = 1.0 - f / 2.0;
    return n;
}

// depth to color encoding and decoding functions from
//   Deferred Shading Tutorial by Fabio Policarpo and Francisco Fonseca
//   (corrected by Frederic Bouvier)
vec3 float_to_color(in float f)
{
    vec3 color;
    f *= 255.0;
    color.x = floor(f);
    f = (f-color.x)*255.0;
    color.y = floor(f);
    color.z = f-color.y;
    color.xy /= 255.0;
    return color;
}

float color_to_float(vec3 color)
{
    const vec3 byte_to_float = vec3(1.0, 1.0/255.0, 1.0/(255.0*255.0));
    return dot(color,byte_to_float);
}

vec3 position( vec3 viewDir, float depth )
{
    vec3 pos;
    pos.z = - fg_Planes.y / (fg_Planes.x + depth * fg_Planes.z);
    pos.xy = viewDir.xy / viewDir.z * pos.z;
    return pos;
}

vec3 position( vec3 viewDir, vec3 depthColor )
{
    return position( viewDir, color_to_float(depthColor) );
}

vec3 position( vec3 viewDir, vec2 coords, sampler2D depth_tex )
{
    float depth;
    if (fg_DepthInColor)
        depth = color_to_float( texture2D( depth_tex, coords ).rgb );
    else
        depth = texture2D( depth_tex, coords ).r;
    return position( viewDir, depth );
}
