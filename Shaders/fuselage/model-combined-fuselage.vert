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

uniform float		body_width;
uniform int 		wingflex;
uniform float 		wingflex_z;
uniform float		wing_span;
uniform float		rotation_x1;
uniform float		rotation_y1;
uniform float		rotation_z1;
uniform float		rotation_x2;
uniform float		rotation_y2;
uniform float		rotation_z2;
uniform float		rotation_rad;

uniform int  		nmap_enabled;
//uniform int			rembrandt_enabled;

vec2 calc_deflection(float y){
	float distance;
	if(y < body_width*0.5 && y > -body_width*0.5){
		//this part does not move
		distance = 0;
	}else if(y > body_width*0.5){
		distance = y - (body_width/2);
	}else if(y < -body_width*0.5){
		distance = y - ((-1*body_width)/2);
	}
	float max_dist = (wing_span-body_width)/2;
	float deflection = wingflex_z * (distance*distance)/(max_dist*max_dist);
	float delta_y;
	if(y<0){
		delta_y = deflection/wing_span;
	}else{
		delta_y = -deflection/wing_span;
	}
	vec2 returned = vec2 ( deflection, delta_y );
	return returned;
}

void	main(void)
{
		vec4 vertex = gl_Vertex;
		
		if ( wingflex == 1 ) {
			float x_factor = max((abs(vertex.x) - body_width),0);
			float y_factor = max(vertex.y,0.0);
			
			vec2 deflection=calc_deflection(vertex.y);
			
			vertex.z += deflection[0];
			vertex.y += deflection[1];
			
			if(rotation_rad != 0){
				float rotation_rad2 = 0.5 * rotation_rad;
				vec2 defl1=calc_deflection(rotation_y1);
				vec2 defl2=calc_deflection(rotation_y2);
				float rot_y1 = rotation_y1;
				float rot_z1 = rotation_z1;
				float rot_y2 = rotation_y2;
				float rot_z2 = rotation_z2;
				rot_y1 -= defl1[1];
				rot_z1 += defl1[0];
				rot_y2 -= defl2[1];
				rot_z2 += defl2[0];
				//Calculate rotation
				vec3 normal;
				normal[0]=rotation_x2-rotation_x1;
				normal[1]=rot_y2-rot_y1;
				normal[2]=rot_z2-rot_z1;
				normal = normalize(normal);
				float tmp = (1-cos(rotation_rad2));
				mat4 rotation_matrix = mat4(
					pow(normal[0],2)*tmp+cos(rotation_rad2),			normal[1]*normal[0]*tmp-normal[2]*sin(rotation_rad2),	normal[2]*normal[0]*tmp+normal[1]*sin(rotation_rad2),	0.0,
					normal[0]*normal[1]*tmp+normal[2]*sin(rotation_rad2),	pow(normal[1],2)*tmp+cos(rotation_rad2),			normal[2]*normal[1]*tmp-normal[0]*sin(rotation_rad2),	0.0,
					normal[0]*normal[2]*tmp-normal[1]*sin(rotation_rad2),	normal[1]*normal[2]*tmp+normal[0]*sin(rotation_rad2),	pow(normal[2],2)*tmp+cos(rotation_rad2),			0.0,
					0.0,							0.0,							0.0,							1.0
					);
				vec4 old_point;
				old_point[0]=vertex.x;
				old_point[1]=vertex.y;
				old_point[2]=vertex.z;
				old_point[3]=1.0;
				rotation_matrix[3][0] = rotation_x1 	- rotation_x1*rotation_matrix[0][0] - rot_y1*rotation_matrix[1][0] - rot_z1*rotation_matrix[2][0];
				rotation_matrix[3][1] = rot_y1 	- rotation_x1*rotation_matrix[0][1] - rot_y1*rotation_matrix[1][1] - rot_z1*rotation_matrix[2][1];
				rotation_matrix[3][2] = rot_z1 	- rotation_x1*rotation_matrix[0][2] - rot_y1*rotation_matrix[1][2] - rot_z1*rotation_matrix[2][2];
				vec4 new_point=rotation_matrix*old_point;
				vertex.x=new_point[0];
				vertex.y=new_point[1];
				vertex.z=new_point[2];
			}
			
		}
		
		rawpos = vertex.xyz;//model space
		
		vec4 ecPosition = gl_ModelViewMatrix * vertex;//view space
		eyeVec = ecPosition.xyz;//view space
		eyeDir = gl_ModelViewMatrixInverse[3].xyz - vertex.xyz;//model space

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
		
		gl_Position = gl_ModelViewProjectionMatrix * vertex;//ftransform();
		gl_ClipVertex = ecPosition;
		gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
