// -*- mode: C; -*-
// Licence: GPL v2
// © Emilian Huminiuc and Vivian Meazza 2011
// The fuselage effect is a modified version of model-combined-deffered.
// Modifications author: Nikolai V. Chr. 2017
#version 120

varying	vec3	rawpos;
varying	vec3	VNormal;
varying	vec3	VTangent;
varying	vec3	VBinormal;
varying	vec3	vViewVec;
varying	vec3	reflVec;
varying vec3 	vertVec;
//varying vec3 	lightDir;

//varying	float	alpha;

attribute	vec3	tangent;
attribute	vec3	binormal;

uniform	float		pitch;
uniform	float		roll;
uniform	float		hdg;
uniform	int  		refl_dynamic;
uniform int  		nmap_enabled;
//uniform int  		shader_qual;

// up
uniform float   latDeg;
uniform float   lonDeg;
varying vec3 upInView;
uniform mat4 osg_ViewMatrix;

//////Fog Include///////////
// uniform	int 	fogType;
// void	fog_Func(int type);
////////////////////////////

mat3 rotY(in float angle)
{
    mat3 rotmat = mat3(
                        cos(angle),     0.0,    sin(angle),
                        0.0,            1.0,    0.0,
                        -sin(angle),    0.0,    cos(angle)
    );
    return rotmat;
}

mat3 rotZ(in float angle)
{
    mat3 rotmat = mat3(
                        cos(angle), -sin(angle),    0.0,
                        sin(angle), cos(angle),     0.0,
                        0.0,        0.0,            1.0
    );
    return rotmat;
}

vec3 upInViewSpace(float lat_deg, float lon_deg) {
    float latRad = radians(90-lat_deg);
    float lonRad = radians(lon_deg);
    //mat3 WorldFGInverse = inverse(rotY(latRad) * rotZ(lonRad));
    mat3 WorldFGInverse = rotZ(-lonRad) * rotY(-latRad);
    vec3 up = vec3(0.0, 0.0, 1.0);// up in FG
    up = WorldFGInverse * up;// up in world space
    up = normalize(osg_ViewMatrix * vec4(up, 0.0)).xyz;// up in view space (as in away from ground)
    //up = normalize(fg_ViewMatrix*vec4(up, 0.0)).xyz;
    return up;
}

void	rotationMatrixPR(in float sinRx, in float cosRx, in float sinRy, in float cosRy, out mat4 rotmat)
{
	rotmat = mat4(	cosRy ,	sinRx * sinRy ,	cosRx * sinRy,	0.0,
									0.0   ,	cosRx        ,	-sinRx * cosRx,	0.0,
									-sinRy,	sinRx * cosRy,	cosRx * cosRy ,	0.0,
									0.0   ,	0.0          ,	0.0           ,	1.0 );
}

void	rotationMatrixH(in float sinRz, in float cosRz, out mat4 rotmat)
{
	rotmat = mat4(	cosRz,	-sinRz,	0.0,	0.0,
									sinRz,	cosRz,	0.0,	0.0,
									0.0  ,	0.0  ,	1.0,	0.0,
									0.0  ,	0.0  ,	0.0,	1.0 );
}

void	main(void)
{
	    upInView = upInViewSpace(latDeg,lonDeg);
		rawpos = gl_Vertex.xyz;
		vec4 ecPosition = gl_ModelViewMatrix * gl_Vertex;
		//fog_Func(fogType);

		VNormal = normalize(gl_NormalMatrix * gl_Normal);

		vec3 n = normalize(gl_Normal);
		

		vec3 tempTangent;
		vec3 tempBinormal;
		if (nmap_enabled > 0){
			tempTangent = tangent;
			tempBinormal  = binormal;
			VTangent = normalize(gl_NormalMatrix * tangent);
			VBinormal = normalize(gl_NormalMatrix * binormal);
		} else {
			tempTangent = cross(n, vec3(1.0,0.0,0.0));
			tempBinormal = cross(n, tempTangent);
		}

		
		/*vec3 t = tempTangent;
		vec3 b = tempBinormal;*/

    // Super hack: if diffuse material alpha is less than 1, assume a
	// transparency animation is at work
		/*if (gl_FrontMaterial.diffuse.a < 1.0)
			alpha = gl_FrontMaterial.diffuse.a;
		else
			alpha = gl_Color.a;*/

    // Vertex in eye coordinates
		vertVec = ecPosition.xyz;
		vViewVec.x = dot(tempTangent, vertVec);
		vViewVec.y = dot(tempBinormal, vertVec);
		vViewVec.z = dot(n, vertVec);

	//lightDir = vec3(gl_LightSource[0].position.xyz - vertVec);

    // calculate the reflection vector
		vec4 reflect_eye = vec4(reflect(vertVec, VNormal), 0.0);
		vec3 reflVec_stat = normalize(gl_ModelViewMatrixInverse * reflect_eye).xyz;
		if (refl_dynamic > 0){
			//prepare rotation matrix
			mat4 RotMatPR;
			mat4 RotMatH;
			float _roll = roll;
			if (_roll>90.0 || _roll < -90.0)
			{
				_roll = -_roll;
			}
			float cosRx = cos(radians(_roll));
			float sinRx = sin(radians(_roll));
			float cosRy = cos(radians(-pitch));
			float sinRy = sin(radians(-pitch));
			float cosRz = cos(radians(hdg));
			float sinRz = sin(radians(hdg));
			rotationMatrixPR(sinRx, cosRx, sinRy, cosRy, RotMatPR);
			rotationMatrixH(sinRz, cosRz, RotMatH);
			vec3 reflVec_dyn = (RotMatH * (RotMatPR * normalize(gl_ModelViewMatrixInverse * reflect_eye))).xyz;

			reflVec = reflVec_dyn;
		} else {
			reflVec = reflVec_stat;
		}


		//gl_FrontColor = gl_FrontMaterial.emission;// + gl_Color * (gl_LightModel.ambient + gl_LightSource[0].ambient);
		
		gl_Position = ftransform();
		gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}