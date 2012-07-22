#version 400

uniform sampler2D occlusionMap;
uniform sampler2D normalMap;
uniform sampler2D displacementMap;

in vec4 gColor;
in vec2 gTexCoord;


layout(location = 0, index = 0) out vec4 FragColor;

void main()
{
//	FragColor = gColor;
	FragColor = vec4(1.0, 0.0, 0.0, 1.0);
//	FragColor = texture(occlusionMap, gTexCoord);
	
}
