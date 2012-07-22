#version 400

uniform sampler2D occlusionMap;
uniform sampler2D normalMap;
uniform sampler2D displacementMap;

uniform mat4 normalMatrix;

uniform vec3 lightPosition;
uniform vec3 diffuseMaterial;
uniform vec3 ambientMaterial;
uniform vec3 specularMaterial;
uniform float shininess;


in vec4 gColor;
in vec4 gPosition;
in vec3 gGridDistance;
in vec2 gTexCoord;
//in vec3 gNormal;
//in vec3 gTriDistance;
//in vec4 gPatchDistance;


const vec4 InnerLineColor = vec4(1, 1, 1, 1);
const bool DrawLines = true;


layout(location = 0, index = 0) out vec4 FragColor;


//float amplify(float d, float scale, float offset)
//{
//	d = scale * d + offset;
//	d = clamp(d, 0, 1);
//	d = 1 - exp2(-2*d*d);
//	return d;
//}


void main()
{
//	vec3 N = normalize(normalMatrix * texture(normalMap, gTexCoord));
//	vec3 L = lightPosition;
//	vec3 E = vec3(0, 0, 1);
//	vec3 H = normalize(L + E);

//	float df = abs(dot(N, L));
//	float sf = abs(dot(N, H));
//	sf = pow(sf, shininess);
//	vec3 color = ambientMaterial + df * diffuseMaterial + sf * specularMaterial;

	if (DrawLines) 
	{
		float d1 = min(min(gGridDistance.x, gGridDistance.y), gGridDistance.z);
//		float d2 = min(min(min(gPatchDistance.x, gPatchDistance.y), gPatchDistance.z), gPatchDistance.w);
//		d1 = 1 - amplify(d1, 50, -0.5);
//		d2 = amplify(d2, 50, -0.5);
//		color = d2 * color + d1 * d2 * InnerLineColor;
		if (d1 <= 0.01)
		{
			FragColor = InnerLineColor;
		}
		else
		{
//			FragColor = vec4(texture(normalMap, gTexCoord).xyz, 1.0);
			FragColor = vec4(gTexCoord, 0.0, 1.0);
		}
	}
	else
	{
		FragColor = vec4(texture(normalMap, gTexCoord).xyz, 1.0);
//		FragColor = texture(occlusionMap, gTexCoord);
	}
}






