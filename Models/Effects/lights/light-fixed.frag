// -*-C++-*-
#version 120

uniform sampler2D texture;

uniform float light_color_base_r;
uniform float light_color_base_g;
uniform float light_color_base_b;

uniform float light_color_center_r;
uniform float light_color_center_g;
uniform float light_color_center_b;

uniform float intensity_scale;

uniform float pointing_x;
uniform float pointing_y;
uniform float pointing_z;

uniform float outer_angle;
uniform float inner_angle;
uniform float zero_angle;
uniform float outer_gain;

//uniform float visibility;
//uniform float avisibility;
//uniform float hazeLayerAltitude;
uniform float eye_alt;
uniform float terminator;

uniform float osg_SimulationTime;

uniform bool is_directional;
uniform bool is_strobe;

varying vec3 vertex;
varying vec3 relPos;
varying vec3 normal;

float Noise2D(in vec2 coord, in float wavelength);
vec3 fog_Func(vec3 color, int type);

float shape (in vec3 coord, in float noise, in float fade, in float transmission, in float glare, in float lightArg) 
{
   float r = length (coord) / max(fade, 0.2);

   float angle = noise * 6.2832;

   float sinphi = dot(vec2 (sin(angle),cos(angle)), normalize(coord.yz));
   float sinterm = sin(mod((sinphi-3.0) * (sinphi-3.0),6.2832));
   float ray = 0.0;
   if (sinterm == 0.0)
   	{ray = 0.0;}
   else
	//{ray = clamp(pow(sinterm,10.0),0.0,1.0);
	{ray = sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm * sinterm;
   	ray *= exp(-40.0 * r * r) * smoothstep(0.8, 1.0,fade) * smoothstep(0.7, 1.0, glare);
	}



   float base = exp(-80.0*r*r );
   float halo = 0.2 * exp(-10.0 * r * r) * (1.0 - smoothstep(-5.0, 0.0, lightArg));
   float fogEffect =  (1.0-smoothstep(0.4,0.8,transmission));
   //fogEffect = 1.0;

   //float offset = 0.0;
   //offset *=0.3;
   //vec2 offset_vec = vec2 (1.0, 0.0);
   //offset_vec *= offset;

  // vec2 coord_reduced1 = vec2(coord.y- 1.2* offset_vec.x, coord.z -  1.2 * offset_vec.y); 
   //vec2 coord_reduced2 = vec2(coord.y- 2.0 * offset_vec.x, coord.z - 2.0 * offset_vec.y); 
   //vec3 coord_reduced = coord;
   //r = min(length (coord_reduced1), 0.8* length(coord_reduced2));
   //r /= 1.0 - 0.3 * smoothstep(0.0, 0.3, offset);

   float intensity = clamp(base + halo + ray,0.0,1.0) + 0.2 * fogEffect * (1.0-smoothstep(0.3, 0.6,r));

   intensity *=fade;

return intensity;
}


float directional_fade (in float direction)
{

float arg = clamp(direction, 0.0, 1.0);
float ia = (1.0 - inner_angle);
float oa = (1.0 - outer_angle);
float za = (1.0 - zero_angle);

if (direction > ia) {return 1.0;}
else if (direction > oa) 
	{return outer_gain + (1.0-outer_gain) * (direction - oa) / (ia - oa);}
else if (direction > za)
	{return outer_gain * (direction - za) / (oa - za);}
else {return 0.0;}

}

float strobe_fade (in float fade)
{

float time_arg1 = sin(4.0 * osg_SimulationTime);
float time_arg2 = sin(4.0 * osg_SimulationTime - 0.4);

return fade * 0.825 * (pow(time_arg1, 40.0) + pow(time_arg2, 8.0));

}

float fog_transmission()
{
	//if (type == 0){
		const float LOG2 = 1.442695;
		//float fogCoord =length(PointPos);
		float fogCoord = gl_ProjectionMatrix[3].z/(gl_FragCoord.z * -2.0 + 1.0 - gl_ProjectionMatrix[2].z);
		float fogFactor = exp2(-gl_Fog.density * gl_Fog.density * fogCoord * fogCoord * LOG2);

		if(gl_Fog.density == 1.0)
			fogFactor=1.0;

		return fogFactor;
}


void main()
{

float noise = 0.0;

vec3 light_color_base = vec3 (light_color_base_r, light_color_base_g, light_color_base_b);    
vec3 light_color_center = vec3 (light_color_center_r, light_color_center_g, light_color_center_b);    

vec3 pointing_vec = vec3 (pointing_x, pointing_y, pointing_z);
vec3 viewDir = normalize(relPos);

// fogging

float dist = length(relPos);
//float delta_z = hazeLayerAltitude - eye_alt;
float transmission = 1.0;
float vAltitude;
//float delta_zv;
float H;
float distance_in_layer;
/**
float transmission_arg;

 // angle with horizon
    float ct = dot(vec3(0.0, 0.0, 1.0), relPos)/dist;


    if (delta_z > 0.0) // we're inside the layer
	{
	if (ct < 0.0) // we look down
		{
		distance_in_layer = dist;
		vAltitude = min(distance_in_layer,min(visibility, avisibility)) * ct;
  		delta_zv = delta_z - vAltitude;
		}
	else 	// we may look through upper layer edge
		{
		H = dist * ct;
		if (H > delta_z) {distance_in_layer = dist/H * delta_z;}
		else {distance_in_layer = dist;}
		vAltitude = min(distance_in_layer,visibility) * ct;
  		delta_zv = delta_z - vAltitude;
		}
	}
   else // we see the layer from above, delta_z < 0.0
	{
	H = dist * -ct;
	if (H  < (-delta_z)) 
		{
		distance_in_layer = 0.0;
		delta_zv = 0.0;
		}
	else
		{
		vAltitude = H + delta_z;
		distance_in_layer = vAltitude/H * dist;
		vAltitude = min(distance_in_layer,visibility) * (-ct);
		delta_zv = vAltitude;
		}
	}



    transmission_arg = (dist-distance_in_layer)/avisibility;
    if (visibility < avisibility)
	{
	transmission_arg = transmission_arg + (distance_in_layer/visibility);
	}
   else
	{
	transmission_arg = transmission_arg + (distance_in_layer/avisibility);
	}

*/

    transmission =  fog_transmission();
    float lightArg = terminator/100000.0;


float r = length(vertex);
float mix_factor = 0.3 + 0.7 * smoothstep(0.0, 0.5, r);

// directionality

vec3 nViewDir = normalize(viewDir);
vec3 nPointingVec = normalize(pointing_vec);
float direction = dot (nViewDir, nPointingVec );

float fade;
vec2 offset = vec2 (0.0, 0.0);

if (is_directional)
	{
	fade = directional_fade(direction);
	}
else	
	{fade = 1.0;}



// time evolution

if (is_strobe) {fade = strobe_fade (fade);}

fade *= intensity_scale;

// disc size correction for daylight

// shape of the light disc
float glare = length(light_color_center)/1.7321 * (1.0 - smoothstep(-5.0, 10.0, lightArg));
float intensity = shape(vertex, noise, fade, transmission, glare, lightArg);

// coloring of the light disc
vec3 light_color = mix(light_color_base, light_color_center, intensity*intensity);


gl_FragColor =   vec4 (light_color.rgb, intensity * transmission );


}
