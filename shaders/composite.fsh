#version 330 compatibility

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec3 scene = texture(colortex0, texcoord).rgb;
	float depth = texture(depthtex0, texcoord).r;

	// Sky / void: depth clears to ~0 or ~1 depending on Z mode; never apply world fog here.
	bool sky = depth >= 0.9995 || depth <= 1e-4;
	if (!isAdrianEnd() || sky) {
		outColor0 = vec4(scene, 1.0);
		return;
	}

	float ndc = depth * 2.0 - 1.0;
	float denom = far + near - ndc * (far - near);
	if (abs(denom) < 1e-6) {
		outColor0 = vec4(scene, 1.0);
		return;
	}
	float linearZ = (2.0 * near * far) / denom;
	// Far plane / broken depth: treat as sky so fog never tints the nebula.
	if (linearZ > far * 0.86 || linearZ != linearZ) {
		outColor0 = vec4(scene, 1.0);
		return;
	}

	float fogAmount = 1.0 - exp(-linearZ * adrianFogDensity());
	fogAmount = clamp(fogAmount, 0.0, 0.28);
	vec3 fogCol = adrianFogColor();
	vec3 mixed = mix(scene, fogCol, fogAmount);
	outColor0 = vec4(mixed, 1.0);
}
