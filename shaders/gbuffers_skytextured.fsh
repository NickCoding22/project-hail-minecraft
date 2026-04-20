#version 330 compatibility

in vec3 phmSkyRay;
in vec2 texcoord;
in vec4 glcolor;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	float lr = length(phmSkyRay);
	vec3 d = lr > 1e-8 ? phmSkyRay / lr : vec3(0.0, 1.0, 0.0);

	if (phmUseEndSkyNebula()) {
		outColor0 = vec4(adrianSkyColor(d), 1.0);
	} else {
		outColor0 = texture(gtexture, texcoord) * glcolor;
	}
}
