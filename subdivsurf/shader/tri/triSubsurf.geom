#version 400

layout(triangles, invocations = 1) in;
layout(triangle_strip, max_vertices = 4) out;


uniform sampler2D displacementMap;

uniform mat4 MVP;
uniform mat4 MV;
uniform mat4 normalMatrix;

uniform float displacementScale;

precise in vec2 teTexCoord[];
precise in vec2 teSTexCoord[];
in vec4 teNormal[];


precise out vec4 gPosition;
precise out vec2 gTexCoord;
out vec3 gGridDistance;
out vec4 gNormal;
out vec3 gNormalFlat;

precise gl_Position;

void main()
{	
	gNormalFlat = normalize(normalMatrix * 
	              vec4(cross(gl_in[1].gl_Position.xyz - gl_in[0].gl_Position.xyz, 
	                         gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz), 0.0)).xyz;
	
	gTexCoord = teTexCoord[0];
//	gl_Position = gl_in[0].gl_Position;
	gl_Position = MVP * (gl_in[0].gl_Position + displacementScale * vec4(texture(displacementMap, teSTexCoord[0] + 0.5/1024.0).xyz, 0.0));
	gPosition = MV * (gl_in[0].gl_Position + displacementScale * vec4(texture(displacementMap, gTexCoord).xyz, 0.0));
	gNormal = normalize(normalMatrix * teNormal[0]);
	gGridDistance = vec3(1.0, 0.0, 0.0);
	EmitVertex();

	gTexCoord = teTexCoord[1];
//	gl_Position = gl_in[1].gl_Position;
	gl_Position = MVP * (gl_in[1].gl_Position + displacementScale * vec4(texture(displacementMap, teSTexCoord[1] + 0.5/1024.0).xyz, 0.0));
	gPosition = MV * (gl_in[1].gl_Position + displacementScale * vec4(texture(displacementMap, gTexCoord).xyz, 0.0));
	gNormal = normalize(normalMatrix * teNormal[1]);
	gGridDistance = vec3(0.0, 1.0, 0.0);
	EmitVertex();
	
	gTexCoord = teTexCoord[2];
//	gl_Position = gl_in[2].gl_Position;
	gl_Position = MVP * (gl_in[2].gl_Position + displacementScale * vec4(texture(displacementMap, teSTexCoord[2] + 0.5/1024.0).xyz, 0.0));
	gPosition = MV * (gl_in[2].gl_Position + displacementScale * vec4(texture(displacementMap, gTexCoord).xyz, 0.0));
	gNormal = normalize(normalMatrix * teNormal[2]);
	gGridDistance = vec3(0.0, 0.0, 1.0);
	EmitVertex();
	EndPrimitive();
}

