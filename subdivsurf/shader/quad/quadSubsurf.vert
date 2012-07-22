#version 400

uniform mat4 MVP;

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 texCoord;


out vec4 vColor;
out vec2 vTexCoord;


void main()
{	
	gl_Position = vec4(Position, 1.0);
	vColor = Color;
	vTexCoord = texCoord;
}
