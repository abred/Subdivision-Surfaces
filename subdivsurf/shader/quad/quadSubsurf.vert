#version 400

uniform mat4 MVP;

layout(location = 0) in vec3 position;
layout(location = 2) in vec2 texCoord;


precise out vec2 vTexCoord;


void main()
{	
	gl_Position = vec4(position, 1.0);
	vTexCoord = texCoord;
}
