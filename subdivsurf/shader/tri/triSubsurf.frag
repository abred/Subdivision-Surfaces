#version 400

uniform sampler2D occlusionMap;
uniform sampler2D smoothOcclusionMap;
uniform sampler2D normalMap;
uniform sampler2D displacementMap;

uniform mat4 normalMatrix;

uniform vec4 lightPosition;
uniform vec3 diffuseMaterial;
uniform vec3 ambientMaterial;
uniform vec3 specularMaterial;
uniform float shininess;
uniform bool drawLines;
uniform bool shading;
uniform bool color3;
uniform float displacementScale;

in vec4 gPosition;
in vec3 gGridDistance;
in vec2 gTexCoord;
in vec4 gNormal;
in vec3 gNormalFlat;


const vec4 lineColor = vec4(1.0, 1.0, 1.0, 1.0);


layout(location = 0, index = 0) out vec4 FragColor;



void main()
{
	vec2 tex = vec2(gTexCoord.x, 1 - gTexCoord.y);
	vec4 color;
	if(color3)
	{
		color = vec4(0.2, 0.15, 0.8, 1.0);
	}
	else
	{
		color = vec4(0.5, 0.35, 0.3, 1.0);
	}
	
	vec4 normalTmp = vec4(2.0 * texture(normalMap, tex + 0.5/2048.0).xyz -1.0, 0.0);
	vec4 normal = normalize(normalMatrix * normalTmp); 
	normal = mix(gNormal, normal, displacementScale);
	
	float occlusion = texture(occlusionMap, tex + 0.5/1024.0).x;
	float smoothOcclusion = texture(smoothOcclusionMap, gTexCoord + 0.5/512.0).x;
	occlusion = mix(smoothOcclusion, occlusion, displacementScale);
	
	if(!shading)
	{
		normal = vec4(gNormalFlat, 0.0);
		occlusion = 1.0;
	}
	
	vec4 lightVec = normalize(lightPosition - gPosition);
	vec4 ref = reflect(-lightVec, normal);
	vec4 pos = normalize(-gPosition);
	
	if (drawLines)
	{
		float d = min(min(gGridDistance.x, gGridDistance.y), gGridDistance.z);

		if (d <= 0.01)
		{
			FragColor = lineColor;
		}
		else
		{
//			FragColor = ambientMaterial + 
//			            diffuseMaterial * max(dot(lightVec, normal), 0.0) + 
//			            specularMaterial * pow(max(dot(ref, xxx), 0.0), shininess);
			FragColor = color * 0.3 + occlusion * 
			           (color * max(dot(lightVec, normal), 0.0) + 
			            0.3 * pow(max(dot(ref, pos), 0.0), shininess));
		}
	}
	else
	{
			FragColor = color * 0.3 + occlusion * 
			           (color * max(dot(lightVec, normal), 0.0) + 
			            0.3 * pow(max(dot(ref, pos), 0.0), shininess));
	}
}






