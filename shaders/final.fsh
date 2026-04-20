#version 330 compatibility

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#include "/lib/uniforms.glsl"
#include "/lib/adrian.glsl"

void main() {
	vec3 c = texture(colortex0, texcoord).rgb;

	vec3 bloom = max(c - 0.55, 0.0);
	bloom *= vec3(0.35, 1.05, 0.22);
	c += bloom * 0.85;

	float depth = texture(depthtex0, texcoord).r;
	bool sky = depth >= 0.9995 || depth <= 1e-4;

	// Neighbor smear was muddying the nebula; keep it for lit geometry only.
	if (isAdrianEnd() && !sky) {
		vec2 px = vec2(1.0 / max(viewWidth, 1.0), 1.0 / max(viewHeight, 1.0));
		vec3 neigh =
			texture(colortex0, texcoord + vec2(px.x, 0.0)).rgb +
			texture(colortex0, texcoord - vec2(px.x, 0.0)).rgb +
			texture(colortex0, texcoord + vec2(0.0, px.y)).rgb +
			texture(colortex0, texcoord - vec2(0.0, px.y)).rgb;
		vec3 blur = neigh * 0.25;
		float br = max(max(blur.r, blur.g), blur.b);
		c += max(blur - 0.4, 0.0) * vec3(0.2, 0.65, 0.12) * smoothstep(0.55, 1.2, br);
	}

	c = c / (c + vec3(1.0));
	c = pow(c, vec3(1.0 / 2.05));
	gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
