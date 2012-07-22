#version 400

layout(triangles, invocations = 1) in;
layout(triangle_strip, max_vertices = 4) out;

uniform sampler2D displacementMap;

in vec4 teColor[];
in vec4 tePosition[];
in vec2 teTexCoord[];


out vec4 gColor;
out vec4 gPosition;
out vec2 gTexCoord;
out vec3 gGridDistance;
//out vec3 gNormal;

void main()
{	
	gColor = teColor[0];
	gTexCoord = teTexCoord[0];
	gl_Position = gl_in[0].gl_Position;
//	gl_Position = gl_in[0].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = tePosition[0];
	gGridDistance = vec3(1.0, 0.0, 0.0);
	EmitVertex();

	gColor = teColor[1];
	gTexCoord = teTexCoord[1];
	gl_Position = gl_in[1].gl_Position;
//	gl_Position = gl_in[1].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = tePosition[1];
	gGridDistance = vec3(0.0, 1.0, 0.0);
	EmitVertex();
	
	gColor = teColor[2];
	gTexCoord = teTexCoord[2];
	gl_Position = gl_in[2].gl_Position;
//	gl_Position = gl_in[2].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = tePosition[2];
	gGridDistance = vec3(0.0, 0.0, 1.0);
	EmitVertex();
	EndPrimitive();
}

