#version 330 compatibility

in vec2 texcoord;
in vec4 glcolor;

#include "/lib/uniforms.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	outColor0 = texture(gtexture, texcoord) * glcolor;
}
