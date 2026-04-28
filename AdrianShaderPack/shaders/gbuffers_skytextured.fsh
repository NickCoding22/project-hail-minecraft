#version 330 compatibility

uniform sampler2D gtexture;
uniform int biome_category;

uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	if (biome_category == 8) {
		color = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}
}