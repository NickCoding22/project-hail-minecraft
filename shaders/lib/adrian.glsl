// OptiFine biome_category order (0–16). THE_END is 8.
// Include `/lib/uniforms.glsl` before this file.
#ifndef CAT_THE_END
#define CAT_THE_END 8
#endif

bool isAdrianEnd() {
#ifdef IRIS
	if (!hasSkylight && !hasCeiling) {
		return true;
	}
#endif
	return biome_category == CAT_THE_END;
}

// Sky-only: same rules, kept separate so we can add sky draw-call fallbacks later.
bool phmUseEndSkyNebula() {
#ifdef IRIS
	if (hasCeiling) {
		return false;
	}
	if (!hasSkylight) {
		return true;
	}
#endif
	return biome_category == CAT_THE_END;
}

float phm_hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Not named `noise3`: GLSL compatibility defines a built-in `noise3` with a different signature/return type.
float phm_noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n = i.x + i.y * 57.0 + 113.0 * i.z;
	return mix(
		mix(mix(phm_hash31(vec3(n + 0.0)), phm_hash31(vec3(n + 1.0)), f.x),
			mix(phm_hash31(vec3(n + 57.0)), phm_hash31(vec3(n + 58.0)), f.x), f.y),
		mix(mix(phm_hash31(vec3(n + 113.0)), phm_hash31(vec3(n + 114.0)), f.x),
			mix(phm_hash31(vec3(n + 170.0)), phm_hash31(vec3(n + 171.0)), f.x), f.y),
		f.z);
}

float phm_fbm(vec3 p) {
	float v = 0.0;
	float a = 0.55;
	mat3 m = mat3(0.00, 0.80, 0.60, -0.80, 0.36, -0.48, -0.60, -0.48, 0.64);
	for (int i = 0; i < 5; i++) {
		v += a * phm_noise3(p);
		p = m * p * 2.02 + vec3(17.0);
		a *= 0.5;
	}
	return v;
}

vec3 adrianSkyColor(vec3 dir) {
	float t = frameTimeCounter * 0.018;
	vec3 d = normalize(dir);
	vec2 uv = vec2(atan(d.z, d.x), asin(clamp(d.y, -1.0, 1.0)));
	// Slightly tighter sampling = busier swirls on the dome.
	uv *= vec2(0.28, 0.46);

	vec2 flow = vec2(t * 0.07, t * -0.05);
	float warp = phm_fbm(vec3(uv * 2.4 + flow, t * 0.12)) * 0.42;
	vec2 uwm = uv * 1.6 + vec2(warp, warp * 0.7) + flow;

	float n1 = phm_fbm(vec3(uwm * 1.1, t * 0.09));
	float n2 = phm_fbm(vec3(uwm.yx * 1.35 + 3.1, t * 0.11 + n1));
	float n = mix(n1, n2, 0.5);
	// Push mid-tones apart so bands read clearly on screen.
	n = clamp(pow(mix(n, smoothstep(0.12, 0.88, n), 0.55), 0.82), 0.0, 1.0);

	float fine = phm_fbm(vec3(uv * 3.8 + flow * 1.3, t * 0.15 + 2.0));
	n = mix(n, fine, 0.22);

	float veins = pow(max(0.0, phm_noise3(vec3(uv * 7.2, t * 0.2)) - 0.28), 2.2);

	vec3 neon = vec3(0.62, 1.0, 0.02);
	vec3 deep = vec3(0.04, 0.09, 0.01);
	vec3 amber = vec3(1.0, 0.45, 0.02);
	vec3 yellowCore = vec3(1.0, 0.98, 0.72);

	float bright = smoothstep(0.32, 0.9, n);
	float body = smoothstep(0.06, 0.68, n);
	float amberPatch = smoothstep(0.5, 0.92, phm_noise3(vec3(uv * 0.9 + vec2(40.0, 10.0), t * 0.05)));

	vec3 col = mix(deep, neon, body);
	col = mix(col, amber, amberPatch * 0.55);
	col = mix(col, yellowCore, bright * 0.38);
	col += veins * neon * 2.1;

	// Do not vignette by world Y here — it creates a hard horizontal band vs camera pitch.
	// Only tuck brightness slightly when looking into the void far below the islands.
	float voidBelow = smoothstep(-0.85, -0.2, d.y);
	col *= mix(1.0, 0.72, voidBelow * 0.35);

	float glow = pow(max(0.0, n - 0.4), 1.85) * 2.8;
	col += neon * glow;
	col += veins * 0.45;

	return max(col, vec3(0.0));
}

vec3 adrianTerrainShade(vec3 albedo, vec3 lm, vec3 normal, vec3 vPosRelPlayer) {
	vec3 viewDir = normalize(-vPosRelPlayer);
	float lmBright = dot(lm, vec3(0.31, 0.35, 0.34));
	float torch = clamp(lm.r * 1.15 + lmBright * 0.15, 0.0, 1.0);

	// Softer cast: preserve more of the block’s own color.
	vec3 greenKey = vec3(0.28, 0.92, 0.22);
	float wrap = clamp(normal.y * 0.4 + 0.6, 0.0, 1.0);
	vec3 fill = greenKey * (0.08 + 0.38 * wrap);

	float skyLit = clamp(lmBright * 1.1, 0.0, 1.0);
	vec3 amb = albedo * fill * (0.06 + 0.48 * skyLit);
	vec3 torchCol = albedo * vec3(1.0, 0.82, 0.52) * torch * 1.2;

	float ndv = clamp(dot(normalize(normal), viewDir), 0.0, 1.0);
	float rim = pow(1.0 - ndv, 2.8) * 0.11;
	vec3 rimCol = vec3(0.35, 1.0, 0.18) * rim * (0.35 + 0.65 * skyLit);

	vec3 col = amb + torchCol + rimCol;
	col = mix(col, albedo * greenKey * 0.05, 0.22);
	return col;
}

vec3 adrianFogColor() {
	// Greener, less brown so any residual haze matches the nebula.
	return vec3(0.06, 0.32, 0.07);
}

float adrianFogDensity() {
	// Light land haze only; sky is excluded in composite by depth / far-plane tests.
	return 0.0065;
}
