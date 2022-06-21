// -*- mode: C; -*-
// UBERSHADER - default forward rendering - fragment shader
// Licence: GPL v2
// Authors: Frederic Bouvier and Gijs de Rooy
// with major additions and revisions by
// Emilian Huminiuc and Vivian Meazza 2011
#version 120

varying	vec4	diffuseColor;
varying	vec3 	VBinormal;
varying	vec3 	VNormal;
varying	vec3 	VTangent;
varying	vec3 	rawpos;
varying vec3	eyeVec;
varying vec3	eyeDir;

uniform sampler2D	BaseTex;
uniform sampler2D	LightMapTex;
uniform sampler2D	NormalTex;
uniform sampler2D	ReflGradientsTex;
uniform sampler2D	ReflMapTex;
uniform sampler3D	ReflNoiseTex;
uniform samplerCube	Environment;

uniform int		dirt_enabled;
uniform int		dirt_multi;
uniform int		lightmap_enabled;
uniform int		lightmap_multi;
uniform int		nmap_dds;
uniform int		nmap_enabled;
uniform int		refl_enabled;
uniform	int		refl_dynamic;
uniform int		refl_map;

uniform float	amb_correction;
uniform float	dirt_b_factor;
uniform float	dirt_g_factor;
uniform float	dirt_r_factor;
uniform float	lightmap_a_factor;
uniform float	lightmap_b_factor;
uniform float	lightmap_g_factor;
uniform float	lightmap_r_factor;
uniform float	nmap_tile;
uniform float	refl_correction;
uniform float	refl_fresnel;
uniform float	refl_noise;
uniform float	refl_rainbow;

uniform vec3	lightmap_r_color;
uniform vec3	lightmap_g_color;
uniform vec3	lightmap_b_color;
uniform vec3	lightmap_a_color;

uniform vec3	dirt_r_color;
uniform vec3	dirt_g_color;
uniform vec3	dirt_b_color;

///reflection orientation
uniform mat4	osg_ViewMatrixInverse;
uniform float	latDeg;
uniform float	lonDeg;

///fog include//////////////////////
uniform int fogType;
vec3 fog_Func(vec3 color, int type);
////////////////////////////////////


//////rotation matrices/////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
mat3 rotX(in float angle)
{
	mat3 rotmat = mat3(
						1.0,	0.0,		0.0,
						0.0,	cos(angle),	-sin(angle),
						0.0,	sin(angle),	cos(angle)
	);
	return rotmat;
}

mat3 rotY(in float angle)
{
	mat3 rotmat = mat3(
						cos(angle),		0.0,	sin(angle),
						0.0,			1.0,	0.0,
						-sin(angle),	0.0,	cos(angle)
	);
	return rotmat;
}

mat3 rotZ(in float angle)
{
	mat3 rotmat = mat3(
						cos(angle),	-sin(angle),	0.0,
						sin(angle),	cos(angle),		0.0,
						0.0,		0.0,			1.0
	);
	return rotmat;
}

////////////////////////////////////////////////////////////////////////////////


void main (void)
{
	vec4 texel      = texture2D(BaseTex, gl_TexCoord[0].st);
	vec4 nmap       = texture2D(NormalTex, gl_TexCoord[0].st * nmap_tile);
	vec4 reflmap    = texture2D(ReflMapTex, gl_TexCoord[0].st);
	vec4 noisevec   = texture3D(ReflNoiseTex, rawpos.xyz);
	vec4 lightmapTexel = texture2D(LightMapTex, gl_TexCoord[0].st);

	vec3 mixedcolor;
	vec3 N = vec3(0.0,0.0,1.0);
	float pf = 0.0;

	///BEGIN bump //////////////////////////////////////////////////////////////////
 	if (nmap_enabled > 0 ){
		N = nmap.rgb * 2.0 - 1.0;
		N = normalize(N.x * VTangent + N.y * VBinormal + N.z * VNormal);
		if (nmap_dds > 0)
			N = -N;
 	} else {
 		N = normalize(VNormal);
 	}
	///END bump ////////////////////////////////////////////////////////////////////
	vec3 viewN	 = normalize((gl_ModelViewMatrixTranspose * vec4(N,0.0)).xyz);
	vec3 viewVec = normalize(eyeVec);
	float v      = abs(dot(viewVec, viewN));// Map a rainbowish color
	vec4 fresnel = texture2D(ReflGradientsTex, vec2(v, 0.75));
	vec4 rainbow = texture2D(ReflGradientsTex, vec2(v, 0.25));

	mat4 reflMatrix = gl_ModelViewMatrixInverse;
	vec3 wRefVec	= reflect(viewVec,N);

	////dynamic reflection /////////////////////////////
	if (refl_dynamic > 0){
		reflMatrix = osg_ViewMatrixInverse;

		vec3 wVertVec	= normalize(reflMatrix * vec4(viewVec,0.0)).xyz;
		vec3 wNormal	= normalize(reflMatrix * vec4(N,0.0)).xyz;

		float latRad = radians(90.-latDeg);
		float lonRad = radians(lonDeg);

		mat3 rotCorrY = rotY(latRad);
		mat3 rotCorrZ = rotZ(lonRad);
		mat3 reflCorr = rotCorrY * rotCorrZ;
		wRefVec	= reflect(wVertVec,wNormal);
		wRefVec = normalize(reflCorr * wRefVec);
	} else {	///static reflection
		wRefVec = normalize(reflMatrix * vec4(wRefVec,0.0)).xyz;
	}

	vec3 reflection = textureCube(Environment, wRefVec).xyz;

	vec3 E = eyeDir;
	E = normalize(E);

	vec3 L = normalize((gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz);
	vec3 H = normalize(L + E);

	N = viewN;

	float nDotVP = dot(N,L);
	float nDotHV = dot(N,H);
	float eDotLV = max(0.0, dot(-E,L));

	//glare on the backside of tranparent objects
	if ((gl_Color.a < .999 || texel.a < 1.0) && nDotVP < 0.0) {
		nDotVP = dot(-N, L);
		nDotHV = dot(-N, H);
	}

	nDotVP = max(0.0, nDotVP);
	nDotHV = max(0.0, nDotHV);

	if (nDotVP == 0.0)
		pf = 0.0;
	else
		pf = pow(nDotHV, gl_FrontMaterial.shininess);

	vec4 Diffuse  = gl_LightSource[0].diffuse * nDotVP;
	vec4 Specular = gl_FrontMaterial.specular * gl_LightSource[0].diffuse * pf;

	vec4 color = gl_Color + Diffuse*diffuseColor;
	color = clamp( color, 0.0, 1.0 );
	color.a = texel.a * diffuseColor.a;
	////////////////////////////////////////////////////////////////////
	//BEGIN reflect
	////////////////////////////////////////////////////////////////////
	if (refl_enabled > 0 ){
		float reflFactor = 0.0;
		float transparency_offset = clamp(refl_correction, -1.0, 1.0);// set the user shininess offset

		if(refl_map > 0){
			// map the shininess of the object with user input
			reflFactor = reflmap.a + transparency_offset;
		} else if (nmap_enabled > 0) {
			// set the reflectivity proportional to shininess with user input
			reflFactor = gl_FrontMaterial.shininess * 0.0078125 * nmap.a + transparency_offset;
		} else {
			reflFactor = gl_FrontMaterial.shininess* 0.0078125 + transparency_offset;
		}
		reflFactor = clamp(reflFactor, 0.0, 1.0);

		// add fringing fresnel and rainbow effects and modulate by reflection
		vec3 reflcolor = mix(reflection, rainbow.rgb, refl_rainbow * v);
		vec3 reflfrescolor = mix(reflcolor, fresnel.rgb, refl_fresnel  * v);
		vec3 noisecolor = mix(reflfrescolor, noisevec.rgb, refl_noise);
		vec3 raincolor = noisecolor * reflFactor;
		raincolor += Specular.rgb;
		raincolor *= gl_LightSource[0].diffuse.rgb;
		mixedcolor = mix(texel.rgb, raincolor, reflFactor);
 	} else {
 		mixedcolor = texel.rgb;
 	}
 	/////////////////////////////////////////////////////////////////////
 	//END reflect
 	/////////////////////////////////////////////////////////////////////

 	if (color.a<1.0){
		color.a += .1 * eDotLV;
 	}
 	//////////////////////////////////////////////////////////////////////
 	//begin DIRT
 	//////////////////////////////////////////////////////////////////////
 	if (dirt_enabled >= 1){
		vec3 dirtFactorIn = vec3 (dirt_r_factor, dirt_g_factor, dirt_b_factor);
		vec3 dirtFactor = reflmap.rgb * dirtFactorIn.rgb;
		mixedcolor.rgb = mix(mixedcolor.rgb, dirt_r_color, smoothstep(0.0, 1.0, dirtFactor.r));
		if (color.a < 1.0) {
			color.a += dirtFactor.r * eDotLV;
		}
		if (dirt_multi > 0) {
			mixedcolor.rgb = mix(mixedcolor.rgb, dirt_g_color, smoothstep(0.0, 1.0, dirtFactor.g));
			mixedcolor.rgb = mix(mixedcolor.rgb, dirt_b_color, smoothstep(0.0, 1.0, dirtFactor.b));
			if (color.a < 1.0) {
				color.a += dirtFactor.g * eDotLV;
				color.a += dirtFactor.b * eDotLV;
			}
		}

	}
	//////////////////////////////////////////////////////////////////////
	//END Dirt
	//////////////////////////////////////////////////////////////////////


	// set ambient adjustment to remove bluiness with user input
	float ambient_offset = clamp(amb_correction, -1.0, 1.0);
	vec4 ambient = gl_LightModel.ambient + gl_LightSource[0].ambient;

	vec3 ambient_Correction = vec3(ambient.rg, ambient.b * 0.6);

	ambient_Correction *= ambient_offset;
	ambient_Correction = clamp(ambient_Correction, -1.0, 1.0);

	vec4 fragColor = vec4(color.rgb * mixedcolor + ambient_Correction.rgb, color.a);

	fragColor += Specular * nmap.a;

	//////////////////////////////////////////////////////////////////////
	// BEGIN lightmap
	//////////////////////////////////////////////////////////////////////
	if ( lightmap_enabled >= 1 ) {
		vec3 lightmapcolor = vec3(0.0);
		vec4 lightmapFactor = vec4(lightmap_r_factor, lightmap_g_factor,
								  lightmap_b_factor, lightmap_a_factor);
		lightmapFactor = lightmapFactor * lightmapTexel;
		if (lightmap_multi > 0 ){
			lightmapcolor = lightmap_r_color * lightmapFactor.r +
			                lightmap_g_color * lightmapFactor.g +
			                lightmap_b_color * lightmapFactor.b +
			                lightmap_a_color * lightmapFactor.a ;
		} else {
			lightmapcolor = lightmapTexel.rgb * lightmap_r_color * lightmapFactor.r;
		}
		fragColor.rgb = max(fragColor.rgb, lightmapcolor * smoothstep(0.0, 1.0, mixedcolor*.5 + lightmapcolor*.5));
	}
	//////////////////////////////////////////////////////////////////////
	// END lightmap
	/////////////////////////////////////////////////////////////////////

	fragColor.rgb = fog_Func(fragColor.rgb, fogType);

	gl_FragColor = fragColor;//vec4(1.0,0.0,0.0,0.5);
}
