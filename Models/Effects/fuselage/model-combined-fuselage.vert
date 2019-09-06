// -*- mode: C; -*-
// UBERSHADER - vertex shader
// Licence: GPL v2
// © Emilian Huminiuc and Vivian Meazza 2011
// The fuselage effect is a modified version of model-combined-deffered.
// Modifications author: Nikolai V. Chr. 2017
#version 120

varying	vec3	VBinormal;
varying	vec3	VNormal;
varying	vec3	VTangent;
varying	vec3	rawpos;
varying vec3 	eyeVec;
varying vec3	eyeDir;

attribute	vec3	tangent;
attribute	vec3	binormal;

uniform int  		nmap_enabled;
//uniform int			rembrandt_enabled;

void	main(void)
{
		rawpos = gl_Vertex.xyz;//model space
		vec4 ecPosition = gl_ModelViewMatrix * gl_Vertex;//view space
		eyeVec = ecPosition.xyz;//view space
		eyeDir = gl_ModelViewMatrixInverse[3].xyz - gl_Vertex.xyz;//model space

		VNormal = normalize(gl_NormalMatrix * gl_Normal);

		vec3 n = normalize(gl_Normal);

// 		generate "fake" binormals/tangents
		/*vec3 c1 = cross(n, vec3(0.0,0.0,1.0));
		vec3 c2 = cross(n, vec3(0.0,1.0,0.0));
		vec3 tempTangent = c1;

		if(length(c2)>length(c1)){
			tempTangent = c2;
		}

		vec3 tempBinormal = cross(n, tempTangent);*/

		if (nmap_enabled > 0){
			//tempTangent = tangent;
			//tempBinormal  = binormal;
			
			VTangent = normalize(gl_NormalMatrix * tangent);
			VBinormal = normalize(gl_NormalMatrix * binormal);
		}		

		/*if(rembrandt_enabled < 1) {
			gl_FrontColor = gl_FrontMaterial.emission;// + gl_Color * (gl_LightModel.ambient + gl_LightSource[0].ambient);
		} else {
		  gl_FrontColor = gl_Color;
		}*/
		
		gl_Position = ftransform();
		gl_ClipVertex = ecPosition;
		gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
