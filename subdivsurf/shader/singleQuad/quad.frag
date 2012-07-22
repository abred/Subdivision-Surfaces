#version 400

uniform sampler2D occlusionMap;
uniform sampler2D normalMap;
uniform sampler2D displacementMap;

uniform mat4 normalMatrix;

in vec4 gColor;
in vec3 gGridDistance;
in vec2 gTexCoord;



const vec4 InnerLineColor = vec4(1, 1, 1, 1);



layout(location = 0, index = 0) out vec4 FragColor;


void main()
{
	float d1 = min(min(gGridDistance.x, gGridDistance.y), gGridDistance.z);

	if (d1 <= 0.01)
	{
		FragColor = InnerLineColor;
	}
	else
	{
//		FragColor = vec4(texture(normalMap, gTexCoord).xyz, 1.0);
		FragColor = vec4(gTexCoord, 0.0, 1.0);
	}
}






