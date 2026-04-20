#version 330 compatibility

out vec2 texcoord;

void main() {
	texcoord = gl_MultiTexCoord0.st;
	gl_Position = ftransform();
}
