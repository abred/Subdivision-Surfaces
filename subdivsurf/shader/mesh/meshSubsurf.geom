#version 400

layout(triangles, invocations = 1) in;
layout(triangle_strip, max_vertices = 4) out;

uniform sampler2D displacementMap;

in vec4 vColor[];
in vec4 vPosition[];
in vec2 vTexCoord[];


out vec4 gColor;
out vec4 gPosition;
out vec2 gTexCoord;
out vec3 gGridDistance;
//out vec3 gNormal;

void main()
{	
	gColor = vColor[0];
	gTexCoord = vTexCoord[0];
	gl_Position = gl_in[0].gl_Position;
//	gl_Position = gl_in[0].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = vPosition[0];
	gGridDistance = vec3(1.0, 0.0, 0.0);
	EmitVertex();

	gColor = vColor[1];
	gTexCoord = vTexCoord[1];
	gl_Position = gl_in[1].gl_Position;
//	gl_Position = gl_in[1].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = vPosition[1];
	gGridDistance = vec3(0.0, 1.0, 0.0);
	EmitVertex();
	
	gColor = vColor[2];
	gTexCoord = vTexCoord[2];
	gl_Position = gl_in[2].gl_Position;
//	gl_Position = gl_in[2].gl_Position + texture(displacementMap, gTexCoord);
	gPosition = vPosition[2];
	gGridDistance = vec3(0.0, 0.0, 1.0);
	EmitVertex();
	EndPrimitive();
}

