#version 400

layout(triangles, invocations = 1) in;
layout(triangle_strip, max_vertices = 4) out;

uniform sampler2D displacementMap;

in vec4 teColor[];
in vec2 teTexCoord[];


out vec4 gColor;
out vec2 gTexCoord;

void main()
{	
	for(int i = 0; i < gl_in.length(); ++i)
	{
		gColor = teColor[i];
		gTexCoord = teTexCoord[i];
		gl_Position = gl_in[i].gl_Position;
//		gl_Position = gl_in[i].gl_Position + texture(displacementMap, gTexCoord);
		EmitVertex();
	}
	EndPrimitive();
}

