#version 330 compatibility

// Unnormalized world-oriented ray; normalize in the fragment shader after interpolation.
// Interpolating normalized directions across large sky triangles collapses to gray/black bands.
out vec3 phmSkyRay;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_FrontColor = gl_Color;
	vec4 posv = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * posv;
	vec3 viewPos = posv.xyz;
	phmSkyRay = mat3(gbufferModelViewInverse) * viewPos;
}
