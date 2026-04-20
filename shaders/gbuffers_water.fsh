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
	vec3 albedo = tex.rgb;
	vec3 lm = texture(lightmap, lmcoord).rgb;
	vec3 rgb;
	if (isAdrianEnd()) {
		vec3 tinted = adrianTerrainShade(albedo, lm, normal, vPos);
		vec3 waterTint = vec3(0.12, 0.55, 0.18);
		rgb = mix(tinted, tinted * waterTint + vec3(0.05, 0.22, 0.06), 0.35);
	} else {
		rgb = albedo * lm;
	}
	outColor0 = vec4(rgb, tex.a * glcolor.a);
}
