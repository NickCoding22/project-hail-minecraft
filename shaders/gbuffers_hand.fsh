#version 330 compatibility

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 vPos;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec4 tex = texture(gtexture, texcoord) * glcolor;
	if (tex.a < 0.1) {
		discard;
	}
	vec3 albedo = tex.rgb;
	vec3 lm = texture(lightmap, lmcoord).rgb;
	vec3 rgb;
	if (isAdrianEnd()) {
		rgb = adrianTerrainShade(albedo, lm, normal, vPos);
	} else {
		rgb = albedo * lm;
	}
	outColor0 = vec4(rgb, tex.a);
}
