#version 330 compatibility

in vec3 phmSkyRay;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	float lr = length(phmSkyRay);
	vec3 d = lr > 1e-8 ? phmSkyRay / lr : vec3(0.0, 1.0, 0.0);

	bool nebula = phmUseEndSkyNebula();
#ifdef IRIS
	// Some builds draw the end “void cap” before biome uniforms match; void verts are ~black.
	if (!nebula && dot(gl_Color.rgb, gl_Color.rgb) < 0.03 && !hasSkylight && !hasCeiling) {
		nebula = true;
	}
#endif

	if (nebula) {
		outColor0 = vec4(adrianSkyColor(d), 1.0);
	} else {
		outColor0 = vec4(gl_Color.rgb, 1.0);
	}
}
