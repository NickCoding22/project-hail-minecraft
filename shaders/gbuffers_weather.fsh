#version 330 compatibility

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {
	vec4 tex = texture(gtexture, texcoord) * glcolor;
	vec3 lm = texture(lightmap, lmcoord).rgb;
	vec3 rgb;
	if (isAdrianEnd()) {
		rgb = adrianTerrainShade(tex.rgb, lm, vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
	} else {
		rgb = tex.rgb * lm;
	}
	outColor0 = vec4(rgb, tex.a);
}
