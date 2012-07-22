#version 400

uniform mat4 MVP;

layout(location = 0) in vec2 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 texCoord;


out vec4 vColor;
out vec2 vTexCoord;


void main()
{	
	gl_Position = MVP * vec4(Position, 0.0, 1.0);
	vColor = Color;
	vTexCoord = texCoord;
}
