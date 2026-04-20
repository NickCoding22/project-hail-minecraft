#version 330 compatibility

out vec3 phmSkyRay;
out vec2 texcoord;
out vec4 glcolor;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_FrontColor = gl_Color;
	vec4 posv = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * posv;
	vec3 viewPos = posv.xyz;
	phmSkyRay = mat3(gbufferModelViewInverse) * viewPos;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}
